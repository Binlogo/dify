import Foundation

/// Client for Dify Completion API
public final class CompletionClient: DifyClient {
    
    /// Create a completion message
    /// - Parameters:
    ///   - inputs: Input parameters for the completion
    ///   - user: User identifier
    ///   - stream: Whether to use streaming mode
    ///   - files: Optional files to include
    /// - Returns: Completion response or stream
    public func createCompletionMessage(
        inputs: [String: Any],
        user: String,
        stream: Bool = false,
        files: [Any]? = nil
    ) async throws -> MessageResponse {
        let responseMode: ResponseMode = stream ? .streaming : .blocking
        let request = CompletionMessageRequest(
            inputs: inputs,
            user: user,
            responseMode: responseMode,
            files: files
        )
        
        let requestData = try JSONEncoder().encode(request)
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/completion-messages",
            body: requestData
        )
        
        return try JSONDecoder().decode(MessageResponse.self, from: data)
    }
    
    /// Create a completion message with streaming support
    /// - Parameters:
    ///   - inputs: Input parameters for the completion
    ///   - user: User identifier
    ///   - files: Optional files to include
    /// - Returns: AsyncThrowingStream of streaming responses
    public func createCompletionMessageStream(
        inputs: [String: Any],
        user: String,
        files: [Any]? = nil
    ) -> AsyncThrowingStream<StreamingResponse, Error> {
        let request = CompletionMessageRequest(
            inputs: inputs,
            user: user,
            responseMode: .streaming,
            files: files
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let requestData = try JSONEncoder().encode(request)
                    let stream = sendStreamingRequest(
                        method: .POST,
                        endpoint: "/completion-messages",
                        body: requestData
                    )
                    
                    var buffer = ""
                    for try await chunk in stream {
                        guard let chunkString = String(data: chunk, encoding: .utf8) else { continue }
                        buffer += chunkString
                        let lines = buffer.components(separatedBy: .newlines)
                        
                        for i in 0..<lines.count - 1 {
                            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                            if line.hasPrefix("data: ") {
                                let jsonString = String(line.dropFirst(6))
                                if jsonString == "[DONE]" {
                                    continuation.finish()
                                    return
                                }
                                if let jsonData = jsonString.data(using: .utf8) {
                                    do {
                                        let response = try JSONDecoder().decode(StreamingResponse.self, from: jsonData)
                                        continuation.yield(response)
                                    } catch { continue }
                                }
                            }
                        }
                        buffer = lines.last ?? ""
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Run a workflow
    /// - Parameters:
    ///   - inputs: Input parameters for the workflow
    ///   - user: User identifier
    ///   - stream: Whether to use streaming mode
    /// - Returns: Workflow response
    public func runWorkflow(
        inputs: [String: Any],
        user: String,
        stream: Bool = false
    ) async throws -> MessageResponse {
        let responseMode: ResponseMode = stream ? .streaming : .blocking
        let request = WorkflowRunRequest(
            inputs: inputs,
            user: user,
            responseMode: responseMode
        )
        
        let requestData = try JSONEncoder().encode(request)
        
        if stream {
            // Similar streaming logic as completion
            var responseData = Data()
            let stream = sendStreamingRequest(
                method: .POST,
                endpoint: "/workflows/run",
                body: requestData
            )
            
            for try await chunk in stream {
                responseData.append(chunk)
            }
            
            let responseString = String(data: responseData, encoding: .utf8) ?? ""
            let lines = responseString.components(separatedBy: .newlines)
            
            for line in lines.reversed() {
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    if let jsonData = jsonString.data(using: .utf8),
                       let response = try? JSONDecoder().decode(MessageResponse.self, from: jsonData) {
                        return response
                    }
                }
            }
            
            throw DifyError.invalidResponse
        } else {
            let data = try await sendRequest(
                method: .POST,
                endpoint: "/workflows/run",
                body: requestData
            )
            
            return try JSONDecoder().decode(MessageResponse.self, from: data)
        }
    }
    
    /// Run a workflow with streaming support
    /// - Parameters:
    ///   - inputs: Input parameters for the workflow
    ///   - user: User identifier
    /// - Returns: AsyncThrowingStream of streaming responses
    public func runWorkflowStream(
        inputs: [String: Any],
        user: String
    ) -> AsyncThrowingStream<StreamingResponse, Error> {
        let request = WorkflowRunRequest(
            inputs: inputs,
            user: user,
            responseMode: .streaming
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let requestData = try JSONEncoder().encode(request)
                    let stream = sendStreamingRequest(
                        method: .POST,
                        endpoint: "/workflows/run",
                        body: requestData
                    )
                    
                    var buffer = ""
                    
                    for try await chunk in stream {
                        guard let chunkString = String(data: chunk, encoding: .utf8) else {
                            continue
                        }
                        
                        buffer += chunkString
                        let lines = buffer.components(separatedBy: .newlines)
                        
                        for i in 0..<lines.count - 1 {
                            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if line.hasPrefix("data: ") {
                                let jsonString = String(line.dropFirst(6))
                                
                                if jsonString == "[DONE]" {
                                    continuation.finish()
                                    return
                                }
                                
                                if let jsonData = jsonString.data(using: .utf8) {
                                    do {
                                        let response = try JSONDecoder().decode(StreamingResponse.self, from: jsonData)
                                        continuation.yield(response)
                                    } catch {
                                        continue
                                    }
                                }
                            }
                        }
                        
                        buffer = lines.last ?? ""
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Streaming Response Model

/// Response for streaming API calls
public struct StreamingResponse: Codable {
    public let event: String?
    public let messageId: String?
    public let conversationId: String?
    public let answer: String?
    public let createdAt: Date?
    public let taskId: String?
    public let workflowRunId: String?
    
    private enum CodingKeys: String, CodingKey {
        case event, answer
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case createdAt = "created_at"
        case taskId = "task_id"
        case workflowRunId = "workflow_run_id"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        event = try container.decodeIfPresent(String.self, forKey: .event)
        messageId = try container.decodeIfPresent(String.self, forKey: .messageId)
        conversationId = try container.decodeIfPresent(String.self, forKey: .conversationId)
        answer = try container.decodeIfPresent(String.self, forKey: .answer)
        taskId = try container.decodeIfPresent(String.self, forKey: .taskId)
        workflowRunId = try container.decodeIfPresent(String.self, forKey: .workflowRunId)
        
        // 健壮的日期解析：支持多种格式
        var parsedDate: Date?
        if let createdAtValue = try? container.decode(Int.self, forKey: .createdAt) {
            // Unix 时间戳（秒）
            parsedDate = Date(timeIntervalSince1970: TimeInterval(createdAtValue))
        } else if let createdAtValue = try? container.decode(Double.self, forKey: .createdAt) {
            // Unix 时间戳（可能包含毫秒）
            parsedDate = Date(timeIntervalSince1970: createdAtValue)
        } else if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            // 尝试解析字符串格式的日期
            if let timestamp = Double(createdAtString) {
                // 数字字符串格式
                parsedDate = Date(timeIntervalSince1970: timestamp)
            } else {
                // ISO 8601 或其他日期字符串格式
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                parsedDate = formatter.date(from: createdAtString)
                
                // 如果 ISO8601 解析失败，尝试其他常见格式
                if parsedDate == nil {
                    let fallbackFormatter = DateFormatter()
                    fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                    parsedDate = fallbackFormatter.date(from: createdAtString)
                }
            }
        }
        createdAt = parsedDate
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(event, forKey: .event)
        try container.encodeIfPresent(messageId, forKey: .messageId)
        try container.encodeIfPresent(conversationId, forKey: .conversationId)
        try container.encodeIfPresent(answer, forKey: .answer)
        try container.encodeIfPresent(taskId, forKey: .taskId)
        try container.encodeIfPresent(workflowRunId, forKey: .workflowRunId)
        
        // 编码为 Unix 时间戳
        if let createdAt = createdAt {
            try container.encode(Int(createdAt.timeIntervalSince1970), forKey: .createdAt)
        }
    }
} 