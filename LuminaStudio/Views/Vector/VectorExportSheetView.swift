import SwiftUI
import VectorCore

public struct VectorExportSheetView: View {
    @Bindable var viewModel: VectorEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportFormat: ExportFormat = .svg
    @State private var rasterScale: CGFloat = 2.0
    @State private var statusText: String = ""
    
    public enum ExportFormat: String, CaseIterable, Identifiable {
        case svg = "SVG (Vector)"
        case pdf = "PDF (Vector)"
        case png = "PNG (Rasterized)"
        public var id: String { rawValue }
    }
    
    public init(viewModel: VectorEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if exportFormat == .png {
                    Section("Raster Resolution") {
                        Picker("Scale", selection: $rasterScale) {
                            Text("1x (Standard)").tag(CGFloat(1.0))
                            Text("2x (Retina)").tag(CGFloat(2.0))
                            Text("3x (Super Retina)").tag(CGFloat(3.0))
                        }
                    }
                }
                
                Section {
                    Button {
                        performExport()
                    } label: {
                        Text("Export Document")
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
            .navigationTitle("Export Vector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func performExport() {
        switch exportFormat {
        case .svg:
            let svg = VectorInterchange.shared.exportSVG(document: viewModel.document)
            statusText = "Generated SVG (\(svg.count) bytes). Ready to share or save."
        case .pdf:
            let pdfData = VectorInterchange.shared.exportPDF(document: viewModel.document)
            statusText = "Generated vector PDF (\(pdfData.count) bytes)."
        case .png:
            if let artboard = viewModel.document.activeArtboard {
                let (buf, size) = VectorRenderEngine.shared.renderArtboard(artboard, scale: rasterScale)
                statusText = "Rasterized to PNG at \(Int(size.width)) × \(Int(size.height)) px."
            }
        }
    }
}
