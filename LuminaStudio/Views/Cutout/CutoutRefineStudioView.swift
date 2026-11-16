import SwiftUI
import EditorCore

public struct CutoutRefineStudioView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Cutout state
    @State private var workingMask: LayerMask
    @State private var overlayMode: CutoutOverlayMode = .fadedOriginal(removedOpacity: 0.25)
    @State private var removedOpacity: Double = 0.25
    @State private var isSmartEdgeEnabled: Bool = true
    @State private var isColorDecontaminationEnabled: Bool = true
    @State private var brushSize: CGFloat = 28.0
    @State private var brushHardness: Double = 0.3
    @State private var isRestoreTool: Bool = true // true: Restore, false: Erase
    @State private var isHairRefineActive: Bool = false
    
    // Edge sliders
    @State private var featherRadius: Int = 0
    @State private var shiftEdgeDelta: Int = 0
    @State private var edgeContrast: Double = 0.0
    
    // Zoom and Precision
    @State private var currentTouchPoint: CGPoint?
    @State private var isPressingOriginal: Bool = false
    @State private var showDoneSheet: Bool = false
    @State private var speckCleanNotice: String?
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
        let w = viewModel.document.configuration.width
        let h = viewModel.document.configuration.height
        let initialMask: LayerMask
        if let existing = viewModel.activeLayer?.mask {
            initialMask = LayerMask(width: existing.width, height: existing.height)
            initialMask.maskData = existing.maskData
        } else {
            initialMask = LayerMask(width: w, height: h, initialValue: 255)
        }
        _workingMask = State(initialValue: initialMask)
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Canvas with Overlay Shader Simulation
                canvasView(in: proxy.size)
                    .gesture(canvasDragGesture(in: proxy.size))
                
                // Procedural Pixel Grid at Extreme Zoom (>= 800%)
                if viewModel.viewport.zoom >= ViewportState.pixelGridThresholdZoom {
                    pixelGridOverlay(in: proxy.size)
                }
                
                // Viewport Mini-Map at > 400% Zoom
                if viewModel.viewport.zoom > 4.0 {
                    VStack {
                        Spacer()
                        HStack {
                            CutoutMiniMapView(
                                canvasSize: viewModel.document.configuration.size,
                                viewport: viewModel.viewport
                            )
                            .padding(.leading, 16)
                            .padding(.bottom, 90)
                            Spacer()
                        }
                    }
                }
                
                // Magnifier Loupe during Touch
                if let touch = currentTouchPoint {
                    MagnifierLoupeView(
                        touchPoint: touch,
                        canvasSize: viewModel.document.configuration.size,
                        viewport: viewModel.viewport,
                        rawPixels: viewModel.activeLayer?.rawPixelData,
                        maskData: workingMask.maskData
                    )
                }
                
                // Controls Chrome
                VStack(spacing: 8) {
                    topBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    overlayModeBar
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    bottomToolsBar
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
            }
            .confirmationDialog("Done Refining", isPresented: $showDoneSheet) {
                Button("Keep as Layer Mask (Default)") {
                    commitAsLayerMask()
                    dismiss()
                }
                Button("Apply to Duplicated Layer") {
                    commitToDuplicatedLayer()
                    dismiss()
                }
                Button("Export Transparent PNG") {
                    exportTransparentPNG()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert(speckCleanNotice ?? "Specks Cleaned", isPresented: Binding(
                get: { speckCleanNotice != nil },
                set: { if !$0 { speckCleanNotice = nil } }
            )) {
                Button("OK") {}
            }
        }
    }
    
    // MARK: - Canvas View
    
    private func canvasView(in size: CGSize) -> some View {
        ZStack {
            // Background Checkerboard for Transparency
            checkerboardBackground
            
            // Image Content with Mask Applied
            if let active = viewModel.activeLayer, let imgData = active.rawPixelData {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width * CGFloat(viewModel.viewport.zoom))
                    .position(viewModel.viewport.panOffset)
            }
        }
    }
    
    private var checkerboardBackground: some View {
        Canvas { context, size in
            let step: CGFloat = 16.0
            for y in stride(from: 0, to: size.height, by: step) {
                for x in stride(from: 0, to: size.width, by: step) {
                    let isEven = (Int(x / step) + Int(y / step)) % 2 == 0
                    let rect = CGRect(x: x, y: y, width: step, height: step)
                    context.fill(Path(rect), with: .color(isEven ? Color(white: 0.18) : Color(white: 0.24)))
                }
            }
        }
    }
    
    private func pixelGridOverlay(in size: CGSize) -> some View {
        Canvas { context, size in
            let canvasSize = viewModel.document.configuration.size
            let start = viewModel.viewport.screenPoint(from: .zero, canvasSize: canvasSize)
            let step = CGFloat(viewModel.viewport.zoom)
            guard step >= 8.0 else { return }
            
            var path = Path()
            for x in stride(from: start.x, to: size.width, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: start.y, to: size.height, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Gestures
    
    private func canvasDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                currentTouchPoint = value.location
                let canvasPoint = viewModel.viewport.canvasPoint(
                    from: value.location,
                    canvasSize: viewModel.document.configuration.size
                )
                paintMaskAt(point: canvasPoint)
            }
            .onEnded { _ in
                currentTouchPoint = nil
            }
    }
    
    private func paintMaskAt(point: CGPoint) {
        let val: UInt8 = isRestoreTool ? 255 : 0
        if isSmartEdgeEnabled, let pixels = viewModel.activeLayer?.rawPixelData {
            CutoutEngine.shared.paintSmartEdgeStamp(
                at: point,
                radius: brushSize,
                value: val,
                hardness: brushHardness,
                rgbPixels: [UInt8](pixels),
                mask: workingMask
            )
        } else {
            let preset = BrushPreset(
                size: brushSize,
                hardness: brushHardness,
                opacity: 1.0,
                flow: 1.0
            )
            BrushEngine.shared.paintMaskStamp(
                at: point,
                preset: preset,
                value: val,
                pressure: 1.0,
                maskData: &workingMask.maskData,
                width: workingMask.width,
                height: workingMask.height
            )
        }
    }
    
    // MARK: - Top & Mode Bars
    
    private var topBar: some View {
        HStack {
            Button("Cancel", role: .cancel) { dismiss() }
                .foregroundStyle(.white)
            
            Spacer()
            
            // Zoom indicator & shortcuts
            HStack(spacing: 8) {
                Button("Fit") {
                    viewModel.zoomToFit(containerSize: viewModel.viewport.viewportSize)
                }
                .font(.caption2)
                
                Button("100%") {
                    viewModel.zoomTo100(containerSize: viewModel.viewport.viewportSize)
                }
                .font(.caption2)
                
                Text("\(Int(viewModel.viewport.zoom * 100))%")
                    .font(.caption.monospacedDigit())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Before/After Press & Hold
            Button {} label: {
                Image(systemName: isPressingOriginal ? "eye.slash.fill" : "eye.fill")
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            ._onButtonGesture(pressing: { isPressingOriginal = $0 }, perform: {})
            
            Button("Done") {
                showDoneSheet = true
            }
            .fontWeight(.bold)
            .foregroundStyle(Color.accentColor)
        }
    }
    
    private var overlayModeBar: some View {
        HStack(spacing: 8) {
            ForEach([
                CutoutOverlayMode.fadedOriginal(removedOpacity: removedOpacity),
                CutoutOverlayMode.redTint,
                CutoutOverlayMode.checkerboard,
                CutoutOverlayMode.solidColor(r: 0, g: 1, b: 0),
                CutoutOverlayMode.maskOnly
            ], id: \.id) { mode in
                Button {
                    overlayMode = mode
                } label: {
                    Text(mode.displayName)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(overlayMode.id == mode.id ? Color.accentColor : Color(white: 0.2))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            
            if case .fadedOriginal = overlayMode {
                Slider(value: $removedOpacity, in: 0.0...0.6, step: 0.05)
                    .frame(width: 80)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    // MARK: - Bottom Tools Bar
    
    private var bottomToolsBar: some View {
        VStack(spacing: 10) {
            // Edge Controls Sliders
            HStack(spacing: 16) {
                Button {
                    CutoutEngine.shared.shiftEdge(mask: workingMask, delta: 2)
                } label: {
                    Label("Grow", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                }
                
                Button {
                    CutoutEngine.shared.shiftEdge(mask: workingMask, delta: -2)
                } label: {
                    Label("Shrink", systemImage: "arrow.down.right.and.arrow.up.left")
                        .font(.caption2)
                }
                
                Button {
                    CutoutEngine.shared.feather(mask: workingMask, radius: 4)
                } label: {
                    Label("Feather", systemImage: "cloud.fill")
                        .font(.caption2)
                }
                
                Button {
                    if let pixels = viewModel.activeLayer?.rawPixelData {
                        CutoutEngine.shared.refineHairDetails(mask: workingMask, rgbPixels: [UInt8](pixels))
                    }
                } label: {
                    Label("Hair Refine", systemImage: "wand.and.stars")
                        .font(.caption2)
                }
                
                Button {
                    let cleaned = CutoutEngine.shared.removeSmallSpecks(mask: workingMask, minPixelCount: 80)
                    speckCleanNotice = "Removed \(cleaned) small stray specks."
                } label: {
                    Label("Clean Specks", systemImage: "sparkles")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.white)
            
            // Primary Tool Selector
            HStack(spacing: 20) {
                // Restore vs. Erase toggle
                Picker("Brush Type", selection: $isRestoreTool) {
                    Text("Restore").tag(true)
                    Text("Erase").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                // Smart Edge toggle
                Toggle(isOn: $isSmartEdgeEnabled) {
                    Label("Smart Edge", systemImage: "bolt.horizontal.fill")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .tint(Color.accentColor)
                
                // Brush Size Slider
                HStack(spacing: 4) {
                    Text("Size")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Slider(value: $brushSize, in: 4...150, step: 2)
                        .frame(width: 80)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Commit Actions
    
    private func commitAsLayerMask() {
        guard let active = viewModel.activeLayer else { return }
        let cmd = CreateLayerMaskCommand(layer: active, mask: workingMask)
        Task { @MainActor in
            try? await viewModel.commandManager.execute(cmd)
            viewModel.statusMessage = "Cutout Layer Mask Applied"
        }
    }
    
    private func commitToDuplicatedLayer() {
        guard let active = viewModel.activeLayer else { return }
        let copy = active.duplicate()
        copy.name = "\(active.name) Cutout"
        copy.mask = workingMask
        let cmd = AddLayerCommand(document: viewModel.document, layer: copy)
        Task { @MainActor in
            try? await viewModel.commandManager.execute(cmd)
            viewModel.statusMessage = "Cutout Applied to Duplicated Layer"
        }
    }
    
    private func exportTransparentPNG() {
        commitAsLayerMask()
        viewModel.isExportSheetPresented = true
    }
}
