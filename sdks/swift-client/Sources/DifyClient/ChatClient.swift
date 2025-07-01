import Foundation

/// Client for Dify Chat API
public final class ChatClient: DifyClient {
    
    /// Create a chat message
    /// - Parameters:
    ///   - inputs: Input parameters for the chat
    ///   - query: User query/message
    ///   - user: User identifier
    ///   - stream: Whether to use streaming mode
    ///   - conversationId: Optional conversation ID to continue existing conversation
    ///   - files: Optional files to include
    /// - Returns: Chat response
    public func createChatMessage(
        inputs: [String: Any],
        query: String,
        user: String,
        stream: Bool = false,
        conversationId: String? = nil,
        files: [Any]? = nil
    ) async throws -> MessageResponse {
        let responseMode: ResponseMode = stream ? .streaming : .blocking
        let request = ChatMessageRequest(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: responseMode,
            conversationId: conversationId,
            files: files
        )
        
        let requestData = try JSONEncoder().encode(request)
        
        if stream {
            // For streaming mode, collect all chunks
            var responseData = Data()
            let stream = sendStreamingRequest(
                method: .POST,
                endpoint: "/chat-messages",
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
                endpoint: "/chat-messages",
                body: requestData
            )
            
            return try JSONDecoder().decode(MessageResponse.self, from: data)
        }
    }
    
    /// Create a chat message with streaming support
    /// - Parameters:
    ///   - inputs: Input parameters for the chat
    ///   - query: User query/message
    ///   - user: User identifier
    ///   - conversationId: Optional conversation ID
    ///   - files: Optional files to include
    /// - Returns: AsyncThrowingStream of streaming responses
    public func createChatMessageStream(
        inputs: [String: Any],
        query: String,
        user: String,
        conversationId: String? = nil,
        files: [Any]? = nil
    ) -> AsyncThrowingStream<StreamingResponse, Error> {
        let request = ChatMessageRequest(
            inputs: inputs,
            query: query,
            user: user,
            responseMode: .streaming,
            conversationId: conversationId,
            files: files
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let requestData = try JSONEncoder().encode(request)
                    let stream = sendStreamingRequest(
                        method: .POST,
                        endpoint: "/chat-messages",
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
    
    /// Get suggested questions for a message
    /// - Parameters:
    ///   - messageId: ID of the message
    ///   - user: User identifier
    /// - Returns: Suggested questions response
    public func getSuggestedQuestions(messageId: String, user: String) async throws -> SuggestedQuestionsResponse {
        let queryItems = [URLQueryItem(name: "user", value: user)]
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/messages/\(messageId)/suggested",
            queryItems: queryItems
        )
        
        return try JSONDecoder().decode(SuggestedQuestionsResponse.self, from: data)
    }
    
    /// Stop a chat message
    /// - Parameters:
    ///   - taskId: Task ID of the message to stop
    ///   - user: User identifier
    /// - Returns: Stop response
    public func stopChatMessage(taskId: String, user: String) async throws -> MessageFeedbackResponse {
        let body = StopTaskRequest(user: user)
        let requestData = try JSONEncoder().encode(body)
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/chat-messages/\(taskId)/stop",
            body: requestData
        )
        
        return try JSONDecoder().decode(MessageFeedbackResponse.self, from: data)
    }
    
    /// Get conversations list
    /// - Parameters:
    ///   - user: User identifier
    ///   - firstId: First conversation ID for pagination
    ///   - limit: Maximum number of conversations to return
    ///   - pinned: Filter by pinned status
    /// - Returns: Conversations response
    public func getConversations(
        user: String,
        firstId: String? = nil,
        limit: Int? = nil,
        pinned: Bool? = nil
    ) async throws -> ConversationsResponse {
        var queryItems = [URLQueryItem(name: "user", value: user)]
        
        if let firstId = firstId {
            queryItems.append(URLQueryItem(name: "first_id", value: firstId))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let pinned = pinned {
            queryItems.append(URLQueryItem(name: "pinned", value: String(pinned)))
        }
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/conversations",
            queryItems: queryItems
        )
        
        return try JSONDecoder().decode(ConversationsResponse.self, from: data)
    }
    
    /// Get conversation messages
    /// - Parameters:
    ///   - user: User identifier
    ///   - conversationId: Conversation ID
    ///   - firstId: First message ID for pagination
    ///   - limit: Maximum number of messages to return
    /// - Returns: Messages response
    public func getConversationMessages(
        user: String,
        conversationId: String = "",
        firstId: String? = nil,
        limit: Int? = nil
    ) async throws -> MessagesResponse {
        var queryItems = [
            URLQueryItem(name: "user", value: user),
            URLQueryItem(name: "conversation_id", value: conversationId)
        ]
        
        if let firstId = firstId {
            queryItems.append(URLQueryItem(name: "first_id", value: firstId))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/messages",
            queryItems: queryItems
        )
        
        return try JSONDecoder().decode(MessagesResponse.self, from: data)
    }
    
    /// Rename a conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID to rename
    ///   - name: New name for the conversation
    ///   - user: User identifier
    ///   - autoGenerate: Whether to auto-generate the name
    /// - Returns: Rename response
    public func renameConversation(
        conversationId: String,
        name: String,
        user: String,
        autoGenerate: Bool = false
    ) async throws -> MessageFeedbackResponse {
        let body = RenameConversationRequest(name: name, user: user, autoGenerate: autoGenerate)
        let requestData = try JSONEncoder().encode(body)
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/conversations/\(conversationId)/name",
            body: requestData
        )
        
        return try JSONDecoder().decode(MessageFeedbackResponse.self, from: data)
    }
    
    /// Delete a conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID to delete
    ///   - user: User identifier
    /// - Returns: Delete response
    public func deleteConversation(conversationId: String, user: String) async throws -> MessageFeedbackResponse {
        let queryItems = [URLQueryItem(name: "user", value: user)]
        
        let data = try await sendRequest(
            method: .DELETE,
            endpoint: "/conversations/\(conversationId)",
            queryItems: queryItems
        )
        
        return try JSONDecoder().decode(MessageFeedbackResponse.self, from: data)
    }
    
    /// Convert audio to text
    /// - Parameters:
    ///   - audioData: Audio file data
    ///   - fileName: Name of the audio file
    ///   - user: User identifier
    /// - Returns: Text response
    public func audioToText(
        audioData: Data,
        fileName: String,
        user: String
    ) async throws -> MessageFeedbackResponse {
        let boundary = UUID().uuidString
        let body = createAudioMultipartBody(
            audioData: audioData,
            fileName: fileName,
            user: user,
            boundary: boundary
        )
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/audio-to-text",
            body: body,
            additionalHeaders: ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        )
        
        return try JSONDecoder().decode(MessageFeedbackResponse.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func createAudioMultipartBody(
        audioData: Data,
        fileName: String,
        user: String,
        boundary: String
    ) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        // Add user field
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user\"\r\n\r\n".data(using: .utf8)!)
        body.append(user.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
} 