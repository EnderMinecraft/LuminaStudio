import SwiftUI
import EditorCore

public struct NewTextLayerSheetView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = "Lumina Studio"
    @State private var fontSize: CGFloat = 54.0
    @State private var tracking: CGFloat = 0.0
    @State private var fontName: String = "HelveticaNeue-Bold"
    @State private var selectedColor: Color = .white
    @State private var alignment: Int = 1
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Text Content") {
                    TextField("Enter text", text: $text)
                        .font(.body)
                }
                
                Section("Typography") {
                    Picker("Font", selection: $fontName) {
                        Text("Helvetica Neue Bold").tag("HelveticaNeue-Bold")
                        Text("Helvetica Neue Light").tag("HelveticaNeue-Light")
                        Text("Avenir Next Heavy").tag("AvenirNext-Heavy")
                        Text("Georgia").tag("Georgia")
                        Text("Courier New Bold").tag("CourierNewPS-BoldMT")
                    }
                    
                    HStack {
                        Text("Size")
                        Spacer()
                        Slider(value: $fontSize, in: 16...180, step: 2)
                            .frame(width: 140)
                        Text("\(Int(fontSize)) pt")
                            .font(.caption.monospacedDigit())
                            .frame(width: 44, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Tracking")
                        Spacer()
                        Slider(value: $tracking, in: -2...15, step: 0.5)
                            .frame(width: 140)
                        Text(String(format: "%.1f", tracking))
                            .font(.caption.monospacedDigit())
                            .frame(width: 44, alignment: .trailing)
                    }
                    
                    Picker("Alignment", selection: $alignment) {
                        Image(systemName: "text.alignleft").tag(0)
                        Image(systemName: "text.aligncenter").tag(1)
                        Image(systemName: "text.alignright").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Appearance") {
                    ColorPicker("Text Color", selection: $selectedColor)
                }
                
                Section {
                    Button("Add Text Layer") {
                        createTextLayer()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
            }
            .navigationTitle("New Text Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createTextLayer() {
        let style = TextStyleData(
            fontName: fontName,
            fontSize: fontSize,
            tracking: tracking,
            colorHex: "#FFFFFF",
            alignment: alignment
        )
        let canvasSize = viewModel.document.configuration.size
        let (buffer, size) = TextEngine.shared.renderText(text: text, style: style, bounds: canvasSize)
        
        let layerData = TextLayerData(
            text: text,
            fontName: fontName,
            fontSize: fontSize,
            tracking: tracking,
            textColorHex: "#FFFFFF",
            alignment: alignment
        )
        
        let layer = Layer(
            name: "Text: \(text.prefix(12))",
            opacity: 1.0,
            blendMode: .normal,
            isVisible: true,
            isLocked: false,
            transform: .identity,
            mask: nil,
            kind: .text(layerData),
            rawPixelData: Data(buffer),
            pixelWidth: Int(size.width),
            pixelHeight: Int(size.height)
        )
        let cmd = AddLayerCommand(document: viewModel.document, layer: layer)
        Task { @MainActor in
            try? await viewModel.commandManager.execute(cmd)
        }
    }
}

public struct NewShapeLayerSheetView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var shapeType: ShapeLayerData.ShapeType = .roundedRectangle
    @State private var cornerRadius: CGFloat = 24.0
    @State private var polygonSides: Int = 5
    @State private var strokeWidth: CGFloat = 4.0
    @State private var fillColor: Color = .blue
    @State private var strokeColor: Color = .white
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Shape Type") {
                    Picker("Type", selection: $shapeType) {
                        Text("Rectangle").tag(ShapeLayerData.ShapeType.rectangle)
                        Text("Rounded Rect").tag(ShapeLayerData.ShapeType.roundedRectangle)
                        Text("Ellipse").tag(ShapeLayerData.ShapeType.ellipse)
                        Text("Polygon").tag(ShapeLayerData.ShapeType.polygon)
                        Text("Star").tag(ShapeLayerData.ShapeType.star)
                        Text("Line").tag(ShapeLayerData.ShapeType.line)
                    }
                }
                
                Section("Geometry") {
                    if shapeType == .roundedRectangle {
                        HStack {
                            Text("Corner Radius")
                            Spacer()
                            Slider(value: $cornerRadius, in: 0...100, step: 2)
                                .frame(width: 140)
                            Text("\(Int(cornerRadius)) px")
                                .font(.caption.monospacedDigit())
                        }
                    } else if shapeType == .polygon {
                        Stepper("Sides: \(polygonSides)", value: $polygonSides, in: 3...12)
                    }
                    
                    HStack {
                        Text("Stroke Width")
                        Spacer()
                        Slider(value: $strokeWidth, in: 0...32, step: 1)
                            .frame(width: 140)
                        Text("\(Int(strokeWidth)) px")
                            .font(.caption.monospacedDigit())
                    }
                }
                
                Section("Style") {
                    ColorPicker("Fill Color", selection: $fillColor)
                    ColorPicker("Stroke Color", selection: $strokeColor)
                }
                
                Section {
                    Button("Create Shape Layer") {
                        createShapeLayer()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
            }
            .navigationTitle("New Shape Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createShapeLayer() {
        let shapeData = ShapeLayerData(
            type: shapeType,
            fillColorHex: "#3B82F6",
            strokeColorHex: "#FFFFFF",
            strokeWidth: strokeWidth,
            cornerRadius: cornerRadius,
            polygonSides: polygonSides
        )
        let canvasSize = viewModel.document.configuration.size
        let buffer = ShapeEngine.shared.renderShape(data: shapeData, bounds: canvasSize)
        
        let layer = Layer(
            name: "Shape: \(shapeType.rawValue.capitalized)",
            opacity: 1.0,
            blendMode: .normal,
            isVisible: true,
            isLocked: false,
            transform: .identity,
            mask: nil,
            kind: .shape(shapeData),
            rawPixelData: Data(buffer),
            pixelWidth: Int(canvasSize.width),
            pixelHeight: Int(canvasSize.height)
        )
        let cmd = AddLayerCommand(document: viewModel.document, layer: layer)
        Task { @MainActor in
            try? await viewModel.commandManager.execute(cmd)
        }
    }
}
