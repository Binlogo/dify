//
//  CompletionView.swift
//  DifyClientExample
//
//  Created by Binlogo on 2025/7/2.
//

import SwiftUI
import DifyClient

struct CompletionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var completionManager = CompletionManager()
    @State private var inputText = ""
    @State private var isStreaming = true
    @State private var selectedTemplate = CompletionTemplate.general
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Template Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择模板")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CompletionTemplate.allCases, id: \.self) { template in
                                    TemplateCard(
                                        template: template,
                                        isSelected: selectedTemplate == template
                                    ) {
                                        selectedTemplate = template
                                        inputText = template.promptTemplate
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("输入内容")
                            .font(.headline)
                        
                        TextEditor(text: $inputText)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("流式生成", isOn: $isStreaming)
                            
                            Spacer()
                            
                            Button("测试连接") {
                                completionManager.testConnection()
                            }
                            .foregroundColor(.orange)
                            .disabled(completionManager.isLoading)
                            
                            Button("清空结果") {
                                completionManager.clearResults()
                            }
                            .foregroundColor(.red)
                            .disabled(completionManager.results.isEmpty)
                        }
                        
                        Button(action: generateCompletion) {
                            HStack {
                                if completionManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(completionManager.isLoading ? "生成中..." : "开始生成")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(inputText.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(inputText.isEmpty || completionManager.isLoading)
                    }
                    .padding(.horizontal)
                    
                    // Results Section
                    if !completionManager.results.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("生成结果")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(completionManager.results) { result in
                                CompletionResultView(result: result)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("文本生成")
        }
        .onAppear {
            completionManager.configure(apiKey: appState.apiKey, baseURL: appState.baseURL, userId: appState.userId)
        }
    }
    
    private func generateCompletion() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let inputs = selectedTemplate.buildInputs(from: inputText)
        
        if isStreaming {
            completionManager.generateStreamingCompletion(inputs: inputs)
        } else {
            completionManager.generateCompletion(inputs: inputs)
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: CompletionTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.icon)
                    .foregroundColor(isSelected ? .white : .blue)
                Spacer()
            }
            
            Text(template.title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
            
            Text(template.description)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(width: 160, height: 100)
        .background(isSelected ? Color.blue : Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Completion Result View

struct CompletionResultView: View {
    let result: CompletionResult
    @State private var showCopySuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("生成时间: \(result.timestamp, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        copyToClipboard(result.content)
                    } label: {
                        Image(systemName: showCopySuccess ? "checkmark" : "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    
                    Menu {
                        Button("分享文本") {
                            shareText(result.content)
                        }
                        Button("删除结果") {
                            // TODO: 实现删除功能
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(result.content)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .textSelection(.enabled)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        
        showCopySuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showCopySuccess = false
        }
    }
    
    private func shareText(_ text: String) {
        #if os(iOS)
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
        #endif
    }
}

// MARK: - Completion Manager

class CompletionManager: ObservableObject {
    @Published var results: [CompletionResult] = []
    @Published var isLoading = false
    
    private var apiKey = ""
    private var baseURL = ""
    private var userId = ""
    private var completionClient: CompletionClient?
    
    func configure(apiKey: String, baseURL: String, userId: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.userId = userId
        self.completionClient = CompletionClient(apiKey: apiKey, baseURL: baseURL)
        
        // 调试信息
        print("CompletionManager configured:")
        print("- API Key: \(apiKey.prefix(10))...")
        print("- Base URL: \(baseURL)")
        print("- User ID: \(userId)")
    }
    
    func generateCompletion(inputs: [String: Any]) {
        guard let completionClient = completionClient else { 
            print("Error: completionClient is nil")
            return 
        }
        
        // 验证输入参数
        guard !userId.isEmpty else {
            let errorResult = CompletionResult(content: "生成失败：用户ID不能为空")
            results.insert(errorResult, at: 0)
            return
        }
        
        guard !inputs.isEmpty else {
            let errorResult = CompletionResult(content: "生成失败：输入参数不能为空")
            results.insert(errorResult, at: 0)
            return
        }
        
        print("Starting completion generation with inputs: \(inputs)")
        print("User ID: \(userId)")
        
        isLoading = true
        
        Task {
            do {
                let response = try await completionClient.createCompletionMessage(
                    inputs: inputs,
                    user: userId
                )
                
                await MainActor.run {
                    let result = CompletionResult(content: response.answer)
                    results.insert(result, at: 0)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    var errorMessage = "生成失败："
                    if let difyError = error as? DifyError {
                        switch difyError {
                        case .apiError(let statusCode, let message):
                            errorMessage += " API error (\(statusCode)): \(message ?? "Unknown error")"
                        case .invalidURL:
                            errorMessage += " 无效的URL"
                        case .networkError(let networkError):
                            errorMessage += " 网络错误: \(networkError.localizedDescription)"
                        case .decodingError(let decodingError):
                            errorMessage += " 解码错误: \(decodingError.localizedDescription)"
                        default:
                            errorMessage += " \(difyError.localizedDescription)"
                        }
                    } else {
                        errorMessage += " \(error.localizedDescription)"
                    }
                    
                    let errorResult = CompletionResult(content: errorMessage)
                    results.insert(errorResult, at: 0)
                    isLoading = false
                }
            }
        }
    }
    
    func generateStreamingCompletion(inputs: [String: Any]) {
        guard let completionClient = completionClient else { 
            print("Error: completionClient is nil")
            return 
        }
        
        // 验证输入参数
        guard !userId.isEmpty else {
            let errorResult = CompletionResult(content: "生成失败：用户ID不能为空")
            results.insert(errorResult, at: 0)
            return
        }
        
        guard !inputs.isEmpty else {
            let errorResult = CompletionResult(content: "生成失败：输入参数不能为空")
            results.insert(errorResult, at: 0)
            return
        }
        
        print("Starting streaming completion with inputs: \(inputs)")
        print("User ID: \(userId)")
        
        isLoading = true
        
        // Add placeholder result
        let placeholderResult = CompletionResult(content: "")
        results.insert(placeholderResult, at: 0)
        
        Task {
            let stream = completionClient.createCompletionMessageStream(
                inputs: inputs,
                user: userId
            )
            
            do {
                for try await chunk in stream {
                    await MainActor.run {
                        if !results.isEmpty, let answer = chunk.answer {
                            results[0] = results[0].appendingContent(answer)
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    var errorMessage = "生成失败："
                    if let difyError = error as? DifyError {
                        switch difyError {
                        case .apiError(let statusCode, let message):
                            errorMessage += " API error (\(statusCode)): \(message ?? "Unknown error")"
                        case .invalidURL:
                            errorMessage += " 无效的URL"
                        case .networkError(let networkError):
                            errorMessage += " 网络错误: \(networkError.localizedDescription)"
                        case .decodingError(let decodingError):
                            errorMessage += " 解码错误: \(decodingError.localizedDescription)"
                        default:
                            errorMessage += " \(difyError.localizedDescription)"
                        }
                    } else {
                        errorMessage += " \(error.localizedDescription)"
                    }
                    
                    if !results.isEmpty {
                        results[0] = CompletionResult(content: errorMessage)
                    } else {
                        results.insert(CompletionResult(content: errorMessage), at: 0)
                    }
                    isLoading = false
                }
            }
        }
    }
    
    func clearResults() {
        results.removeAll()
    }
    
    func testConnection() {
        guard let completionClient = completionClient else {
            let errorResult = CompletionResult(content: "测试失败：客户端未初始化")
            results.insert(errorResult, at: 0)
            return
        }
        
        guard !userId.isEmpty else {
            let errorResult = CompletionResult(content: "测试失败：用户ID不能为空")
            results.insert(errorResult, at: 0)
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // 使用简单的测试输入
                let testInputs = ["query": "Hello"]
                let response = try await completionClient.createCompletionMessage(
                    inputs: testInputs,
                    user: userId
                )
                
                await MainActor.run {
                    let testResult = CompletionResult(
                        content: "✅ 连接测试成功！\n\n测试回复: \(response.answer)\n\n您的API配置正常工作。"
                    )
                    results.insert(testResult, at: 0)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    var errorMessage = "❌ 连接测试失败：\n\n"
                    if let difyError = error as? DifyError {
                        switch difyError {
                        case .apiError(let statusCode, let message):
                            errorMessage += "状态码: \(statusCode)\n"
                            if let message = message {
                                errorMessage += "错误信息: \(message)\n"
                            }
                            
                            switch statusCode {
                            case 401:
                                errorMessage += "\n💡 建议：请检查API密钥是否正确"
                            case 400:
                                errorMessage += "\n💡 建议：请求格式有误，可能是API密钥或应用配置问题"
                            case 403:
                                errorMessage += "\n💡 建议：API密钥没有访问权限"
                            case 404:
                                errorMessage += "\n💡 建议：请检查API基础URL是否正确"
                            case 429:
                                errorMessage += "\n💡 建议：请求频率过高，请稍后重试"
                            case 500...599:
                                errorMessage += "\n💡 建议：服务器错误，请稍后重试"
                            default:
                                break
                            }
                        case .invalidURL:
                            errorMessage += "URL格式错误\n💡 建议：请检查API基础URL格式"
                        case .networkError(let networkError):
                            errorMessage += "网络错误: \(networkError.localizedDescription)\n💡 建议：请检查网络连接"
                        case .decodingError:
                            errorMessage += "数据解析错误\n💡 建议：API返回格式异常"
                        default:
                            errorMessage += difyError.localizedDescription
                        }
                    } else {
                        errorMessage += error.localizedDescription
                    }
                    
                    let errorResult = CompletionResult(content: errorMessage)
                    results.insert(errorResult, at: 0)
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Models

struct CompletionResult: Identifiable {
    let id = UUID()
    let content: String
    let timestamp = Date()
    
    func appendingContent(_ newContent: String) -> CompletionResult {
        CompletionResult(content: content + newContent)
    }
}

enum CompletionTemplate: String, CaseIterable {
    case general = "general"
    case email = "email"
    case article = "article"
    case summary = "summary"
    case translation = "translation"
    case creative = "creative"
    
    var title: String {
        switch self {
        case .general: return "通用问答"
        case .email: return "邮件写作"
        case .article: return "文章创作"
        case .summary: return "内容摘要"
        case .translation: return "文本翻译"
        case .creative: return "创意写作"
        }
    }
    
    var description: String {
        switch self {
        case .general: return "回答各种问题"
        case .email: return "撰写商务邮件"
        case .article: return "创作文章内容"
        case .summary: return "提取关键信息"
        case .translation: return "多语言翻译"
        case .creative: return "创意故事写作"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "questionmark.circle"
        case .email: return "envelope"
        case .article: return "doc.text"
        case .summary: return "list.bullet"
        case .translation: return "globe"
        case .creative: return "paintbrush"
        }
    }
    
    var promptTemplate: String {
        switch self {
        case .general:
            return "请回答以下问题：\n\n"
        case .email:
            return "请帮我写一封关于 [主题] 的商务邮件：\n\n"
        case .article:
            return "请写一篇关于 [主题] 的文章，要求：\n- 结构清晰\n- 内容丰富\n- 逻辑性强\n\n"
        case .summary:
            return "请总结以下内容的要点：\n\n"
        case .translation:
            return "请将以下内容翻译成 [目标语言]：\n\n"
        case .creative:
            return "请写一个关于 [主题] 的创意故事：\n\n"
        }
    }
    
    func buildInputs(from text: String) -> [String: Any] {
        return ["query": text]
    }
}

#Preview {
    CompletionView()
        .environmentObject(AppState())
} 