# Calling OpenAI APIs in Swift (No SDK)

To call the OpenAI APIs in Swift without using any SDKs, you can use Swift's built-in networking with `URLSession`. Here’s a concise, accessible approach:

## Steps

1. **Create a URLRequest** to the OpenAI endpoint (e.g., `https://api.openai.com/v1/chat/completions`).
2. **Set the HTTP method** to `POST`.
3. **Add your API key** in the `Authorization` header: `Bearer YOUR_API_KEY`.
4. **Set the `Content-Type` header** to `application/json`.
5. **Encode your request body as JSON** (using `JSONEncoder` or manual `Data`).
6. **Use `URLSession.shared.dataTask`** to send the request and handle the response.

## Example: Chat Completions

```swift
import Foundation

// 1. Define your request body
struct ChatRequest: Codable {
    let model: String
    let messages: [[String: String]]
}

let apiKey = "YOUR_OPENAI_API_KEY"
let url = URL(string: "https://api.openai.com/v1/chat/completions")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let chatRequest = ChatRequest(
    model: "gpt-3.5-turbo",
    messages: [
        ["role": "user", "content": "Hello!"]
    ]
)

request.httpBody = try? JSONEncoder().encode(chatRequest)

// 2. Send the request
let task = URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data else { return }
    // Handle the response (decode JSON, etc.)
    print(String(data: data, encoding: .utf8) ?? "No response")
}
task.resume()
```

Replace `"YOUR_OPENAI_API_KEY"` with your actual key. This approach works for any OpenAI endpoint—just adjust the request body as needed. No SDKs required!
