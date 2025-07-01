# Dify Swift SDK

This is the Swift SDK for the Dify API, which allows you to easily integrate Dify into your iOS, macOS, tvOS, and watchOS applications.

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

In Xcode, go to `File` → `Add Package Dependencies...` and add:

```
https://github.com/langgenius/dify
```

Select `sdks/swift-client` as the package path.

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/langgenius/dify", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import DifyClient

let apiKey = "your-api-key-here"
let user = "user-123"

// Create a basic client
let client = DifyClient(apiKey: apiKey)

// Get application parameters
do {
    let parameters = try await client.getApplicationParameters(user: user)
    print("Parameters: \(parameters)")
} catch {
    print("Error: \(error)")
}
```

### Completion API

```swift
import DifyClient

let completionClient = CompletionClient(apiKey: apiKey)

// Create completion message
let response = try await completionClient.createCompletionMessage(
    inputs: ["query": "Tell me a story"],
    user: user
)
print("Answer: \(response.answer)")

// Streaming completion
let stream = completionClient.createCompletionMessageStream(
    inputs: ["query": "Tell me about AI"],
    user: user
)

for try await chunk in stream {
    if let answer = chunk.answer {
        print("Chunk: \(answer)")
    }
}
```

### Chat API

```swift
import DifyClient

let chatClient = ChatClient(apiKey: apiKey)

// Create chat message
let response = try await chatClient.createChatMessage(
    inputs: [:],
    query: "Hello, how are you?",
    user: user
)
print("Response: \(response.answer)")

// Continue conversation
if let conversationId = response.conversationId {
    let followUp = try await chatClient.createChatMessage(
        inputs: [:],
        query: "Tell me more",
        user: user,
        conversationId: conversationId
    )
    print("Follow-up: \(followUp.answer)")
}

// Streaming chat
let chatStream = chatClient.createChatMessageStream(
    inputs: [:],
    query: "Explain quantum computing",
    user: user
)

for try await chunk in chatStream {
    if let answer = chunk.answer {
        print("Stream: \(answer)")
    }
}
```

### Workflow API

```swift
import DifyClient

let workflowClient = WorkflowClient(apiKey: apiKey)

// Run workflow
let result = try await workflowClient.run(
    inputs: ["text": "Analyze this content"],
    user: user
)
print("Workflow result: \(result.answer)")
```

### File Upload

```swift
// Upload file
let fileData = "Sample content".data(using: .utf8)!
let uploadResponse = try await client.uploadFile(
    fileData: fileData,
    fileName: "sample.txt",
    mimeType: "text/plain",
    user: user
)
print("File uploaded: \(uploadResponse.id)")

// Use with vision models
let remoteFiles = [
    RemoteFile(type: .image, url: "https://example.com/image.jpg")
]

let visionResponse = try await chatClient.createChatMessage(
    inputs: [:],
    query: "Describe this image",
    user: user,
    files: remoteFiles
)
```

### Error Handling

```swift
do {
    let response = try await client.getApplicationParameters(user: user)
    // Handle success
} catch let error as DifyError {
    switch error {
    case .apiError(let statusCode, let message):
        print("API Error (\(statusCode)): \(message ?? "")")
    case .networkError(let error):
        print("Network Error: \(error)")
    case .invalidURL:
        print("Invalid URL")
    case .invalidResponse:
        print("Invalid Response")
    case .noData:
        print("No Data")
    case .decodingError(let error):
        print("Decoding Error: \(error)")
    }
} catch {
    print("Other Error: \(error)")
}
```

## Documentation

- [中文文档](README_CN.md)
- [Examples](Examples/README.md)
- [API Reference](https://docs.dify.ai/api-reference)

## License

This SDK is released under the MIT License. 