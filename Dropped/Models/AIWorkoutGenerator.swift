import Foundation

/// Error types surfaced by the OpenAI workout generation service.
enum AIWorkoutGeneratorError: Error {
    case missingAPIKey
    case networkError(Error)
    case invalidResponse
    case invalidWorkout
    case apiError(String)
}

/// App-level OpenAI configuration.
///
/// The API key is intentionally not hardcoded. Add `OPENAI_API_KEY` to the app's
/// Info.plist or launch environment when enabling AI workout generation.
enum OpenAIConfiguration {
    static var apiKey: String? {
        if let bundledKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           bundledKey.isUsableAPIKey {
            return bundledKey
        }

        let environmentKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        return environmentKey?.isUsableAPIKey == true ? environmentKey : nil
    }
}

/// Service responsible for requesting and parsing generated cycling workouts.
final class AIWorkoutGenerator {
    private let apiKey: String?
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o-mini"

    /// Creates a generator with an optional API key.
    /// - Parameter apiKey: OpenAI API key. Missing or placeholder keys fail explicitly.
    init(apiKey: String?) {
        self.apiKey = apiKey
    }

    /// Generates a structured workout using OpenAI.
    /// - Parameters:
    ///   - ftp: User's Functional Threshold Power in watts.
    ///   - type: Selected workout type.
    ///   - completion: Callback with a parsed workout or user-actionable error.
    func generateWorkout(ftp: Int, type: WorkoutType, completion: @escaping (Result<Workout, AIWorkoutGeneratorError>) -> Void) {
        guard let apiKey, apiKey.isUsableAPIKey else {
            completion(.failure(.missingAPIKey))
            return
        }

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: "You are a cycling coach. Output only valid JSON that matches the requested schema."),
                .init(role: "user", content: Self.makePrompt(ftp: ftp, type: type))
            ],
            responseFormat: .init(type: "json_object")
        )

        guard let body = try? JSONEncoder().encode(requestBody) else {
            completion(.failure(.invalidResponse))
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(Self.apiError(from: data, statusCode: httpResponse.statusCode)))
                return
            }

            guard let data = data,
                  let response = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
                  let content = response.choices.first?.message.content else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                let workout = try GeneratedWorkout.decode(from: content).makeWorkout()
                completion(.success(workout))
            } catch {
                completion(.failure(.invalidWorkout))
            }
        }
        task.resume()
    }

    /// Constructs the prompt and schema contract for workout generation.
    private static func makePrompt(ftp: Int, type: WorkoutType) -> String {
        """
        Generate a structured cycling workout for a rider with FTP \(ftp) watts. Workout type: \(type.displayName).
        Output JSON with this exact shape:
        {
          "title": "Workout title",
          "summary": "Brief coaching summary",
          "intervals": [
            {
              "duration_minutes": 5,
              "target_watts": 120,
              "description": "Warm up"
            }
          ],
          "total_duration_minutes": 45
        }
        Use positive durations and target watts for every interval.
        """
    }

    /// Parses an OpenAI error response when available.
    private static func apiError(from data: Data?, statusCode: Int) -> AIWorkoutGeneratorError {
        guard let data,
              let response = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) else {
            return .apiError("Request failed with status \(statusCode).")
        }

        return .apiError(response.error.message)
    }
}

private extension String {
    var isUsableAPIKey: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.uppercased().contains("YOUR_")
    }
}

/// Encodable request body for the OpenAI chat completions endpoint.
private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }
}

/// Minimal decodable response shape used by the app.
private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

/// Minimal decodable OpenAI error response.
private struct OpenAIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}

/// JSON schema returned by the model before conversion into the app's Workout model.
private struct GeneratedWorkout: Decodable {
    let title: String
    let summary: String
    let intervals: [GeneratedInterval]
    let totalDurationMinutes: Double?

    enum CodingKeys: String, CodingKey {
        case title
        case summary
        case intervals
        case totalDurationMinutes = "total_duration_minutes"
    }

    static func decode(from json: String) throws -> GeneratedWorkout {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(GeneratedWorkout.self, from: data)
    }

    func makeWorkout(date: Date = Date()) throws -> Workout {
        let workoutIntervals = try intervals.map { try $0.makeInterval() }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !workoutIntervals.isEmpty else {
            throw AIWorkoutGeneratorError.invalidWorkout
        }

        return Workout(title: title, date: date, summary: summary, intervals: workoutIntervals)
    }
}

/// JSON schema for a single generated workout interval.
private struct GeneratedInterval: Decodable {
    let durationMinutes: Double
    let targetWatts: Int
    let description: String?

    enum CodingKeys: String, CodingKey {
        case durationMinutes = "duration_minutes"
        case targetWatts = "target_watts"
        case description
    }

    func makeInterval() throws -> Interval {
        guard durationMinutes > 0, targetWatts > 0 else {
            throw AIWorkoutGeneratorError.invalidWorkout
        }

        return Interval(watts: targetWatts, duration: durationMinutes * 60)
    }
}
