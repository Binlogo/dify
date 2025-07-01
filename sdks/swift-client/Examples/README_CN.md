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

## 注意事项

1. **API 密钥安全**: 请不要在代码中硬编码 API 密钥，建议从环境变量或配置文件中读取
2. **网络请求**: 确保设备有网络连接
3. **异步处理**: 所有 API 调用都是异步的，需要在 async 上下文中使用
4. **错误处理**: 始终使用 do-catch 块来处理可能的错误
5. **用户标识**: 确保为每个用户提供唯一的用户标识符

## 更多示例

如果你需要更多特定用例的示例，请参考：
- [Dify 官方文档](https://docs.dify.ai/)
- [API 参考文档](https://docs.dify.ai/api-reference)
- 项目的单元测试文件

## 反馈和贡献

如果你发现示例中的问题或有改进建议，欢迎：
1. 提交 Issue
2. 创建 Pull Request
3. 参与讨论

感谢使用 Dify Swift SDK！ 