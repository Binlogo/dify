import Foundation

/// Client for Dify Workflow API
public final class WorkflowClient: DifyClient {
    
    /// Run a workflow
    /// - Parameters:
    ///   - inputs: Input parameters for the workflow
    ///   - user: User identifier
    ///   - stream: Whether to use streaming mode
    /// - Returns: Workflow response
    public func run(
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
            // For streaming mode, collect all chunks
            var responseData = Data()
            let stream = sendStreamingRequest(
                method: .POST,
                endpoint: "/workflows/run",
                body: requestData
            )
            
            for try await chunk in stream {
                responseData.append(chunk)
            }
            
            // Parse the final response
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
    public func runStream(
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
    
    /// Stop a workflow
    /// - Parameters:
    ///   - taskId: Task ID of the workflow to stop
    ///   - user: User identifier
    /// - Returns: Stop response
    public func stop(taskId: String, user: String) async throws -> MessageFeedbackResponse {
        let body = StopTaskRequest(user: user)
        let requestData = try JSONEncoder().encode(body)
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/workflows/\(taskId)/stop",
            body: requestData
        )
        
        return try JSONDecoder().decode(MessageFeedbackResponse.self, from: data)
    }
} 