//
//  WorkflowView.swift
//  DifyClientExample
//
//  Created by Binlogo on 2025/7/2.
//

import SwiftUI
import DifyClient

struct WorkflowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var workflowManager = WorkflowManager()
    @State private var workflowInputs: [String: String] = [:]
    @State private var isStreaming = true
    @State private var showingAddInput = false
    @State private var newInputKey = ""
    @State private var newInputValue = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Workflow Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("工作流执行")
                            .font(.headline)
                        
                        InfoCard(
                            icon: "flowchart",
                            title: "智能工作流",
                            description: "使用Dify工作流API执行复杂的AI任务流程"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Input Parameters
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("输入参数")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingAddInput = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if workflowInputs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "square.dashed")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                
                                Text("暂无输入参数")
                                    .foregroundColor(.secondary)
                                
                                Button("添加示例参数") {
                                    addSampleInputs()
                                }
                                .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(workflowInputs.keys.sorted()), id: \.self) { key in
                                    InputParameterRow(
                                        key: key,
                                        value: Binding(
                                            get: { workflowInputs[key] ?? "" },
                                            set: { workflowInputs[key] = $0 }
                                        )
                                    ) {
                                        workflowInputs.removeValue(forKey: key)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Execution Options
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("流式执行", isOn: $isStreaming)
                            
                            Spacer()
                            
                            Button("清空结果") {
                                workflowManager.clearResults()
                            }
                            .foregroundColor(.red)
                            .disabled(workflowManager.results.isEmpty)
                        }
                        
                        Button(action: executeWorkflow) {
                            HStack {
                                if workflowManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(workflowManager.isLoading ? "执行中..." : "执行工作流")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(workflowInputs.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(workflowInputs.isEmpty || workflowManager.isLoading)
                    }
                    .padding(.horizontal)
                    
                    // Results Section
                    if !workflowManager.results.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("执行结果")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(workflowManager.results) { result in
                                WorkflowResultView(result: result)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("工作流")
            .sheet(isPresented: $showingAddInput) {
                AddInputSheet(
                    key: $newInputKey,
                    value: $newInputValue,
                    onAdd: {
                        if !newInputKey.isEmpty {
                            workflowInputs[newInputKey] = newInputValue
                            newInputKey = ""
                            newInputValue = ""
                            showingAddInput = false
                        }
                    },
                    onCancel: {
                        newInputKey = ""
                        newInputValue = ""
                        showingAddInput = false
                    }
                )
            }
        }
        .onAppear {
            workflowManager.configure(apiKey: appState.apiKey, baseURL: appState.baseURL, userId: appState.userId)
        }
    }
    
    private func executeWorkflow() {
        let inputs = workflowInputs.mapValues { $0 as Any }
        
        if isStreaming {
            workflowManager.executeStreamingWorkflow(inputs: inputs)
        } else {
            workflowManager.executeWorkflow(inputs: inputs)
        }
    }
    
    private func addSampleInputs() {
        workflowInputs = [
            "task": "文本分析",
            "content": "今天天气真好，我心情很愉快！",
            "language": "中文"
        ]
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Input Parameter Row

struct InputParameterRow: View {
    let key: String
    @Binding var value: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(key)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("输入值", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Input Sheet

struct AddInputSheet: View {
    @Binding var key: String
    @Binding var value: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("参数名称")
                        .font(.headline)
                    
                    TextField("例如: task, content, language", text: $key)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("参数值")
                        .font(.headline)
                    
                    TextEditor(text: $value)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("添加参数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        onAdd()
                    }
                    .disabled(key.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Workflow Result View

struct WorkflowResultView: View {
    let result: WorkflowResult
    @State private var showCopySuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("执行时间: \(result.timestamp, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let executionTime = result.executionTime {
                        Text("耗时: \(String(format: "%.2f", executionTime))秒")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        copyToClipboard(result.content)
                    } label: {
                        Image(systemName: showCopySuccess ? "checkmark" : "doc.on.doc")
                            .foregroundColor(.green)
                    }
                    
                    Menu {
                        Button("查看详情") {
                            // TODO: 实现详情查看
                        }
                        Button("分享结果") {
                            shareText(result.content)
                        }
                        Button("删除结果") {
                            // TODO: 实现删除功能
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            
            if result.isStreaming && result.content.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在执行工作流...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(result.content)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
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

// MARK: - Workflow Manager

class WorkflowManager: ObservableObject {
    @Published var results: [WorkflowResult] = []
    @Published var isLoading = false
    
    private var apiKey = ""
    private var baseURL = ""
    private var userId = ""
    private var workflowClient: WorkflowClient?
    
    func configure(apiKey: String, baseURL: String, userId: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.userId = userId
        self.workflowClient = WorkflowClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    func executeWorkflow(inputs: [String: Any]) {
        guard let workflowClient = workflowClient else { return }
        
        isLoading = true
        let startTime = Date()
        
        Task {
            do {
                let response = try await workflowClient.run(
                    inputs: inputs,
                    user: userId
                )
                
                let executionTime = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    let result = WorkflowResult(
                        content: response.answer,
                        executionTime: executionTime
                    )
                    results.insert(result, at: 0)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorResult = WorkflowResult(
                        content: "执行失败：\(error.localizedDescription)"
                    )
                    results.insert(errorResult, at: 0)
                    isLoading = false
                }
            }
        }
    }
    
    func executeStreamingWorkflow(inputs: [String: Any]) {
        guard let workflowClient = workflowClient else { return }
        
        isLoading = true
        let startTime = Date()
        
        // Add placeholder result
        let placeholderResult = WorkflowResult(content: "", isStreaming: true)
        results.insert(placeholderResult, at: 0)
        
        Task {
            let stream = workflowClient.runStream(
                inputs: inputs,
                user: userId
            )
            
            do {
                for try await chunk in stream {
                    await MainActor.run {
                        if !results.isEmpty, let answer = chunk.answer {
                            let executionTime = Date().timeIntervalSince(startTime)
                            results[0] = results[0].appendingContent(answer, executionTime: executionTime)
                        }
                    }
                }
                
                await MainActor.run {
                    if !results.isEmpty {
                        results[0] = results[0].finishStreaming()
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    if !results.isEmpty {
                        results[0] = WorkflowResult(
                            content: "执行失败：\(error.localizedDescription)"
                        )
                    }
                    isLoading = false
                }
            }
        }
    }
    
    func clearResults() {
        results.removeAll()
    }
}

// MARK: - Workflow Result Model

struct WorkflowResult: Identifiable {
    let id = UUID()
    let content: String
    let timestamp = Date()
    let executionTime: TimeInterval?
    let isStreaming: Bool
    
    init(content: String, executionTime: TimeInterval? = nil, isStreaming: Bool = false) {
        self.content = content
        self.executionTime = executionTime
        self.isStreaming = isStreaming
    }
    
    func appendingContent(_ newContent: String, executionTime: TimeInterval) -> WorkflowResult {
        WorkflowResult(
            content: content + newContent,
            executionTime: executionTime,
            isStreaming: isStreaming
        )
    }
    
    func finishStreaming() -> WorkflowResult {
        WorkflowResult(
            content: content,
            executionTime: executionTime,
            isStreaming: false
        )
    }
}

#Preview {
    WorkflowView()
        .environmentObject(AppState())
} 