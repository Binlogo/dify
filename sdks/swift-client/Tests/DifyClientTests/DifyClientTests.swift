import XCTest
@testable import DifyClient

final class DifyClientTests: XCTestCase {
    
    func testDifyClientInitialization() {
        let apiKey = "test-api-key"
        let client = DifyClient(apiKey: apiKey)
        
        XCTAssertEqual(client.apiKey, apiKey)
        XCTAssertEqual(client.baseURL, difyBaseURL)
    }
    
    func testCustomBaseURL() {
        let apiKey = "test-api-key"
        let customBaseURL = "https://custom.api.com/v1"
        let client = DifyClient(apiKey: apiKey, baseURL: customBaseURL)
        
        XCTAssertEqual(client.apiKey, apiKey)
        XCTAssertEqual(client.baseURL, customBaseURL)
    }
    
    func testUpdateApiKey() {
        let originalApiKey = "original-key"
        let newApiKey = "new-key"
        let client = DifyClient(apiKey: originalApiKey)
        
        let updatedClient = client.updateApiKey(newApiKey)
        
        XCTAssertEqual(updatedClient.apiKey, newApiKey)
        XCTAssertEqual(updatedClient.baseURL, client.baseURL)
    }
    
    func testCompletionClientInheritance() {
        let apiKey = "test-api-key"
        let completionClient = CompletionClient(apiKey: apiKey)
        
        XCTAssertEqual(completionClient.apiKey, apiKey)
        XCTAssertTrue(completionClient is DifyClient)
    }
    
    func testChatClientInheritance() {
        let apiKey = "test-api-key"
        let chatClient = ChatClient(apiKey: apiKey)
        
        XCTAssertEqual(chatClient.apiKey, apiKey)
        XCTAssertTrue(chatClient is DifyClient)
    }
    
    func testWorkflowClientInheritance() {
        let apiKey = "test-api-key"
        let workflowClient = WorkflowClient(apiKey: apiKey)
        
        XCTAssertEqual(workflowClient.apiKey, apiKey)
        XCTAssertTrue(workflowClient is DifyClient)
    }
    
    func testMessageRatingEnum() {
        XCTAssertEqual(MessageRating.like.rawValue, "like")
        XCTAssertEqual(MessageRating.dislike.rawValue, "dislike")
    }
    
    func testResponseModeEnum() {
        XCTAssertEqual(ResponseMode.blocking.rawValue, "blocking")
        XCTAssertEqual(ResponseMode.streaming.rawValue, "streaming")
    }
    
    func testFileTypeEnum() {
        XCTAssertEqual(FileType.image.rawValue, "image")
        XCTAssertEqual(FileType.document.rawValue, "document")
        XCTAssertEqual(FileType.audio.rawValue, "audio")
        XCTAssertEqual(FileType.video.rawValue, "video")
    }
    
    func testFileTransferMethodEnum() {
        XCTAssertEqual(FileTransferMethod.remoteURL.rawValue, "remote_url")
        XCTAssertEqual(FileTransferMethod.localFile.rawValue, "local_file")
    }
    
    func testRemoteFileInitialization() {
        let remoteFile = RemoteFile(
            type: .image,
            url: "https://example.com/image.jpg"
        )
        
        XCTAssertEqual(remoteFile.type, .image)
        XCTAssertEqual(remoteFile.transferMethod, .remoteURL)
        XCTAssertEqual(remoteFile.url, "https://example.com/image.jpg")
    }
    
    func testUploadedFileInitialization() {
        let uploadedFile = UploadedFile(
            type: .document,
            uploadFileId: "upload-123"
        )
        
        XCTAssertEqual(uploadedFile.type, .document)
        XCTAssertEqual(uploadedFile.transferMethod, .localFile)
        XCTAssertEqual(uploadedFile.uploadFileId, "upload-123")
    }
    
    func testDifyErrorDescription() {
        let invalidURLError = DifyError.invalidURL
        XCTAssertEqual(invalidURLError.errorDescription, "Invalid URL")
        
        let noDataError = DifyError.noData
        XCTAssertEqual(noDataError.errorDescription, "No data received")
        
        let invalidResponseError = DifyError.invalidResponse
        XCTAssertEqual(invalidResponseError.errorDescription, "Invalid response")
        
        let apiError = DifyError.apiError(statusCode: 404, message: "Not found")
        XCTAssertEqual(apiError.errorDescription, "API error (404): Not found")
    }
} 