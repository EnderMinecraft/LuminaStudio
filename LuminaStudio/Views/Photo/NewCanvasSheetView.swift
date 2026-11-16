import SwiftUI
import EditorCore

public struct NewCanvasSheetView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var width: Int = 2048
    @State private var height: Int = 2048
    @State private var dpi: Double = 300.0
    @State private var colorSpace: LuminaColorSpace = .displayP3
    @State private var selectedBackground: Int = 0 // 0: white, 1: black, 2: transparent
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Canvas Presets") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            presetButton(title: "Square 2K", w: 2048, h: 2048, d: 300)
                            presetButton(title: "4K UHD", w: 3840, h: 2160, d: 300)
                            presetButton(title: "Full HD", w: 1920, h: 1080, d: 72)
                            presetButton(title: "Instagram Post", w: 1080, h: 1350, d: 72)
                            presetButton(title: "Max 8K", w: 8192, h: 8192, d: 300)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Dimensions") {
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("Width", value: $width, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("Height", value: $height, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("DPI", selection: $dpi) {
                        Text("72 DPI (Web)").tag(72.0)
                        Text("150 DPI (Draft)").tag(150.0)
                        Text("300 DPI (Print)").tag(300.0)
                    }
                }
                
                Section("Color & Appearance") {
                    Picker("Color Space", selection: $colorSpace) {
                        ForEach(LuminaColorSpace.allCases, id: \.self) { cs in
                            Text(cs.rawValue).tag(cs)
                        }
                    }
                    
                    Picker("Background", selection: $selectedBackground) {
                        Text("White").tag(0)
                        Text("Black").tag(1)
                        Text("Transparent").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let bg: CanvasBackgroundColor
                        switch selectedBackground {
                        case 0: bg = .white
                        case 1: bg = .black
                        default: bg = .transparent
                        }
                        viewModel.newCanvas(
                            width: width,
                            height: height,
                            dpi: dpi,
                            colorSpace: colorSpace,
                            background: bg
                        )
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func presetButton(title: String, w: Int, h: Int, d: Double) -> some View {
        Button {
            width = w
            height = h
            dpi = d
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(w) × \(h)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
