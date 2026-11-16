import SwiftUI
import EditorCore

#if canImport(Photos)
import Photos
#endif

public struct ExportSheetView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: ExportFormat = .png
    @State private var jpegQuality: Double = 0.9
    @State private var isExporting: Bool = false
    @State private var exportMessage: String?
    @State private var exportedData: Data?
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Format & Quality") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedFormat == .jpeg {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Quality")
                                Spacer()
                                Text("\(Int(jpegQuality * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $jpegQuality, in: 0.1...1.0, step: 0.05)
                        }
                    }
                }
                
                Section("Document Specs") {
                    LabeledContent("Dimensions", value: "\(viewModel.document.configuration.width) × \(viewModel.document.configuration.height) px")
                    LabeledContent("DPI", value: "\(Int(viewModel.document.configuration.dpi))")
                    LabeledContent("Color Space", value: viewModel.document.configuration.colorSpace.rawValue)
                    LabeledContent("Active Layers", value: "\(viewModel.document.layers.count)")
                }
                
                if let message = exportMessage {
                    Section {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(message.contains("Error") ? .red : .green)
                    }
                }
                
                Section {
                    Button {
                        performSaveToPhotos()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Image(systemName: "square.and.arrow.down")
                            Text("Save to Photos")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSaveToPhotos() {
        isExporting = true
        exportMessage = nil
        
        Task {
            do {
                let data = try viewModel.export(format: selectedFormat, jpegQuality: jpegQuality)
                #if canImport(UIKit) && canImport(Photos)
                if let image = UIImage(data: data) {
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                    await MainActor.run {
                        self.isExporting = false
                        self.exportMessage = "Saved successfully to Photos!"
                    }
                    return
                }
                #endif
                await MainActor.run {
                    self.isExporting = false
                    self.exportMessage = "Export generated (\(data.count) bytes)"
                }
            } catch {
                await MainActor.run {
                    self.isExporting = false
                    self.exportMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
