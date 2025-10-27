
//  AIWorkoutGenerator.swift
//  Dropped
//
//  Service for generating structured cycling workouts using the OpenAI API.
//
//  - Handles prompt construction, API requests, and response parsing.
//  - Designed for use by the WorkoutGeneratorViewModel.
//
//  Edge Cases: Handles API/network errors and invalid responses.
//  Limitations: Assumes OpenAI API key is available and valid.

import Foundation

/// Error types for AIWorkoutGenerator
enum AIWorkoutGeneratorError: Error {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
}

/// Service responsible for generating workouts using OpenAI's API.
/// - Usage: Call `generateWorkout` with user FTP and selected WorkoutType.
final class AIWorkoutGenerator {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-3.5-turbo"

    /// Initialize with OpenAI API key
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Generates a structured workout using OpenAI
    /// - Parameters:
    ///   - ftp: User's Functional Threshold Power (watts)
    ///   - type: Selected WorkoutType
    ///   - completion: Callback with result (JSON string or error)
    func generateWorkout(ftp: Int, type: WorkoutType, completion: @escaping (Result<String, AIWorkoutGeneratorError>) -> Void) {
        let prompt = Self.makePrompt(ftp: ftp, type: type)
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a cycling coach AI. Output only valid JSON."],
                ["role": "user", "content": prompt]
            ]
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
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
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(.failure(.invalidResponse))
                return
            }
            completion(.success(content))
        }
        task.resume()
    }

    /// Constructs the AI prompt for workout generation
    private static func makePrompt(ftp: Int, type: WorkoutType) -> String {
        """
        Generate a structured cycling workout for a rider with FTP \(ftp) watts. Workout type: \(type.displayName).
        Output JSON with fields: title, summary, intervals (array of {duration_minutes, target_watts, description}), and total_duration_minutes.
        """
    }
}
