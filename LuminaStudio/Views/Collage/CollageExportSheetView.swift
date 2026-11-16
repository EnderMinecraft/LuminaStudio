import SwiftUI
import CollageCore

public struct CollageExportSheetView: View {
    @Bindable var viewModel: CollageEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var format: ExportFormat = .png
    @State private var quality: Double = 0.9
    @State private var resolution: CGFloat = 2048
    @State private var statusText: String = ""
    
    public enum ExportFormat: String, CaseIterable, Identifiable {
        case png = "PNG"
        case jpeg = "JPEG"
        case heic = "HEIC"
        public var id: String { rawValue }
    }
    
    public init(viewModel: CollageEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if format == .jpeg {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Quality")
                                Spacer()
                                Text("\(Int(quality * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $quality, in: 0.5...1.0, step: 0.05)
                        }
                    }
                }
                
                Section("Resolution") {
                    Picker("Base Dimension", selection: $resolution) {
                        Text("1500 px (Web/Social)").tag(CGFloat(1500))
                        Text("2048 px (Standard)").tag(CGFloat(2048))
                        Text("4096 px (Print/Ultra)").tag(CGFloat(4096))
                    }
                }
                
                Section {
                    Button {
                        performExport()
                    } label: {
                        Text("Save to Photos")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                
                if !statusText.isEmpty {
                    Section {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Export Collage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func performExport() {
        let (buf, size) = CollageRenderEngine.shared.renderCollage(
            document: viewModel.document,
            baseDimension: resolution
        )
        statusText = "Rendered \(Int(size.width)) × \(Int(size.height)) px image (\(buf.count / 1024) KB). Ready to save or share."
    }
}
