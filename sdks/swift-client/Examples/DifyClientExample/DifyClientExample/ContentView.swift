//
//  ContentView.swift
//  DifyClientExample
//
//  Created by Binlogo on 2025/7/2.
//

import SwiftUI
import DifyClient

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        if appState.isConfigured {
            MainTabView()
                .environmentObject(appState)
        } else {
            SetupView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var apiKey: String = ""
    @Published var baseURL: String = "https://api.dify.ai/v1"
    @Published var isConfigured: Bool = false
    @Published var userId: String = ""
    
    func configure(apiKey: String, baseURL: String = "https://api.dify.ai/v1") {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.isConfigured = !apiKey.isEmpty
        
        // 如果userId为空，生成一个新的
        if self.userId.isEmpty {
            self.userId = "user-\(UUID().uuidString.prefix(8))"
        }
        
        // 持久化存储
        UserDefaults.standard.set(apiKey, forKey: "dify_api_key")
        UserDefaults.standard.set(baseURL, forKey: "dify_base_url")
        UserDefaults.standard.set(userId, forKey: "dify_user_id")
        UserDefaults.standard.set(isConfigured, forKey: "dify_is_configured")
    }
    
    init() {
        // 从存储中恢复配置
        self.apiKey = UserDefaults.standard.string(forKey: "dify_api_key") ?? ""
        self.baseURL = UserDefaults.standard.string(forKey: "dify_base_url") ?? "https://api.dify.ai/v1"
        self.userId = UserDefaults.standard.string(forKey: "dify_user_id") ?? "user-\(UUID().uuidString.prefix(8))"
        self.isConfigured = UserDefaults.standard.bool(forKey: "dify_is_configured") && !apiKey.isEmpty
    }
    
    func reset() {
        apiKey = ""
        baseURL = "https://api.dify.ai/v1"
        userId = "user-\(UUID().uuidString.prefix(8))"
        isConfigured = false
        
        UserDefaults.standard.removeObject(forKey: "dify_api_key")
        UserDefaults.standard.removeObject(forKey: "dify_base_url")
        UserDefaults.standard.removeObject(forKey: "dify_user_id")
        UserDefaults.standard.removeObject(forKey: "dify_is_configured")
    }
}

// MARK: - Setup View

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey = ""
    @State private var baseURL = "https://api.dify.ai/v1"
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Dify Swift Client")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("配置您的API密钥以开始使用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Configuration Form
                VStack(spacing: 20) {
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
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: validateAndConfigure) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "验证中..." : "开始使用")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(apiKey.isEmpty || isLoading)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("需要API密钥？")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("访问 Dify 控制台", destination: URL(string: "https://cloud.dify.ai")!)
                        .font(.caption)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            apiKey = appState.apiKey
            baseURL = appState.baseURL
        }
    }
    
    private func validateAndConfigure() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // 验证API密钥
                let client = DifyClient(apiKey: apiKey, baseURL: baseURL)
                let _ = try await client.getApplicationParameters(user: appState.userId)
                
                await MainActor.run {
                    appState.configure(apiKey: apiKey, baseURL: baseURL)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "API密钥验证失败: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("聊天")
                }
            
            CompletionView()
                .tabItem {
                    Image(systemName: "text.bubble")
                    Text("文本生成")
                }
            
            WorkflowView()
                .tabItem {
                    Image(systemName: "flowchart")
                    Text("工作流")
                }
            
            FileUploadView()
                .tabItem {
                    Image(systemName: "doc.badge.plus")
                    Text("文件")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
        }
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
}
