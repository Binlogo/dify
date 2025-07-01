import Foundation

// MARK: - Common Types

/// User representation for API calls
public typealias User = String

/// Message rating for feedback
public enum MessageRating: String, Codable {
    case like
    case dislike
}

/// Response mode for API calls
public enum ResponseMode: String, Codable {
    case blocking
    case streaming
}

/// File transfer method
public enum FileTransferMethod: String, Codable {
    case remoteURL = "remote_url"
    case localFile = "local_file"
}

/// File type
public enum FileType: String, Codable {
    case image
    case document
    case audio
    case video
}

// MARK: - File Models

/// Remote file reference
public struct RemoteFile: Codable {
    public let type: FileType
    public let transferMethod: FileTransferMethod
    public let url: String
    
    public init(type: FileType, transferMethod: FileTransferMethod = .remoteURL, url: String) {
        self.type = type
        self.transferMethod = transferMethod
        self.url = url
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case transferMethod = "transfer_method"
        case url
    }
}

/// Uploaded file reference
public struct UploadedFile: Codable {
    public let type: FileType
    public let transferMethod: FileTransferMethod
    public let uploadFileId: String
    
    public init(type: FileType, transferMethod: FileTransferMethod = .localFile, uploadFileId: String) {
        self.type = type
        self.transferMethod = transferMethod
        self.uploadFileId = uploadFileId
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case transferMethod = "transfer_method"
        case uploadFileId = "upload_file_id"
    }
}

// MARK: - Request Models

/// Message feedback request
public struct MessageFeedbackRequest: Codable {
    public let rating: MessageRating
    public let user: String
    
    public init(rating: MessageRating, user: String) {
        self.rating = rating
        self.user = user
    }
}

/// Text to audio request
public struct TextToAudioRequest: Codable {
    public let text: String
    public let user: String
    public let streaming: Bool
    
    public init(text: String, user: String, streaming: Bool = false) {
        self.text = text
        self.user = user
        self.streaming = streaming
    }
}

/// Completion message request
public struct CompletionMessageRequest: Encodable {
    public let inputs: [String: Any]
    public let user: String
    public let responseMode: ResponseMode
    public let files: [Any]?
    
    public init(inputs: [String: Any], user: String, responseMode: ResponseMode, files: [Any]? = nil) {
        self.inputs = inputs
        self.user = user
        self.responseMode = responseMode
        self.files = files
    }
    
    private enum CodingKeys: String, CodingKey {
        case inputs, user, files
        case responseMode = "response_mode"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(responseMode, forKey: .responseMode)
        
        // Handle Any type for inputs
        let inputsData = try JSONSerialization.data(withJSONObject: inputs)
        if let inputsDict = try JSONSerialization.jsonObject(with: inputsData) as? [String: Any] {
            try container.encode(AnyCodable(inputsDict), forKey: .inputs)
        }
        
        // Handle files array
        if let files = files {
            try container.encode(AnyCodable(files), forKey: .files)
        }
    }
}

/// Chat message request
public struct ChatMessageRequest: Encodable {
    public let inputs: [String: Any]
    public let query: String
    public let user: String
    public let responseMode: ResponseMode
    public let conversationId: String?
    public let files: [Any]?
    
    public init(
        inputs: [String: Any],
        query: String,
        user: String,
        responseMode: ResponseMode,
        conversationId: String? = nil,
        files: [Any]? = nil
    ) {
        self.inputs = inputs
        self.query = query
        self.user = user
        self.responseMode = responseMode
        self.conversationId = conversationId
        self.files = files
    }
    
    private enum CodingKeys: String, CodingKey {
        case inputs, query, user, files
        case responseMode = "response_mode"
        case conversationId = "conversation_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(query, forKey: .query)
        try container.encode(user, forKey: .user)
        try container.encode(responseMode, forKey: .responseMode)
        try container.encodeIfPresent(conversationId, forKey: .conversationId)
        
        // Handle Any type for inputs
        let inputsData = try JSONSerialization.data(withJSONObject: inputs)
        if let inputsDict = try JSONSerialization.jsonObject(with: inputsData) as? [String: Any] {
            try container.encode(AnyCodable(inputsDict), forKey: .inputs)
        }
        
        // Handle files array
        if let files = files {
            try container.encode(AnyCodable(files), forKey: .files)
        }
    }
}

/// Workflow run request
public struct WorkflowRunRequest: Encodable {
    public let inputs: [String: Any]
    public let user: String
    public let responseMode: ResponseMode
    
    public init(inputs: [String: Any], user: String, responseMode: ResponseMode) {
        self.inputs = inputs
        self.user = user
        self.responseMode = responseMode
    }
    
    private enum CodingKeys: String, CodingKey {
        case inputs, user
        case responseMode = "response_mode"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(responseMode, forKey: .responseMode)
        
        // Handle Any type for inputs
        let inputsData = try JSONSerialization.data(withJSONObject: inputs)
        if let inputsDict = try JSONSerialization.jsonObject(with: inputsData) as? [String: Any] {
            try container.encode(AnyCodable(inputsDict), forKey: .inputs)
        }
    }
}

/// Rename conversation request
public struct RenameConversationRequest: Codable {
    public let name: String
    public let user: String
    public let autoGenerate: Bool
    
    public init(name: String, user: String, autoGenerate: Bool = false) {
        self.name = name
        self.user = user
        self.autoGenerate = autoGenerate
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, user
        case autoGenerate = "auto_generate"
    }
}

/// Stop task request
public struct StopTaskRequest: Codable {
    public let user: String
    
    public init(user: String) {
        self.user = user
    }
}

// MARK: - Response Models

/// Message feedback response
public struct MessageFeedbackResponse: Codable {
    public let result: String
}

/// Application parameters response
public struct ApplicationParametersResponse: Codable {
    public let openingStatement: String?
    public let suggestedQuestions: [String]?
    public let suggestedQuestionsAfterAnswer: SuggestedQuestionsAfterAnswer?
    public let speechToText: SpeechToText?
    public let textToSpeech: TextToSpeech?
    public let retrieverResource: RetrieverResource?
    public let annotationReply: AnnotationReply?
    public let userInputForm: [UserInputForm]?
    public let fileUpload: FileUpload?
    public let systemParameters: SystemParameters?
    
    private enum CodingKeys: String, CodingKey {
        case openingStatement = "opening_statement"
        case suggestedQuestions = "suggested_questions"
        case suggestedQuestionsAfterAnswer = "suggested_questions_after_answer"
        case speechToText = "speech_to_text"
        case textToSpeech = "text_to_speech"
        case retrieverResource = "retriever_resource"
        case annotationReply = "annotation_reply"
        case userInputForm = "user_input_form"
        case fileUpload = "file_upload"
        case systemParameters = "system_parameters"
    }
}

/// File upload response
public struct FileUploadResponse: Codable {
    public let id: String
    public let name: String
    public let size: Int
    public let `extension`: String?
    public let mimeType: String?
    public let createdBy: String
    public let createdAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, size, `extension`
        case mimeType = "mime_type"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

/// Meta response
public struct MetaResponse: Codable {
    public let tool_icons: [String: String]?
}

/// Message response
public struct MessageResponse: Codable {
    public let id: String
    public let answer: String
    public let createdAt: String
    public let conversationId: String?
    public let feedback: MessageFeedback?
    public let retrieverResources: [RetrieverResource]?
    public let metadata: MessageMetadata?
    
    private enum CodingKeys: String, CodingKey {
        case id, answer, feedback, metadata
        case createdAt = "created_at"
        case conversationId = "conversation_id"
        case retrieverResources = "retriever_resources"
    }
}

/// Conversation response
public struct ConversationResponse: Decodable {
    public let id: String
    public let name: String
    public let inputs: [String: Any]
    public let status: String
    public let introduction: String
    public let createdAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, inputs, status, introduction
        case createdAt = "created_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(String.self, forKey: .status)
        introduction = try container.decode(String.self, forKey: .introduction)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        
        // Handle Any type for inputs
        if let inputsData = try? container.decode(AnyCodable.self, forKey: .inputs) {
            inputs = inputsData.value as? [String: Any] ?? [:]
        } else {
            inputs = [:]
        }
    }
}

/// Conversations list response
public struct ConversationsResponse: Decodable {
    public let data: [ConversationResponse]
    public let hasMore: Bool
    public let limit: Int
    
    private enum CodingKeys: String, CodingKey {
        case data, limit
        case hasMore = "has_more"
    }
}

/// Messages list response
public struct MessagesResponse: Codable {
    public let data: [MessageResponse]
    public let hasMore: Bool
    public let limit: Int
    
    private enum CodingKeys: String, CodingKey {
        case data, limit
        case hasMore = "has_more"
    }
}

/// Suggested questions response
public struct SuggestedQuestionsResponse: Codable {
    public let data: [String]
}

// MARK: - Supporting Models

public struct SuggestedQuestionsAfterAnswer: Codable {
    public let enabled: Bool
}

public struct SpeechToText: Codable {
    public let enabled: Bool
}

public struct TextToSpeech: Codable {
    public let enabled: Bool
    public let language: String?
    public let voice: String?
}

public struct RetrieverResource: Codable {
    public let position: Int?
    public let datasetId: String?
    public let datasetName: String?
    public let documentId: String?
    public let documentName: String?
    public let segmentId: String?
    public let score: Double?
    public let content: String?
    
    private enum CodingKeys: String, CodingKey {
        case position, content, score
        case datasetId = "dataset_id"
        case datasetName = "dataset_name"
        case documentId = "document_id"
        case documentName = "document_name"
        case segmentId = "segment_id"
    }
}

public struct AnnotationReply: Codable {
    public let enabled: Bool
}

public struct UserInputForm: Codable {
    public let label: String
    public let variable: String
    public let required: Bool
    public let maxLength: Int?
    
    private enum CodingKeys: String, CodingKey {
        case label, variable, required
        case maxLength = "max_length"
    }
}

public struct FileUpload: Codable {
    public let image: FileUploadConfig?
    public let document: FileUploadConfig?
    public let audio: FileUploadConfig?
    public let video: FileUploadConfig?
}

public struct FileUploadConfig: Codable {
    public let enabled: Bool
    public let numberLimits: Int?
    public let extensions: [String]?
    public let fileSize: Int?
    
    private enum CodingKeys: String, CodingKey {
        case enabled, extensions
        case numberLimits = "number_limits"
        case fileSize = "file_size"
    }
}

public struct SystemParameters: Codable {
    public let imageFileSize: Int?
    public let videoFileSize: Int?
    public let audioFileSize: Int?
    public let documentFileSize: Int?
    
    private enum CodingKeys: String, CodingKey {
        case imageFileSize = "image_file_size"
        case videoFileSize = "video_file_size"
        case audioFileSize = "audio_file_size"
        case documentFileSize = "document_file_size"
    }
}

public struct MessageFeedback: Codable {
    public let rating: MessageRating?
}

public struct MessageMetadata: Codable {
    public let usage: Usage?
    public let retrieverResources: [RetrieverResource]?
    
    private enum CodingKeys: String, CodingKey {
        case usage
        case retrieverResources = "retriever_resources"
    }
}

public struct Usage: Codable {
    public let promptTokens: Int?
    public let promptUnitPrice: String?
    public let promptPriceUnit: String?
    public let promptPrice: String?
    public let completionTokens: Int?
    public let completionUnitPrice: String?
    public let completionPriceUnit: String?
    public let completionPrice: String?
    public let totalTokens: Int?
    public let totalPrice: String?
    public let currency: String?
    public let latency: Double?
    
    private enum CodingKeys: String, CodingKey {
        case currency, latency
        case promptTokens = "prompt_tokens"
        case promptUnitPrice = "prompt_unit_price"
        case promptPriceUnit = "prompt_price_unit"
        case promptPrice = "prompt_price"
        case completionTokens = "completion_tokens"
        case completionUnitPrice = "completion_unit_price"
        case completionPriceUnit = "completion_price_unit"
        case completionPrice = "completion_price"
        case totalTokens = "total_tokens"
        case totalPrice = "total_price"
    }
}

// MARK: - Helper Types

/// Type-erased wrapper for encoding Any values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let encodableArray = array.map { AnyCodable($0) }
            try container.encode(encodableArray)
        case let dictionary as [String: Any]:
            let encodableDictionary = dictionary.mapValues { AnyCodable($0) }
            try container.encode(encodableDictionary)
        default:
            try container.encodeNil()
        }
    }
} 