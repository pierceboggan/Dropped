# Calling OpenAI APIs in Swift without an SDK

The app uses `URLSession` and `Codable` request/response models in `Dropped/Models/AIWorkoutGenerator.swift`.

## App configuration

Do not hardcode API keys in Swift source. `OpenAIConfiguration.apiKey` reads `OPENAI_API_KEY` from the app's Info.plist or launch environment. If no usable key is configured, `AIWorkoutGenerator` returns a user-facing `missingAPIKey` error.

## Request pattern

1. Create a `URLRequest` for `https://api.openai.com/v1/chat/completions`.
2. Set `POST`, `Content-Type: application/json`, and `Authorization: Bearer <api key>`.
3. Encode the chat-completions request with `JSONEncoder`.
4. Ask the model for a strict JSON object.
5. Decode the response into the app's generated-workout schema.
6. Convert the generated schema into `Workout` and `Interval` models before updating UI state.

## Notes

- Keep OpenAI response parsing in the model/service layer, not in SwiftUI views.
- Prefer explicit error messages for missing keys, failed network calls, non-2xx responses, and invalid workout JSON.
- The app should continue to function without an OpenAI key; only AI generation is disabled.
