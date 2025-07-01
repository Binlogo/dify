import Foundation
import DifyClient

// 基本使用示例
class DifyClientExample {
    let apiKey = "your-api-key-here"
    let user = "user-123"
    
    func basicExample() async {
        // 创建基础客户端
        let client = DifyClient(apiKey: apiKey)
        
        do {
            // 获取应用参数
            let parameters = try await client.getApplicationParameters(user: user)
            print("应用参数获取成功: \(parameters)")
            
            // 提供消息反馈
            let feedbackResponse = try await client.messageFeedback(
                messageId: "message-123",
                rating: .like,
                user: user
            )
            print("反馈提交成功: \(feedbackResponse)")
            
        } catch {
            print("错误: \(error)")
        }
    }
    
    func completionExample() async {
        let completionClient = CompletionClient(apiKey: apiKey)
        
        do {
            // 创建 completion 消息
            let response = try await completionClient.createCompletionMessage(
                inputs: ["query": "请告诉我一个关于人工智能的故事"],
                user: user
            )
            print("Completion 回答: \(response.answer)")
            
            // 流式 completion
            print("开始流式 completion...")
            let stream = completionClient.createCompletionMessageStream(
                inputs: ["query": "请详细介绍 Swift 编程语言"],
                user: user
            )
            
            do {
                for try await chunk in stream {
                    if let answer = chunk.answer {
                        print("流式回答片段: \(answer)")
                    }
                }
            } catch {
                print("流式错误: \(error)")
            }
            
        } catch {
            print("Completion 错误: \(error)")
        }
    }
    
    func chatExample() async {
        let chatClient = ChatClient(apiKey: apiKey)
        var conversationId: String?
        
        do {
            // 创建第一个聊天消息
            let firstResponse = try await chatClient.createChatMessage(
                inputs: [:],
                query: "你好，我想了解 Dify 平台",
                user: user
            )
            print("第一个回答: \(firstResponse.answer)")
            conversationId = firstResponse.conversationId
            
            // 继续对话
            if let convId = conversationId {
                let secondResponse = try await chatClient.createChatMessage(
                    inputs: [:],
                    query: "Dify 有哪些主要功能？",
                    user: user,
                    conversationId: convId
                )
                print("第二个回答: \(secondResponse.answer)")
                
                // 获取对话列表
                let conversations = try await chatClient.getConversations(user: user)
                print("对话列表获取成功，共 \(conversations.data.count) 个对话")
                
                // 重命名对话
                let renameResult = try await chatClient.renameConversation(
                    conversationId: convId,
                    name: "关于 Dify 的讨论",
                    user: user
                )
                print("对话重命名成功: \(renameResult)")
            }
            
        } catch {
            print("聊天错误: \(error)")
        }
    }
    
    func streamingChatExample() async {
        let chatClient = ChatClient(apiKey: apiKey)
        
        print("开始流式聊天...")
        let stream = chatClient.createChatMessageStream(
            inputs: [:],
            query: "请详细介绍一下 AI 大语言模型的发展历程",
            user: user
        )
        
        do {
            for try await chunk in stream {
                if let answer = chunk.answer {
                    print("流式聊天片段: \(answer)")
                }
                if let conversationId = chunk.conversationId {
                    print("对话 ID: \(conversationId)")
                }
            }
        } catch {
            print("流式聊天错误: \(error)")
        }
    }
    
    func workflowExample() async {
        let workflowClient = WorkflowClient(apiKey: apiKey)
        
        do {
            // 运行工作流
            let response = try await workflowClient.run(
                inputs: [
                    "input_text": "请分析这段文本的情感",
                    "text": "今天天气真好，我心情很愉快！"
                ],
                user: user
            )
            print("工作流结果: \(response.answer)")
            
            // 流式工作流
            print("开始流式工作流...")
            let stream = workflowClient.runStream(
                inputs: [
                    "task": "文本摘要",
                    "content": "这是一段很长的文本内容，需要进行摘要处理..."
                ],
                user: user
            )
            
            do {
                for try await chunk in stream {
                    if let answer = chunk.answer {
                        print("工作流流式结果: \(answer)")
                    }
                }
            } catch {
                print("流式工作流错误: \(error)")
            }
            
        } catch {
            print("工作流错误: \(error)")
        }
    }
    
    func fileUploadExample() async {
        let client = DifyClient(apiKey: apiKey)
        
        // 模拟文件数据（在实际使用中，这会是真实的文件数据）
        let sampleText = "这是一个示例文本文件的内容"
        guard let fileData = sampleText.data(using: .utf8) else {
            print("无法创建文件数据")
            return
        }
        
        do {
            let uploadResponse = try await client.uploadFile(
                fileData: fileData,
                fileName: "sample.txt",
                mimeType: "text/plain",
                user: user
            )
            print("文件上传成功: \(uploadResponse.id)")
            print("文件名: \(uploadResponse.name)")
            print("文件大小: \(uploadResponse.size) 字节")
            
        } catch {
            print("文件上传错误: \(error)")
        }
    }
    
    func audioExample() async {
        let client = DifyClient(apiKey: apiKey)
        
        do {
            // 文本转语音
            let audioData = try await client.textToAudio(
                text: "你好，这是使用 Dify Swift SDK 生成的语音",
                user: user
            )
            print("获得音频数据，大小: \(audioData.count) 字节")
            
            // 在实际应用中，你可以将 audioData 保存到文件或播放
            // let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // let audioURL = documentsPath.appendingPathComponent("generated_audio.wav")
            // try audioData.write(to: audioURL)
            
        } catch {
            print("文本转语音错误: \(error)")
        }
    }
    
    func errorHandlingExample() async {
        let client = DifyClient(apiKey: "invalid-key")
        
        do {
            let _ = try await client.getApplicationParameters(user: user)
        } catch let error as DifyError {
            switch error {
            case .invalidURL:
                print("URL 无效")
            case .noData:
                print("没有接收到数据")
            case .invalidResponse:
                print("响应格式无效")
            case .decodingError(let decodingError):
                print("JSON 解码错误: \(decodingError)")
            case .networkError(let networkError):
                print("网络错误: \(networkError)")
            case .apiError(let statusCode, let message):
                print("API 错误 (状态码 \(statusCode)): \(message ?? "未知错误")")
            }
        } catch {
            print("其他错误: \(error)")
        }
    }
}

// 使用示例
func runExamples() async {
    let example = DifyClientExample()
    
    print("=== 基本功能示例 ===")
    await example.basicExample()
    
    print("\n=== Completion 示例 ===")
    await example.completionExample()
    
    print("\n=== 聊天示例 ===")
    await example.chatExample()
    
    print("\n=== 流式聊天示例 ===")
    await example.streamingChatExample()
    
    print("\n=== 工作流示例 ===")
    await example.workflowExample()
    
    print("\n=== 文件上传示例 ===")
    await example.fileUploadExample()
    
    print("\n=== 音频功能示例 ===")
    await example.audioExample()
    
    print("\n=== 错误处理示例 ===")
    await example.errorHandlingExample()
}

// 如果作为可执行文件运行
#if canImport(Foundation) && !os(Linux)
if CommandLine.arguments.contains("--run-examples") {
    Task {
        await runExamples()
    }
    RunLoop.main.run()
}
#endif 