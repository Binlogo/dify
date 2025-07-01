import Foundation

/// Base URL for Dify API
public let difyBaseURL = "https://api.dify.ai/v1"

/// HTTP methods supported by Dify API
public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/// Errors that can occur when using the Dify client
public enum DifyError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case apiError(statusCode: Int, message: String?)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message ?? "Unknown error")"
        }
    }
}

/// Base Dify client providing common functionality
open class DifyClient {
    public let apiKey: String
    public let baseURL: String
    public let session: URLSession
    
    /// Initialize a new Dify client
    /// - Parameters:
    ///   - apiKey: Your Dify API key
    ///   - baseURL: Base URL for the API (defaults to official Dify API)
    ///   - session: URLSession to use for requests (defaults to .shared)
    public init(
        apiKey: String,
        baseURL: String = difyBaseURL,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }
    
    /// Update the API key
    /// - Parameter apiKey: New API key
    public func updateApiKey(_ apiKey: String) -> DifyClient {
        return DifyClient(apiKey: apiKey, baseURL: baseURL, session: session)
    }
    
    /// Send a request to the Dify API
    /// - Parameters:
    ///   - method: HTTP method
    ///   - endpoint: API endpoint
    ///   - body: Request body data
    ///   - queryItems: URL query parameters
    ///   - additionalHeaders: Additional HTTP headers
    /// - Returns: Response data
    public func sendRequest(
        method: HTTPMethod,
        endpoint: String,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil,
        additionalHeaders: [String: String] = [:]
    ) async throws -> Data {
        guard var url = URL(string: baseURL + endpoint) else {
            throw DifyError.invalidURL
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let urlWithQuery = components?.url else {
                throw DifyError.invalidURL
            }
            url = urlWithQuery
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add additional headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DifyError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw DifyError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            return data
        } catch let error as DifyError {
            throw error
        } catch {
            throw DifyError.networkError(error)
        }
    }
    
    /// Send a streaming request to the Dify API
    /// - Parameters:
    ///   - method: HTTP method
    ///   - endpoint: API endpoint
    ///   - body: Request body data
    ///   - queryItems: URL query parameters
    ///   - additionalHeaders: Additional HTTP headers
    /// - Returns: AsyncThrowingStream of data chunks
    public func sendStreamingRequest(
        method: HTTPMethod,
        endpoint: String,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil,
        additionalHeaders: [String: String] = [:]
    ) -> AsyncThrowingStream<Data, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard var url = URL(string: baseURL + endpoint) else {
                        continuation.finish(throwing: DifyError.invalidURL)
                        return
                    }
                    
                    if let queryItems = queryItems, !queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                        components?.queryItems = queryItems
                        guard let urlWithQuery = components?.url else {
                            continuation.finish(throwing: DifyError.invalidURL)
                            return
                        }
                        url = urlWithQuery
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = method.rawValue
                    request.httpBody = body
                    
                    // Set default headers
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Add additional headers
                    for (key, value) in additionalHeaders {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                    
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                        let (asyncBytes, response) = try await session.bytes(for: request)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.finish(throwing: DifyError.invalidResponse)
                            return
                        }
                        
                        guard 200...299 ~= httpResponse.statusCode else {
                            continuation.finish(throwing: DifyError.apiError(statusCode: httpResponse.statusCode, message: nil))
                            return
                        }
                        
                        for try await byte in asyncBytes {
                            continuation.yield(Data([byte]))
                        }
                    } else {
                        // Fallback for older versions - use regular data request
                        let (data, response) = try await session.data(for: request)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.finish(throwing: DifyError.invalidResponse)
                            return
                        }
                        
                        guard 200...299 ~= httpResponse.statusCode else {
                            continuation.finish(throwing: DifyError.apiError(statusCode: httpResponse.statusCode, message: nil))
                            return
                        }
                        
                        continuation.yield(data)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Common API Methods

extension DifyClient {
    /// Provide feedback for a message
    /// - Parameters:
    ///   - messageId: ID of the message
    ///   - rating: Rating (like/dislike)
    ///   - user: User identifier
    /// - Returns: Feedback response
    public func messageFeedback(
        messageId: String,
        rating: MessageRating,
        user: String
    ) async throws -> MessageFeedbackResponse {
        let body = MessageFeedbackRequest(rating: rating, user: user)
        let data = try JSONEncoder().encode(body)
        
        let responseData = try await sendRequest(
            method: .POST,
            endpoint: "/messages/\(messageId)/feedbacks",
            body: data
        )
        
        return try JSONDecoder().decode(MessageFeedbackResponse.self, from: responseData)
    }
    
    /// Get application parameters
    /// - Parameter user: User identifier
    /// - Returns: Application parameters
    public func getApplicationParameters(user: String) async throws -> ApplicationParametersResponse {
        let queryItems = [URLQueryItem(name: "user", value: user)]
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/parameters",
            queryItems: queryItems
        )
        
        return try JSONDecoder().decode(ApplicationParametersResponse.self, from: data)
    }
    
    /// Upload a file
    /// - Parameters:
    ///   - fileData: File data to upload
    ///   - fileName: Name of the file
    ///   - mimeType: MIME type of the file
    ///   - user: User identifier
    /// - Returns: File upload response
    public func uploadFile(
        fileData: Data,
        fileName: String,
        mimeType: String,
        user: String
    ) async throws -> FileUploadResponse {
        let boundary = UUID().uuidString
        let body = createMultipartBody(
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            user: user,
            boundary: boundary
        )
        
        let data = try await sendRequest(
            method: .POST,
            endpoint: "/files/upload",
            body: body,
            additionalHeaders: ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        )
        
        return try JSONDecoder().decode(FileUploadResponse.self, from: data)
    }
    
    /// Convert text to audio
    /// - Parameters:
    ///   - text: Text to convert
    ///   - user: User identifier
    ///   - streaming: Whether to use streaming mode
    /// - Returns: Audio data or streaming audio
    public func textToAudio(
        text: String,
        user: String,
        streaming: Bool = false
    ) async throws -> Data {
        let body = TextToAudioRequest(text: text, user: user, streaming: streaming)
        let requestData = try JSONEncoder().encode(body)
        
        if streaming {
            // For streaming, collect all chunks
            var audioData = Data()
            let stream = sendStreamingRequest(
                method: .POST,
                endpoint: "/text-to-audio",
                body: requestData
            )
            
            for try await chunk in stream {
                audioData.append(chunk)
            }
            
            return audioData
        } else {
            return try await sendRequest(
                method: .POST,
                endpoint: "/text-to-audio",
                body: requestData
            )
        }
    }
    
    /// Get meta information
    /// - Parameter user: User identifier
    /// - Returns: Meta information
    public func getMeta(user: String) async throws -> MetaResponse {
        let queryItems = [URLQueryItem(name: "user", value: user)]
        
        let data = try await sendRequest(
            method: .GET,
            endpoint: "/meta",
            queryItems: queryItems
        )
        
        return try JSONDecoder().decode(MetaResponse.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func createMultipartBody(
        fileData: Data,
        fileName: String,
        mimeType: String,
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
        
        // Add file
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
} 