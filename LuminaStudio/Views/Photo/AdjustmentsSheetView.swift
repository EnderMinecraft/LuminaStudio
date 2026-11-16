import SwiftUI
import EditorCore

public struct AdjustmentsSheetView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Int = 0
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 0.0
    @State private var exposureEV: Double = 0.0
    @State private var levels = LevelsData()
    @State private var curves = CurvesData()
    @State private var hueShift: Double = 0.0
    @State private var saturation: Double = 0.0
    @State private var vibrance: Double = 0.0
    @State private var temperature: Double = 0.0
    @State private var tint: Double = 0.0
    @State private var vignetteIntensity: Double = 0.5
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        performAutoEnhance()
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(Color.accentColor)
                            Text("On-Device Auto Enhance")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Auto")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Adjustment Category") {
                    Picker("Adjustment", selection: $selectedTab) {
                        Text("Light").tag(0)
                        Text("Curves").tag(1)
                        Text("Color").tag(2)
                        Text("Effects").tag(3)
                    }
                    .pickerStyle(.segmented)
                }
                
                switch selectedTab {
                case 0:
                    lightControls
                case 1:
                    curvesControls
                case 2:
                    colorControls
                default:
                    effectsControls
                }
                
                Section {
                    Button("Apply Adjustment to Layer") {
                        applyCurrentAdjustment()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
            }
            .navigationTitle("Adjustments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Light Controls
    
    private var lightControls: some View {
        Group {
            Section("Brightness & Contrast") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Brightness")
                        Spacer()
                        Text("\(Int(brightness * 100))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $brightness, in: -1...1, step: 0.02)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Contrast")
                        Spacer()
                        Text("\(Int(contrast * 100))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $contrast, in: -1...1, step: 0.02)
                }
            }
            
            Section("Exposure") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Exposure EV")
                        Spacer()
                        Text(String(format: "%.1f EV", exposureEV))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $exposureEV, in: -4...4, step: 0.1)
                }
            }
            
            Section("Levels") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Black Point")
                        Spacer()
                        Text("\(Int(levels.blackPoint * 255))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $levels.blackPoint, in: 0...0.8, step: 0.01)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Midtone Gamma")
                        Spacer()
                        Text(String(format: "%.2f", levels.midtoneGamma))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $levels.midtoneGamma, in: 0.2...3.0, step: 0.05)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("White Point")
                        Spacer()
                        Text("\(Int(levels.whitePoint * 255))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $levels.whitePoint, in: 0.2...1.0, step: 0.01)
                }
            }
        }
    }
    
    // MARK: - Curves Controls
    
    private var curvesControls: some View {
        Section("Tone Curves Spline") {
            CurvesSplineEditorView(curvesData: $curves)
        }
    }
    
    // MARK: - Color Controls
    
    private var colorControls: some View {
        Group {
            Section("Hue & Saturation") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Hue Shift")
                        Spacer()
                        Text("\(Int(hueShift))°")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $hueShift, in: -180...180, step: 1)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Saturation")
                        Spacer()
                        Text("\(Int(saturation * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $saturation, in: -1...1, step: 0.02)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Vibrance")
                        Spacer()
                        Text("\(Int(vibrance * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $vibrance, in: -1...1, step: 0.02)
                }
            }
            
            Section("Temperature & Tint") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text("\(Int(temperature * 100))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $temperature, in: -1...1, step: 0.02)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Tint")
                        Spacer()
                        Text("\(Int(tint * 100))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $tint, in: -1...1, step: 0.02)
                }
            }
        }
    }
    
    // MARK: - Effects Controls
    
    private var effectsControls: some View {
        Section("Vignette") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Intensity")
                    Spacer()
                    Text("\(Int(vignetteIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $vignetteIntensity, in: 0...1, step: 0.05)
            }
        }
    }
    
    // MARK: - Auto Enhance Execution
    
    private func performAutoEnhance() {
        guard let active = viewModel.activeLayer, let pixels = active.rawPixelData,
              active.pixelWidth > 0, active.pixelHeight > 0 else { return }
        
        let result = AutoEnhanceEngine.shared.analyzeAndEnhance(
            from: [UInt8](pixels),
            count: active.pixelWidth * active.pixelHeight
        )
        self.levels = result.levels
        self.vibrance = result.vibrance.vibrance
        self.brightness = result.brightnessContrast.brightness
        self.contrast = result.brightnessContrast.contrast
        viewModel.statusMessage = "Auto Enhance Applied"
    }
    
    private func applyCurrentAdjustment() {
        guard let active = viewModel.activeLayer, let pixels = active.rawPixelData,
              active.pixelWidth > 0, active.pixelHeight > 0 else { return }
        
        let oldData = pixels
        var buffer = [UInt8](pixels)
        let w = active.pixelWidth
        let h = active.pixelHeight
        
        switch selectedTab {
        case 0:
            if abs(brightness) > 1e-4 || abs(contrast) > 1e-4 {
                AdjustmentEngine.shared.applyAdjustments(
                    parameters: .brightnessContrast(BrightnessContrastData(brightness: brightness, contrast: contrast)),
                    buffer: &buffer,
                    width: w,
                    height: h
                )
            }
            if abs(exposureEV) > 1e-4 {
                AdjustmentEngine.shared.applyAdjustments(
                    parameters: .exposure(ExposureData(exposureEV: exposureEV)),
                    buffer: &buffer,
                    width: w,
                    height: h
                )
            }
            AdjustmentEngine.shared.applyAdjustments(
                parameters: .levels(levels),
                buffer: &buffer,
                width: w,
                height: h
            )
        case 1:
            AdjustmentEngine.shared.applyAdjustments(
                parameters: .curves(curves),
                buffer: &buffer,
                width: w,
                height: h
            )
        case 2:
            if abs(hueShift) > 1e-4 || abs(saturation) > 1e-4 {
                AdjustmentEngine.shared.applyAdjustments(
                    parameters: .hueSaturation(HueSaturationData(hueShiftDegrees: hueShift, saturation: saturation)),
                    buffer: &buffer,
                    width: w,
                    height: h
                )
            }
            if abs(vibrance) > 1e-4 {
                AdjustmentEngine.shared.applyAdjustments(
                    parameters: .vibrance(VibranceData(vibrance: vibrance)),
                    buffer: &buffer,
                    width: w,
                    height: h
                )
            }
            if abs(temperature) > 1e-4 || abs(tint) > 1e-4 {
                AdjustmentEngine.shared.applyAdjustments(
                    parameters: .temperatureTint(TemperatureTintData(temperature: temperature, tint: tint)),
                    buffer: &buffer,
                    width: w,
                    height: h
                )
            }
        default:
            AdjustmentEngine.shared.applyAdjustments(
                parameters: .vignette(VignetteData(intensity: vignetteIntensity)),
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
