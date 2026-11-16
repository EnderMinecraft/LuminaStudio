import SwiftUI
import EditorCore

public struct ToolOptionsBarView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                switch viewModel.activeTool {
                case .brush, .eraser, .smudge:
                    brushControls
                case .selection:
                    selectionControls
                case .crop:
                    cropControls
                case .floodFill:
                    fillControls
                case .gradient:
                    gradientControls
                case .eyedropper:
                    eyedropperControls
                case .move:
                    moveControls
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Brush Controls
    
    private var brushControls: some View {
        HStack(spacing: 14) {
            Button {
                viewModel.isBrushSettingsPresented = true
            } label: {
                Label(viewModel.activeBrushPreset.name, systemImage: "slider.horizontal.2.square")
                    .font(.caption.weight(.medium))
            }
            
            Divider().frame(height: 18)
            
            HStack(spacing: 6) {
                Text("Size")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(value: $viewModel.activeBrushPreset.size, in: 1...300, step: 1)
                    .frame(width: 90)
                Text("\(Int(viewModel.activeBrushPreset.size))px")
                    .font(.caption2.monospacedDigit())
                    .frame(width: 36, alignment: .trailing)
            }
            
            Divider().frame(height: 18)
            
            HStack(spacing: 6) {
                Text("Hardness")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(value: $viewModel.activeBrushPreset.hardness, in: 0...1, step: 0.05)
                    .frame(width: 80)
                Text("\(Int(viewModel.activeBrushPreset.hardness * 100))%")
                    .font(.caption2.monospacedDigit())
                    .frame(width: 32, alignment: .trailing)
            }
            
            Divider().frame(height: 18)
            
            HStack(spacing: 6) {
                Text("Opacity")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(value: $viewModel.activeBrushPreset.opacity, in: 0.05...1.0, step: 0.05)
                    .frame(width: 80)
                Text("\(Int(viewModel.activeBrushPreset.opacity * 100))%")
                    .font(.caption2.monospacedDigit())
                    .frame(width: 32, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Selection Controls
    
    private var selectionControls: some View {
        HStack(spacing: 12) {
            Picker("Tool", selection: $viewModel.selectionToolType) {
                ForEach(SelectionToolType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            
            Divider().frame(height: 18)
            
            Picker("Mode", selection: $viewModel.selectionMode) {
                ForEach(SelectionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            
            Divider().frame(height: 18)
            
            Button("Invert") {
                viewModel.invertSelection()
            }
            .font(.caption)
            
            Button("Deselect") {
                viewModel.deselect()
            }
            .font(.caption)
            
            Button("Feather") {
                viewModel.featherSelection(radius: viewModel.selectionFeatherRadius)
            }
            .font(.caption)
            
            Button("Mask") {
                viewModel.createMaskFromSelection()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
        }
    }
    
    // MARK: - Crop Controls
    
    private var cropControls: some View {
        HStack(spacing: 14) {
            Picker("Aspect", selection: $viewModel.cropConfig.aspectRatio) {
                ForEach(CropAspectRatio.allCases, id: \.self) { aspect in
                    Text(aspect.rawValue).tag(aspect)
                }
            }
            .pickerStyle(.menu)
            
            Divider().frame(height: 18)
            
            Button("Cancel", role: .cancel) {
                viewModel.cancelCrop()
            }
            .font(.caption)
            
            Button("Apply") {
                viewModel.executeCrop()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.accentColor)
        }
    }
    
    // MARK: - Fill Controls
    
    private var fillControls: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text("Tolerance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(value: $viewModel.floodFillTolerance, in: 0...1, step: 0.05)
                    .frame(width: 80)
                Text("\(Int(viewModel.floodFillTolerance * 100))%")
                    .font(.caption2.monospacedDigit())
                    .frame(width: 32, alignment: .trailing)
            }
            
            Toggle("Contiguous", isOn: $viewModel.floodFillContiguous)
                .font(.caption2)
                .toggleStyle(.button)
        }
    }
    
    // MARK: - Gradient Controls
    
    private var gradientControls: some View {
        HStack(spacing: 12) {
            Picker("Type", selection: $viewModel.gradientType) {
                ForEach(GradientType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
    }
    
    // MARK: - Eyedropper Controls
    
    private var eyedropperControls: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(
                    red: Double(viewModel.brushColor.r) / 255.0,
                    green: Double(viewModel.brushColor.g) / 255.0,
                    blue: Double(viewModel.brushColor.b) / 255.0
                ))
                .frame(width: 22, height: 22)
            
            Text(viewModel.brushColor.hexString)
                .font(.caption.monospaced())
            
            Text("RGB(\(viewModel.brushColor.r), \(viewModel.brushColor.g), \(viewModel.brushColor.b))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Move Controls
    
    private var moveControls: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.activeLayer?.transform.scale.width *= -1.0
            } label: {
                Label("Flip H", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .font(.caption)
            }
            
            Button {
                viewModel.activeLayer?.transform.scale.height *= -1.0
            } label: {
                Label("Flip V", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                    .font(.caption)
            }
        }
    }
}
