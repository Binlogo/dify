//
//  FileUploadView.swift
//  DifyClientExample
//
//  Created by Binlogo on 2025/7/2.
//

import SwiftUI
import DifyClient
import UniformTypeIdentifiers

struct FileUploadView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var fileManager = FileUploadManager()
    @State private var showingFilePicker = false
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingSampleFiles = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Upload Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择上传方式")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            UploadOptionCard(
                                icon: "photo",
                                title: "照片/图片",
                                description: "支持图片文件",
                                color: .blue
                            ) {
                                showingImagePicker = true
                            }
                            
                            UploadOptionCard(
                                icon: "doc.text",
                                title: "文档文件",
                                description: "支持文本文档",
                                color: .green
                            ) {
                                showingDocumentPicker = true
                            }
                            
                            UploadOptionCard(
                                icon: "waveform",
                                title: "音频文件",
                                description: "支持音频格式",
                                color: .orange
                            ) {
                                // TODO: 实现音频选择
                            }
                            
                            UploadOptionCard(
                                icon: "text.bubble",
                                title: "示例文件",
                                description: "创建示例内容",
                                color: .purple
                            ) {
                                showingSampleFiles = true
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Upload Progress
                    if fileManager.isUploading {
                        VStack(spacing: 12) {
                            Text("上传中...")
                                .font(.headline)
                            
                            ProgressView(value: fileManager.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(height: 8)
                                .scaleEffect(1.2)
                            
                            Text("\(Int(fileManager.uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Uploaded Files
                    if !fileManager.uploadedFiles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("已上传文件 (\(fileManager.uploadedFiles.count))")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("清空全部") {
                                    fileManager.clearAllFiles()
                                }
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(fileManager.uploadedFiles) { file in
                                    UploadedFileView(file: file) {
                                        fileManager.removeFile(file)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Features Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("功能说明")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            FeatureRow(
                                icon: "checkmark.circle",
                                title: "多格式支持",
                                description: "支持图片、文档、音频等多种文件格式"
                            )
                            
                            FeatureRow(
                                icon: "icloud.and.arrow.up",
                                title: "云端存储",
                                description: "文件安全上传到Dify云端服务器"
                            )
                            
                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "AI处理",
                                description: "上传的文件可用于AI模型分析和处理"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("文件上传")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    fileManager.uploadFile(
                        data: imageData,
                        fileName: "image_\(Date().timeIntervalSince1970).jpg",
                        mimeType: "image/jpeg"
                    )
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                fileManager.uploadFileFromURL(url)
            }
        }
        .sheet(isPresented: $showingSampleFiles) {
            SampleFilesSheet { sampleFile in
                fileManager.uploadSampleFile(sampleFile)
            }
        }
        .onAppear {
            fileManager.configure(apiKey: appState.apiKey, baseURL: appState.baseURL, userId: appState.userId)
        }
    }
}

// MARK: - Upload Option Card

struct UploadOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Uploaded File View

struct UploadedFileView: View {
    let file: UploadedFileInfo
    let onDelete: () -> Void
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            Image(systemName: file.iconName)
                .font(.title2)
                .foregroundColor(file.iconColor)
                .frame(width: 40, height: 40)
                .background(file.iconColor.opacity(0.1))
                .cornerRadius(8)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.fileName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(file.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(file.uploadTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    showingDetails = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingDetails) {
            FileDetailsView(file: file)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - File Upload Manager

class FileUploadManager: ObservableObject {
    @Published var uploadedFiles: [UploadedFileInfo] = []
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    
    private var apiKey = ""
    private var baseURL = ""
    private var userId = ""
    private var difyClient: DifyClient?
    
    func configure(apiKey: String, baseURL: String, userId: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.userId = userId
        self.difyClient = DifyClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    func uploadFile(data: Data, fileName: String, mimeType: String) {
        guard let difyClient = difyClient else { return }
        
        isUploading = true
        uploadProgress = 0
        
        // 模拟上传进度
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                self.uploadProgress += 0.1
                if self.uploadProgress >= 1.0 {
                    timer.invalidate()
                }
            }
        }
        
        Task {
            do {
                let response = try await difyClient.uploadFile(
                    fileData: data,
                    fileName: fileName,
                    mimeType: mimeType,
                    user: userId
                )
                
                await MainActor.run {
                    let fileInfo = UploadedFileInfo(
                        id: response.id,
                        fileName: fileName,
                        size: data.count,
                        mimeType: mimeType,
                        uploadResponse: response
                    )
                    uploadedFiles.insert(fileInfo, at: 0)
                    isUploading = false
                    uploadProgress = 0
                }
            } catch {
                await MainActor.run {
                    // 错误处理
                    isUploading = false
                    uploadProgress = 0
                    // TODO: 显示错误信息
                }
            }
        }
    }
    
    func uploadFileFromURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let mimeType = mimeTypeForFile(fileName)
            
            uploadFile(data: data, fileName: fileName, mimeType: mimeType)
        } catch {
            // 错误处理
        }
    }
    
    func uploadSampleFile(_ sampleFile: SampleFile) {
        guard let data = sampleFile.content.data(using: .utf8) else { return }
        uploadFile(data: data, fileName: sampleFile.fileName, mimeType: sampleFile.mimeType)
    }
    
    func removeFile(_ file: UploadedFileInfo) {
        uploadedFiles.removeAll { $0.id == file.id }
    }
    
    func clearAllFiles() {
        uploadedFiles.removeAll()
    }
    
    private func mimeTypeForFile(_ fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "txt": return "text/plain"
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Models

struct UploadedFileInfo: Identifiable {
    let id: String
    let fileName: String
    let size: Int
    let mimeType: String
    let uploadTime = Date()
    let uploadResponse: FileUploadResponse
    
    var iconName: String {
        if mimeType.hasPrefix("image/") {
            return "photo"
        } else if mimeType.hasPrefix("audio/") {
            return "waveform"
        } else if mimeType.hasPrefix("text/") {
            return "doc.text"
        } else {
            return "doc"
        }
    }
    
    var iconColor: Color {
        if mimeType.hasPrefix("image/") {
            return .blue
        } else if mimeType.hasPrefix("audio/") {
            return .orange
        } else if mimeType.hasPrefix("text/") {
            return .green
        } else {
            return .gray
        }
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

struct SampleFile {
    let fileName: String
    let content: String
    let mimeType: String
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentSelected: (URL) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .text, .pdf, .rtf, .plainText
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onDocumentSelected(url)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Sample Files Sheet

struct SampleFilesSheet: View {
    let onSampleSelected: (SampleFile) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    private let sampleFiles = [
        SampleFile(
            fileName: "sample_text.txt",
            content: "这是一个示例文本文件。\n\n它包含了一些示例内容，用于演示文件上传功能。\n\n您可以使用这个文件来测试Dify的文件处理能力。",
            mimeType: "text/plain"
        ),
        SampleFile(
            fileName: "meeting_notes.txt",
            content: "会议纪要\n\n日期：\(DateFormatter().string(from: Date()))\n参与者：张三、李四、王五\n\n讨论内容：\n1. 项目进展汇报\n2. 下一阶段计划\n3. 资源分配\n\n行动项：\n- 完成技术方案设计\n- 准备用户测试\n- 更新项目文档",
            mimeType: "text/plain"
        ),
        SampleFile(
            fileName: "product_description.txt",
            content: "产品介绍\n\nDify Swift Client是一个专业的iOS/macOS开发工具包，提供了完整的Dify API集成方案。\n\n主要特性：\n• 简单易用的API接口\n• 支持聊天、文本生成、工作流等功能\n• 完善的错误处理机制\n• 多平台支持\n\n适用场景：\n- AI应用开发\n- 智能客服系统\n- 内容生成工具\n- 工作流自动化",
            mimeType: "text/plain"
        )
    ]
    
    var body: some View {
        NavigationView {
            List(sampleFiles, id: \.fileName) { file in
                Button {
                    onSampleSelected(file)
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.fileName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(file.content.prefix(100) + "...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("示例文件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - File Details View

struct FileDetailsView: View {
    let file: UploadedFileInfo
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // File icon and name
                VStack(spacing: 12) {
                    Image(systemName: file.iconName)
                        .font(.system(size: 60))
                        .foregroundColor(file.iconColor)
                    
                    Text(file.fileName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                // File details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(title: "文件ID", value: file.id)
                    DetailRow(title: "文件大小", value: file.formattedSize)
                    DetailRow(title: "文件类型", value: file.mimeType)
                    DetailRow(title: "上传时间", value: DateFormatter.localizedString(from: file.uploadTime, dateStyle: .medium, timeStyle: .short))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("文件详情")
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

struct DetailRow: View {
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

#Preview {
    FileUploadView()
        .environmentObject(AppState())
} 