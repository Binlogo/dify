# Dify Swift SDK

Dify Swift SDK 是 Dify API 的官方 Swift 客户端库，让您可以轻松地在 iOS、macOS、tvOS 和 watchOS 应用中集成 Dify 服务。

## 特性

- ✅ 现代化的 Swift 异步编程支持 (async/await)
- ✅ 支持所有 Dify API 功能
- ✅ 流式响应支持
- ✅ 类型安全的 API 接口
- ✅ 完整的错误处理
- ✅ 无外部依赖
- ✅ 支持 iOS 13+、macOS 10.15+、tvOS 13+、watchOS 6+

## 系统要求

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.9+
- Xcode 15.0+

## 安装

### Swift Package Manager

在 Xcode 中：
1. 选择 `File` > `Add Package Dependencies...`
2. 输入仓库 URL: `https://github.com/langgenius/dify`
3. 选择包路径: `sdks/swift-client`
4. 选择版本并添加到项目

或者在 `Package.swift` 文件中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/langgenius/dify", from: "1.0.0")
]
```

## 快速开始

### 基础使用

```swift
import DifyClient

let apiKey = "your-api-key-here"
let user = "user-123"

// 创建基础客户端
let client = DifyClient(apiKey: apiKey)

// 获取应用参数
let parameters = try await client.getApplicationParameters(user: user)
print("应用参数: \(parameters)")
```

### Completion API

```swift
let completionClient = CompletionClient(apiKey: apiKey)

// 创建 completion 消息
let response = try await completionClient.createCompletionMessage(
    inputs: ["query": "请告诉我一个故事"],
    user: user
)
print("回答: \(response.answer)")

// 流式 completion
let stream = completionClient.createCompletionMessageStream(
    inputs: ["query": "告诉我关于 AI 的信息"],
    user: user
)

for try await chunk in stream {
    if let answer = chunk.answer {
        print("流式回答: \(answer)")
    }
}
```

### Chat API

```swift
let chatClient = ChatClient(apiKey: apiKey)

// 创建聊天消息
let response = try await chatClient.createChatMessage(
    inputs: [:],
    query: "你好，我是新用户",
    user: user
)
print("聊天回答: \(response.answer)")

// 继续对话
if let conversationId = response.conversationId {
    let followUp = try await chatClient.createChatMessage(
        inputs: [:],
        query: "能告诉我更多信息吗？",
        user: user,
        conversationId: conversationId
    )
    print("继续对话: \(followUp.answer)")
}
```

### 文档

- [English Documentation](README.md)
- [示例代码](Examples/README_CN.md)
- [API 参考](https://docs.dify.ai/api-reference)

## 许可证

本 SDK 基于 MIT 许可证发布。