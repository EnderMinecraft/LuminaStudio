import SwiftUI
import EditorCore

public struct FiltersSheetView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: FilterType = .gaussianBlur
    @State private var blurRadius: Double = 10.0
    @State private var pixelateBlockSize: Int = 16
    @State private var noiseAmount: Double = 0.2
    @State private var unsharpIntensity: Double = 1.0
    @State private var chromaticOffset: Int = 8
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Filter Category") {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                }
                
                Section("Parameters") {
                    switch selectedFilter {
                    case .gaussianBlur, .motionBlur, .radialBlur:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Blur Radius")
                                Spacer()
                                Text("\(Int(blurRadius)) px")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $blurRadius, in: 1...80, step: 1)
                        }
                    case .pixelate:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Block Size")
                                Spacer()
                                Text("\(pixelateBlockSize) px")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(pixelateBlockSize) },
                                    set: { pixelateBlockSize = Int($0) }
                                ),
                                in: 2...64,
                                step: 2
                            )
                        }
                    case .noise:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Noise Amount")
                                Spacer()
                                Text("\(Int(noiseAmount * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $noiseAmount, in: 0.05...1.0, step: 0.05)
                        }
                    case .unsharpMask:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Sharpen Intensity")
                                Spacer()
                                Text(String(format: "%.1fx", unsharpIntensity))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $unsharpIntensity, in: 0.2...3.0, step: 0.1)
                        }
                    case .chromaticAberration:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Color Offset")
                                Spacer()
                                Text("\(chromaticOffset) px")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(chromaticOffset) },
                                    set: { chromaticOffset = Int($0) }
                                ),
                                in: 1...40,
                                step: 1
                            )
                        }
                    case .liquify:
                        Text("Liquify mode active. Drag on canvas to push and warp pixels.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button("Apply Filter to Layer") {
                        applyFilter()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func applyFilter() {
        guard let active = viewModel.activeLayer, let pixels = active.rawPixelData,
              active.pixelWidth > 0, active.pixelHeight > 0 else { return }
        
        let oldData = pixels
        var buffer = [UInt8](pixels)
        let w = active.pixelWidth
        let h = active.pixelHeight
        
        switch selectedFilter {
        case .gaussianBlur, .motionBlur, .radialBlur:
            FilterEngine.shared.applyGaussianBlur(radius: blurRadius, buffer: &buffer, width: w, height: h)
        case .pixelate:
            FilterEngine.shared.applyPixelate(blockSize: pixelateBlockSize, buffer: &buffer, width: w, height: h)
        case .noise:
            FilterEngine.shared.applyNoise(amount: noiseAmount, buffer: &buffer, width: w, height: h)
        case .unsharpMask:
            FilterEngine.shared.applyUnsharpMask(radius: 4.0, intensity: unsharpIntensity, buffer: &buffer, width: w, height: h)
        case .chromaticAberration:
            FilterEngine.shared.applyChromaticAberration(offsetPixels: chromaticOffset, buffer: &buffer, width: w, height: h)
        case .liquify:
            FilterEngine.shared.applyLiquifyPush(
                center: CGPoint(x: w / 2, y: h / 2),
                direction: CGPoint(x: 20, y: 10),
                radius: CGFloat(w / 4),
                strength: 0.6,
                buffer: &buffer,
                width: w,
                height: h
            )
        }
        
        let newData = Data(buffer)
        let cmd = PaintStrokeCommand(layer: active, previousData: oldData, newData: newData)
        Task { @MainActor in
            try? await viewModel.commandManager.execute(cmd)
        }
    }
}
