import SwiftUI
import EditorCore

public struct BrushSettingsSheetView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Presets") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(BrushPreset.standardPresets) { preset in
                                Button {
                                    viewModel.activeBrushPreset = preset
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(uiColor: .tertiarySystemFill))
                                            .frame(width: 50, height: 50)
                                            .overlay {
                                                Circle()
                                                    .fill(Color.primary.opacity(preset.opacity))
                                                    .frame(width: max(4, min(36, preset.size * 1.2)),
                                                           height: max(4, min(36, preset.size * 1.2)))
                                                    .blur(radius: (1.0 - preset.hardness) * 4.0)
                                            }
                                        Text(preset.name)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(viewModel.activeBrushPreset.id == preset.id ? Color.accentColor : Color.primary)
                                    }
                                    .padding(8)
                                    .background(
                                        viewModel.activeBrushPreset.id == preset.id ?
                                        Color.accentColor.opacity(0.12) : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Stroke Geometry") {
                    HStack {
                        Text("Size")
                        Spacer()
                        Slider(value: $viewModel.activeBrushPreset.size, in: 1...500, step: 1)
                            .frame(width: 140)
                        Text("\(Int(viewModel.activeBrushPreset.size)) px")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Hardness")
                        Spacer()
                        Slider(value: $viewModel.activeBrushPreset.hardness, in: 0...1, step: 0.05)
                            .frame(width: 140)
                        Text("\(Int(viewModel.activeBrushPreset.hardness * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Spacing")
                        Spacer()
                        Slider(value: $viewModel.activeBrushPreset.spacing, in: 0.02...1.0, step: 0.02)
                            .frame(width: 140)
                        Text("\(Int(viewModel.activeBrushPreset.spacing * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                }
                
                Section("Dynamics & Pressure") {
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Slider(value: $viewModel.activeBrushPreset.opacity, in: 0.05...1.0, step: 0.05)
                            .frame(width: 140)
                        Text("\(Int(viewModel.activeBrushPreset.opacity * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Flow")
                        Spacer()
                        Slider(value: $viewModel.activeBrushPreset.flow, in: 0.05...1.0, step: 0.05)
                            .frame(width: 140)
                        Text("\(Int(viewModel.activeBrushPreset.flow * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                    
                    Toggle("Apple Pencil Pressure to Size", isOn: $viewModel.activeBrushPreset.sizeWithPressure)
                    Toggle("Apple Pencil Pressure to Opacity", isOn: $viewModel.activeBrushPreset.opacityWithPressure)
                }
            }
            .navigationTitle("Brush Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
