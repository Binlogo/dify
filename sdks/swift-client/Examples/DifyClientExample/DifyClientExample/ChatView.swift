//
//  ChatView.swift
//  DifyClientExample
//
//  Created by Binlogo on 2025/7/2.
//

import SwiftUI
import DifyClient

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var chatManager = ChatManager()
    @State private var messageText = ""
    @State private var isStreaming = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatManager.messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if chatManager.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("正在思考...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatManager.messages.count) { _ in
                        if let lastMessage = chatManager.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input area
                VStack(spacing: 12) {
                    // Options
                    HStack {
                        Toggle("流式回复", isOn: $isStreaming)
                            .font(.caption)
                        
                        Spacer()
                        
                        if chatManager.currentConversationId != nil {
                            Button("新对话") {
                                chatManager.startNewConversation()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Input field
                    HStack(spacing: 12) {
                        TextField("输入您的消息...", text: $messageText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(1...4)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(messageText.isEmpty ? Color.gray : Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(messageText.isEmpty || chatManager.isLoading)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI 聊天")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("清空对话") {
                            chatManager.clearMessages()
                        }
                        
                        Button("查看对话列表") {
                            // TODO: 实现对话列表
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            chatManager.configure(apiKey: appState.apiKey, baseURL: appState.baseURL, userId: appState.userId)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = messageText
        messageText = ""
        
        if isStreaming {
            chatManager.sendStreamingMessage(userMessage)
        } else {
            chatManager.sendMessage(userMessage)
        }
    }
}

// MARK: - Chat Message View

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity * 0.7, alignment: .trailing)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.primary)
                            .font(.caption)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content.isEmpty ? "..." : message.content)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity * 0.7, alignment: .leading)
                        .opacity(message.content.isEmpty ? 0.5 : 1.0)
                    
                    HStack {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if message.canProvideFeedback {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button {
                                    // TODO: 实现点赞功能
                                } label: {
                                    Image(systemName: "hand.thumbsup")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button {
                                    // TODO: 实现点踩功能
                                } label: {
                                    Image(systemName: "hand.thumbsdown")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Chat Manager

class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var currentConversationId: String?
    
    private var apiKey = ""
    private var baseURL = ""
    private var userId = ""
    private var chatClient: ChatClient?
    
    func configure(apiKey: String, baseURL: String, userId: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.userId = userId
        self.chatClient = ChatClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    func sendMessage(_ content: String) {
        guard let chatClient = chatClient else { 
            print("❌ ChatManager: chatClient is nil")
            return 
        }
        
        print("🚀 ChatManager: Sending message")
        
        // Add user message
        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        
        isLoading = true
        
        Task {
            do {
                let response = try await chatClient.createChatMessage(
                    inputs: [:],
                    query: content,
                    user: userId,
                    conversationId: currentConversationId
                )
                
                print("✅ ChatManager: Received response")
                
                await MainActor.run {
                    let aiMessage = ChatMessage(
                        content: response.answer,
                        isUser: false,
                        messageId: response.id,
                        canProvideFeedback: true
                    )
                    messages.append(aiMessage)
                    currentConversationId = response.conversationId
                    isLoading = false
                }
            } catch {
                print("❌ ChatManager: Error sending message: \(error)")
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: "抱歉，发生了错误：\(error.localizedDescription)",
                        isUser: false
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    func sendStreamingMessage(_ content: String) {
        guard let chatClient = chatClient else { 
            print("❌ ChatManager: chatClient is nil for streaming")
            return 
        }
        
        print("🌊 ChatManager: Sending streaming message")
        
        // Add user message
        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        
        // Add placeholder AI message with unique identifier
        let placeholderMessage = ChatMessage(content: "", isUser: false)
        let placeholderIndex = messages.count
        messages.append(placeholderMessage)
        
        isLoading = true
        
        Task {
            let stream = chatClient.createChatMessageStream(
                inputs: [:],
                query: content,
                user: userId,
                conversationId: currentConversationId
            )
            
            do {
                for try await chunk in stream {
                    await MainActor.run {
                        // 简化的调试信息
                        if let event = chunk.event {
                            print("📨 ChatManager: \(event) - Answer: '\(chunk.answer ?? "nil")'")
                        }
                        
                        // Use the specific index instead of searching for last non-user message
                        if placeholderIndex < messages.count && !messages[placeholderIndex].isUser {
                            
                            // 检查是否有 answer 内容，不管事件类型
                            if let answer = chunk.answer, !answer.isEmpty {
                                // 创建新的消息对象来触发SwiftUI更新
                                let updatedMessage = ChatMessage(
                                    content: messages[placeholderIndex].content + answer,
                                    isUser: false,
                                    messageId: chunk.messageId ?? messages[placeholderIndex].messageId,
                                    canProvideFeedback: messages[placeholderIndex].canProvideFeedback
                                )
                                messages[placeholderIndex] = updatedMessage
                                
                                // 更新会话ID
                                if let conversationId = chunk.conversationId {
                                    currentConversationId = conversationId
                                }
                            } else {
                                // 对于 message_end 事件，确保设置 canProvideFeedback
                                if let event = chunk.event, event == "message_end" {
                                    let finalMessage = ChatMessage(
                                        content: messages[placeholderIndex].content,
                                        isUser: false,
                                        messageId: chunk.messageId ?? messages[placeholderIndex].messageId,
                                        canProvideFeedback: true
                                    )
                                    messages[placeholderIndex] = finalMessage
                                    print("✅ ChatManager: Message finalized with feedback enabled")
                                }
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    let finalContent = placeholderIndex < messages.count ? messages[placeholderIndex].content : ""
                    
                    if finalContent.isEmpty {
                        print("⚠️ ChatManager: Message content is empty after streaming!")
                    } else {
                        print("✅ ChatManager: Streaming completed")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ ChatManager: Streaming error: \(error)")
                    
                    // 添加错误消息
                    if placeholderIndex < messages.count {
                        messages[placeholderIndex].content = "流式响应出错: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func clearMessages() {
        messages.removeAll()
        currentConversationId = nil
    }
    
    func startNewConversation() {
        currentConversationId = nil
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    var content: String
    let isUser: Bool
    let timestamp = Date()
    let messageId: String?
    let canProvideFeedback: Bool
    
    init(content: String, isUser: Bool, messageId: String? = nil, canProvideFeedback: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.messageId = messageId
        self.canProvideFeedback = canProvideFeedback
    }
    
    func appendingContent(_ newContent: String) -> ChatMessage {
        ChatMessage(
            content: content + newContent,
            isUser: isUser,
            messageId: messageId,
            canProvideFeedback: canProvideFeedback
        )
    }
    
    func withMessageId(_ id: String) -> ChatMessage {
        ChatMessage(
            content: content,
            isUser: isUser,
            messageId: id,
            canProvideFeedback: canProvideFeedback
        )
    }
    
    func withFeedbackEnabled(_ enabled: Bool) -> ChatMessage {
        ChatMessage(
            content: content,
            isUser: isUser,
            messageId: messageId,
            canProvideFeedback: enabled
        )
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    ChatView()
        .environmentObject(AppState())
} 