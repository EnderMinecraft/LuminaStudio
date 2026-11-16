import SwiftUI
import VectorCore

public struct VectorTraceSheetView: View {
    @Bindable var viewModel: VectorEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var contrast: Float = 1.0
    @State private var cornerTolerance: CGFloat = 1.5
    @State private var isTracing: Bool = false
    @State private var tracedCount: Int = 0
    
    public init(viewModel: VectorEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Tracing Parameters") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Contrast Adjustment")
                            Spacer()
                            Text(String(format: "%.1f", contrast))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $contrast, in: 0.5...3.0, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Corner Tolerance (RDP)")
                            Spacer()
                            Text(String(format: "%.1f px", cornerTolerance))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $cornerTolerance, in: 0.5...5.0, step: 0.5)
                    }
                }
                
                Section("Trace Target") {
                    Text("Auto-detect contours from high-contrast image bitmaps using Vision contour topology and Schneider cubic spline fitting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button {
                        runTrace()
                    } label: {
                        if isTracing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Run Vector Trace")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isTracing)
                }
            }
            .navigationTitle("Image Tracer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func runTrace() {
        isTracing = true
        Task {
            // Generate synthetic high-contrast test raster for tracing demo
            let w = 256
            let h = 256
            var pixels = [UInt8](repeating: 255, count: w * h * 4)
            // Draw a black circle in center
            for y in 0..<h {
                for x in 0..<w {
                    let dx = x - 128
                    let dy = y - 128
                    if dx * dx + dy * dy < 70 * 70 {
                        let idx = (y * w + x) * 4
                        pixels[idx] = 20
                        pixels[idx + 1] = 20
                        pixels[idx + 2] = 20
                        pixels[idx + 3] = 255
                    }
                }
            }
            
            let options = ImageTracer.TracingOptions(
                contrastAdjustment: contrast,
                detectsDarkOnLight: false,
                detailLevel: 0.8,
                cornerTolerance: cornerTolerance
            )
            
            let subpaths = await ImageTracer.shared.traceImage(rgbaPixels: pixels, width: w, height: h, options: options)
            
            await MainActor.run {
                if !subpaths.isEmpty, var artboard = viewModel.document.activeArtboard {
                    let node = PathNode(
                        name: "Traced Path",
                        subpaths: subpaths,
                        fillColorHex: viewModel.fillColorHex,
                        strokeColorHex: viewModel.strokeColorHex,
                        strokeWidth: 2.0
                    )
                    artboard.children.append(.path(node))
                    viewModel.document.artboards[0] = artboard
                    viewModel.statusMessage = "Traced \(subpaths.count) vector subpaths"
                }
                isTracing = false
                dismiss()
            }
        }
    }
}
