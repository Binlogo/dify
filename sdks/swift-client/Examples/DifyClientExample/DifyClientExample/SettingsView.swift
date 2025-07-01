//
//  SettingsView.swift
//  DifyClientExample
//
//  Created by Binlogo on 2025/7/2.
//

import SwiftUI
import DifyClient

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAPISettings = false
    @State private var showingAbout = false
    @State private var showingHelp = false
    @State private var showingAppInfo = false
    @State private var applicationInfo: ApplicationParametersResponse?
    @State private var isLoadingAppInfo = false
    
    var body: some View {
        NavigationView {
            List {
                // API Configuration Section
                Section {
                    SettingsRow(
                        icon: "key.fill",
                        title: "API配置",
                        subtitle: "管理API密钥和服务器设置",
                        color: .blue
                    ) {
                        showingAPISettings = true
                    }
                    
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "应用信息",
                        subtitle: isLoadingAppInfo ? "加载中..." : (applicationInfo != nil ? "查看当前应用参数" : "获取应用信息"),
                        color: .green
                    ) {
                        showApplicationInfo()
                    }
                    .disabled(isLoadingAppInfo)
                } header: {
                    Text("配置")
                }
                
                // Features Section
                Section {
                    SettingsRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "聊天功能",
                        subtitle: "智能对话和流式回复",
                        color: .purple
                    ) {}
                    
                    SettingsRow(
                        icon: "text.bubble.fill",
                        title: "文本生成",
                        subtitle: "多模板文本创作",
                        color: .orange
                    ) {}
                    
                    SettingsRow(
                        icon: "flowchart.fill",
                        title: "工作流",
                        subtitle: "复杂AI任务流程",
                        color: .teal
                    ) {}
                    
                    SettingsRow(
                        icon: "doc.badge.plus",
                        title: "文件上传",
                        subtitle: "多格式文件处理",
                        color: .indigo
                    ) {}
                } header: {
                    Text("功能介绍")
                }
                
                // Support Section
                Section {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        title: "帮助文档",
                        subtitle: "查看使用说明",
                        color: .gray
                    ) {
                        showingHelp = true
                    }
                    
                    SettingsRow(
                        icon: "link.circle.fill",
                        title: "Dify官网",
                        subtitle: "https://dify.ai",
                        color: .blue
                    ) {
                        openURL("https://dify.ai")
                    }
                    
                    SettingsRow(
                        icon: "book.circle.fill",
                        title: "API文档",
                        subtitle: "开发者参考",
                        color: .green
                    ) {
                        openURL("https://docs.dify.ai/api-reference")
                    }
                } header: {
                    Text("支持")
                }
                
                // About Section
                Section {
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "关于应用",
                        subtitle: "版本信息和开发者",
                        color: .gray
                    ) {
                        showingAbout = true
                    }
                    
                    Button("重置应用") {
                        resetApplication()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("应用")
                }
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showingAPISettings) {
            APISettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingAppInfo) {
            ApplicationInfoView(applicationInfo: applicationInfo, isLoading: isLoadingAppInfo)
        }
        .onAppear {
            loadApplicationInfo()
        }
    }
    
    private func showApplicationInfo() {
        if applicationInfo == nil && !isLoadingAppInfo {
            loadApplicationInfo()
        }
        showingAppInfo = true
    }
    
    private func loadApplicationInfo() {
        isLoadingAppInfo = true
        
        Task {
            do {
                let client = DifyClient(apiKey: appState.apiKey, baseURL: appState.baseURL)
                let info = try await client.getApplicationParameters(user: appState.userId)
                
                await MainActor.run {
                    applicationInfo = info
                    isLoadingAppInfo = false
                }
            } catch {
                await MainActor.run {
                    isLoadingAppInfo = false
                }
            }
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }
    
    private func resetApplication() {
        appState.reset()
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - API Settings View

struct APISettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var isValidating = false
    @State private var validationResult: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API密钥")
                            .font(.headline)
                        
                        SecureField("请输入您的Dify API密钥", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API基础URL")
                            .font(.headline)
                        
                        TextField("API基础URL", text: $baseURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            #endif
                    }
                    
                    if !validationResult.isEmpty {
                        Text(validationResult)
                            .font(.caption)
                            .foregroundColor(validationResult.contains("成功") ? .green : .red)
                    }
                }
                .padding()
                
                VStack(spacing: 12) {
                    Button(action: validateConfiguration) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isValidating ? "验证中..." : "验证配置")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                    
                    Button(action: saveConfiguration) {
                        Text("保存配置")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(apiKey.isEmpty)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("API设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            apiKey = appState.apiKey
            baseURL = appState.baseURL
        }
    }
    
    private func validateConfiguration() {
        isValidating = true
        validationResult = ""
        
        Task {
            do {
                let client = DifyClient(apiKey: apiKey, baseURL: baseURL)
                let _ = try await client.getApplicationParameters(user: appState.userId)
                
                await MainActor.run {
                    validationResult = "配置验证成功！"
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    validationResult = "验证失败: \(error.localizedDescription)"
                    isValidating = false
                }
            }
        }
    }
    
    private func saveConfiguration() {
        appState.configure(apiKey: apiKey, baseURL: baseURL)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // App Icon and Name
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Dify Swift Client")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("示例应用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Version Info
                VStack(spacing: 12) {
                    InfoRow(title: "版本", value: "1.0.0")
                    InfoRow(title: "构建版本", value: "1")
                    InfoRow(title: "Swift版本", value: "5.9+")
                    InfoRow(title: "平台支持", value: "iOS 13+, macOS 10.15+")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Developer Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("开发者信息")
                        .font(.headline)
                    
                    Text("这是一个展示Dify Swift SDK功能的示例应用。它演示了如何集成和使用Dify的各种AI服务，包括聊天、文本生成、工作流和文件上传等功能。")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Links
                VStack(spacing: 8) {
                    Link("访问Dify官网", destination: URL(string: "https://dify.ai")!)
                    Link("查看API文档", destination: URL(string: "https://docs.dify.ai")!)
                    Link("GitHub仓库", destination: URL(string: "https://github.com/langgenius/dify")!)
                }
                .font(.caption)
            }
            .padding()
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let helpSections = [
        HelpSection(
            title: "快速开始",
            items: [
                "1. 在设置中配置您的Dify API密钥",
                "2. 选择功能模块开始体验",
                "3. 查看各功能的详细说明和示例"
            ]
        ),
        HelpSection(
            title: "聊天功能",
            items: [
                "• 支持实时对话和历史记录",
                "• 可选择流式或非流式回复",
                "• 支持对话管理和反馈"
            ]
        ),
        HelpSection(
            title: "文本生成",
            items: [
                "• 提供多种文本模板",
                "• 支持自定义输入参数",
                "• 可复制和分享生成结果"
            ]
        ),
        HelpSection(
            title: "工作流",
            items: [
                "• 执行复杂的AI任务流程",
                "• 支持自定义输入参数",
                "• 实时查看执行进度和结果"
            ]
        ),
        HelpSection(
            title: "文件上传",
            items: [
                "• 支持图片、文档等多种格式",
                "• 安全的云端存储",
                "• 可用于AI模型分析处理"
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            List(helpSections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.items, id: \.self) { item in
                        Text(item)
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("帮助文档")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct HelpSection {
    let title: String
    let items: [String]
}

// MARK: - Application Info View

struct ApplicationInfoView: View {
    let applicationInfo: ApplicationParametersResponse?
    let isLoading: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("正在获取应用信息...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else if let info = applicationInfo {
                        // App icon and name
                        VStack(spacing: 16) {
                            Image(systemName: "app.badge")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("应用参数")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding()
                        
                        // User input forms
                        if let userInputForm = info.userInputForm, !userInputForm.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("用户输入表单")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(Array(userInputForm.enumerated()), id: \.offset) { index, form in
                                    UserInputFormView(form: form)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Opening statement
                        if let openingStatement = info.openingStatement, !openingStatement.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("开场白")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Text(openingStatement)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Features
                        VStack(alignment: .leading, spacing: 12) {
                            Text("功能特性")
                                .font(.headline)
                                .padding(.horizontal)
                            
                                                         VStack(spacing: 8) {
                                 FeatureItem(
                                     title: "建议问题",
                                     enabled: info.suggestedQuestionsAfterAnswer?.enabled ?? false
                                 )
                                 
                                 FeatureItem(
                                     title: "语音转文字",
                                     enabled: info.speechToText?.enabled ?? false
                                 )
                                 
                                 FeatureItem(
                                     title: "文字转语音",
                                     enabled: info.textToSpeech?.enabled ?? false
                                 )
                                 
                                 FeatureItem(
                                     title: "注释回复",
                                     enabled: info.annotationReply?.enabled ?? false
                                 )
                             }
                            .padding(.horizontal)
                        }
                        
                        // File upload info
                        if info.fileUpload != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("文件上传支持")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 4) {
                                    if let image = info.fileUpload?.image {
                                        FileUploadItem(type: "图片", config: image)
                                    }
                                    if let document = info.fileUpload?.document {
                                        FileUploadItem(type: "文档", config: document)
                                    }
                                    if let audio = info.fileUpload?.audio {
                                        FileUploadItem(type: "音频", config: audio)
                                    }
                                    if let video = info.fileUpload?.video {
                                        FileUploadItem(type: "视频", config: video)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("无法获取应用信息")
                                .font(.headline)
                            
                            Text("请检查API配置是否正确")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("应用信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views for Application Info

struct UserInputFormView: View {
    let form: UserInputForm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(form.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if form.required {
                    Text("*")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("变量: \(form.variable)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let maxLength = form.maxLength {
                Text("最大长度: \(maxLength)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct FeatureItem: View {
    let title: String
    let enabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(enabled ? .green : .red)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(enabled ? "已启用" : "未启用")
                .font(.caption)
                .foregroundColor(enabled ? .green : .secondary)
        }
        .padding(.vertical, 2)
    }
}

struct FileUploadItem: View {
    let type: String
    let config: FileUploadConfig
    
    var body: some View {
        HStack {
            Image(systemName: "doc.badge.plus")
                .foregroundColor(config.enabled ? .blue : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type)
                    .font(.subheadline)
                
                if config.enabled {
                    HStack {
                        if let numberLimits = config.numberLimits {
                            Text("数量限制: \(numberLimits)")
                        }
                        if let fileSize = config.fileSize {
                            Text("大小限制: \(fileSize)MB")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    
                    if let extensions = config.extensions, !extensions.isEmpty {
                        Text("支持格式: \(extensions.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(config.enabled ? "支持" : "不支持")
                .font(.caption)
                .foregroundColor(config.enabled ? .green : .secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
} 