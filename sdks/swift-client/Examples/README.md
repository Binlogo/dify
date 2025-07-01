# Dify Swift SDK Examples

This directory contains examples demonstrating how to use the Dify Swift SDK.

## Files

### BasicUsage.swift

Comprehensive examples covering:

- **Basic Operations**: Application parameters, message feedback
- **Completion API**: Text completion, streaming responses
- **Chat API**: Conversations, streaming chat, conversation management
- **Workflow API**: Running workflows, streaming workflows
- **File Operations**: File uploads, vision models
- **Audio Features**: Text-to-speech, speech-to-text
- **Error Handling**: Comprehensive error management

## Running Examples

### 1. Prerequisites

- Valid Dify API key
- Replace `"your-api-key-here"` with your actual API key

### 2. In Xcode

1. Create a new iOS/macOS project
2. Add DifyClient package dependency
3. Copy example code to your project
4. Update API key
5. Run the code

### 3. Swift Package

1. Create executable package:
```bash
swift package init --type executable --name DifyExample
```

2. Add dependency in `Package.swift`:
```swift
dependencies: [
    .package(path: "../swift-client")
],
targets: [
    .executableTarget(
        name: "DifyExample",
        dependencies: ["DifyClient"]
    )
]
```

3. Copy example code to `Sources/DifyExample/main.swift`
4. Run:
```bash
swift run DifyExample --run-examples
```

## Key Examples

### Basic Client

```swift
let client = DifyClient(apiKey: "your-api-key")
let parameters = try await client.getApplicationParameters(user: "user-123")
```

### Streaming Responses

```swift
let stream = chatClient.createChatMessageStream(
    inputs: [:],
    query: "Your question",
    user: "user-123"
)

for try await chunk in stream {
    if let answer = chunk.answer {
        print(answer)
    }
}
```

### Error Handling

```swift
do {
    let response = try await client.someMethod()
} catch let error as DifyError {
    // Handle DifyError
} catch {
    // Handle other errors
}
```

## Documentation

- [中文示例文档](README_CN.md)
- [Main Documentation](../README.md)
- [API Reference](https://docs.dify.ai/api-reference) 