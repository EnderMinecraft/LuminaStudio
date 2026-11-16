import Foundation
import SwiftUI
import CoreGraphics
import Observation
import EditorCore

#if canImport(UIKit)
import UIKit
#endif

public enum ActiveTool: String, CaseIterable, Identifiable, Sendable {
    case move = "Move & Transform"
    case crop = "Crop"
    case brush = "Brush"
    case eraser = "Eraser"
    case smudge = "Smudge"
    case cloneStamp = "Clone Stamp"
    case eyedropper = "Eyedropper"
    case floodFill = "Fill Bucket"
    case gradient = "Gradient"
    case selection = "Selection"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .move: return "arrow.up.and.down.and.arrow.left.and.right"
        case .crop: return "crop"
        case .brush: return "paintbrush.pointed.fill"
        case .eraser: return "eraser.fill"
        case .smudge: return "hand.draw.fill"
        case .cloneStamp: return "stamp.fill"
        case .eyedropper: return "eyedropper"
        case .floodFill: return "drop.fill"
        case .gradient: return "circle.lefthalf.striped.horizontal"
        case .selection: return "lasso"
        }
    }
}

@Observable
public final class PhotoEditorViewModel: @unchecked Sendable {
    public var document: LuminaDocument
    public let commandManager: CommandManager
    public var viewport: ViewportState
    public let compositor: TiledCanvasCompositor
    
    // Active tool state
    public var activeTool: ActiveTool = .brush
    public var activeBrushPreset: BrushPreset = .roundSoft
    public var brushColor: ColorRGBA = ColorRGBA(r: 59, g: 130, b: 246, a: 255)
    
    // Clone Stamp state
    public var cloneSourcePoint: CGPoint?
    
    // Selection state
    public var activeSelectionMask: SelectionMask
    public var selectionMode: SelectionMode = .replace
    public var selectionToolType: SelectionToolType = .rectangle
    public var selectionFeatherRadius: Int = 4
    public var marchingAntsPhase: CGFloat = 0.0
    public var marchingAntsSegments: [LineSegment] = []
    
    // Color tools state
    public var floodFillTolerance: Double = 0.15
    public var floodFillContiguous: Bool = true
    public var activeEyedropperColor: ColorRGBA?
    public var gradientType: GradientType = .linear
    
    // Crop & Transform state
    public var cropConfig: CropConfiguration
    public var isCropActive: Bool = false
    public var transformState: TransformState = .identity
    public var activeSnappingGuides: [SnappingGuide] = []
    
    // Phase 3 & 4: Adjustments, Filters, Histogram & Cutout Refine
    public var isAdjustmentsSheetPresented: Bool = false
    public var isFiltersSheetPresented: Bool = false
    public var isHistogramPresented: Bool = false
    public var isBeforeAfterBypassed: Bool = false
    public var isCutoutRefineStudioPresented: Bool = false
    public var isPerformingAutoCutout: Bool = false
    public var histogramData: HistogramData = HistogramData()
    
    // UI state
    public var isLayerPanelPresented: Bool = false
    public var isHistoryPanelPresented: Bool = false
    public var isNewCanvasSheetPresented: Bool = false
    public var isExportSheetPresented: Bool = false
    public var isPhotoPickerPresented: Bool = false
    public var isBrushSettingsPresented: Bool = false
    public var isTextLayerSheetPresented: Bool = false
    public var isShapeLayerSheetPresented: Bool = false
    public var showRulersAndGrid: Bool = false
    public var statusMessage: String = "Ready"
    
    public init(document: LuminaDocument, commandManager: CommandManager) {
        self.document = document
        self.commandManager = commandManager
        self.viewport = ViewportState(
            zoom: 1.0,
            panOffset: .zero,
            rotationRadians: 0.0,
            viewportSize: CGSize(width: 800, height: 800)
        )
        self.compositor = TiledCanvasCompositor()
        self.activeSelectionMask = SelectionMask(
            width: document.configuration.width,
            height: document.configuration.height
        )
        self.cropConfig = CropConfiguration(
            cropRect: CGRect(x: 0, y: 0, width: document.configuration.width, height: document.configuration.height)
        )
        self.refreshHistogram()
    }
    
    public var activeLayer: Layer? {
        document.activeLayer
    }
    
    public func refreshHistogram() {
        let buffer = compositor.compositeToBuffer(document: document)
        let count = document.configuration.width * document.configuration.height
        histogramData = HistogramEngine.shared.computeHistogram(from: [UInt8](buffer), count: count)
    }
    
    // MARK: - Layer Actions
    
    public func addBlankLayer() {
        let count = document.layers.count
        let newLayer = Layer(
            name: "Layer \(count)",
            opacity: 1.0,
            blendMode: .normal,
            isVisible: true,
            isLocked: false,
            pixelWidth: document.configuration.width,
            pixelHeight: document.configuration.height
        )
        let cmd = AddLayerCommand(document: document, layer: newLayer)
        executeCommand(cmd)
    }
    
    public func deleteActiveLayer() {
        guard let active = activeLayer else { return }
        guard document.layers.count > 1 else {
            statusMessage = "Cannot delete the last remaining layer."
            return
        }
        do {
            let cmd = try RemoveLayerCommand(document: document, layerID: active.id)
            executeCommand(cmd)
        } catch {
            statusMessage = "Failed to remove layer: \(error.localizedDescription)"
        }
    }
    
    public func duplicateActiveLayer() {
        guard let active = activeLayer else { return }
        let cmd = DuplicateLayerCommand(document: document, sourceLayerID: active.id)
        executeCommand(cmd)
    }
    
    public func moveLayer(from source: Int, to destination: Int) {
        let cmd = ReorderLayerCommand(document: document, fromIndex: source, toIndex: destination)
        executeCommand(cmd)
    }
    
    public func setActiveLayer(id: UUID) {
        document.activeLayerID = id
    }
    
    public func setOpacity(_ opacity: Float) {
        guard let active = activeLayer else { return }
        let cmd = SetOpacityCommand(layer: active, newOpacity: opacity)
        executeCommand(cmd)
    }
    
    public func toggleVisibility(for layerID: UUID) {
        guard let layer = document.findLayer(byID: layerID) else { return }
        let cmd = SetVisibilityCommand(layer: layer, isVisible: !layer.isVisible)
        executeCommand(cmd)
    }
    
    public func toggleLock(for layerID: UUID) {
        guard let layer = document.findLayer(byID: layerID) else { return }
        let cmd = ToggleLockCommand(layer: layer)
        executeCommand(cmd)
    }
    
    public func setBlendMode(_ mode: LuminaBlendMode) {
        guard let active = activeLayer else { return }
        let cmd = SetBlendModeCommand(layer: active, newMode: mode)
        executeCommand(cmd)
    }
    
    public func renameActiveLayer(to newName: String) {
        guard let active = activeLayer, !newName.isEmpty else { return }
        let cmd = RenameLayerCommand(layer: active, newName: newName)
        executeCommand(cmd)
    }
    
    // MARK: - Layer Mask Operations
    
    public func createMaskFromSelection() {
        guard let active = activeLayer else { return }
        let w = document.configuration.width
        let h = document.configuration.height
        let mask = LayerMask(width: w, height: h)
        if activeSelectionMask.hasSelection {
            mask.maskData = Data(activeSelectionMask.data)
        }
        let cmd = CreateLayerMaskCommand(layer: active, mask: mask)
        executeCommand(cmd)
    }
    
    public func invertActiveMask() {
        guard let active = activeLayer, active.mask != nil else { return }
        let cmd = InvertLayerMaskCommand(layer: active)
        executeCommand(cmd)
    }
    
    public func applyActiveMask() {
        guard let active = activeLayer, active.mask != nil else { return }
        let cmd = ApplyLayerMaskCommand(layer: active)
        executeCommand(cmd)
    }
    
    public func toggleActiveMask() {
        guard let active = activeLayer, active.mask != nil else { return }
        let cmd = ToggleLayerMaskCommand(layer: active)
        executeCommand(cmd)
    }
    
    // MARK: - Selection Operations
    
    public func invertSelection() {
        activeSelectionMask.invert()
        updateMarchingAnts()
        statusMessage = "Invert Selection"
    }
    
    public func selectAll() {
        activeSelectionMask.selectAll()
        updateMarchingAnts()
        statusMessage = "Select All"
    }
    
    public func deselect() {
        activeSelectionMask.deselect()
        marchingAntsSegments.removeAll()
        statusMessage = "Deselect"
    }
    
    public func featherSelection(radius: Int) {
        activeSelectionMask.feather(radius: radius)
        updateMarchingAnts()
        statusMessage = "Feather (\(radius)px)"
    }
    
    public func expandSelection(pixels: Int) {
        activeSelectionMask.expand(pixels: pixels)
        updateMarchingAnts()
        statusMessage = "Expand (\(pixels)px)"
    }
    
    public func contractSelection(pixels: Int) {
        activeSelectionMask.contract(pixels: pixels)
        updateMarchingAnts()
        statusMessage = "Contract (\(pixels)px)"
    }
    
    public func updateMarchingAnts() {
        if activeSelectionMask.hasSelection {
            marchingAntsSegments = MarchingAntsGenerator.shared.generateBorderSegments(
                mask: activeSelectionMask,
                sampleStep: max(1, Int(ceil(2.0 / viewport.zoom)))
            )
        } else {
            marchingAntsSegments.removeAll()
        }
    }
    
    // MARK: - Color Tools Execution
    
    public func sampleEyedropper(at point: CGPoint) {
        let buffer = compositor.compositeToBuffer(document: document)
        if let sampled = EyedropperEngine.shared.sampleColor(
            at: point,
            in: buffer,
            width: document.configuration.width,
            height: document.configuration.height,
            aperture: 3
        ) {
            brushColor = sampled
            activeEyedropperColor = sampled
            statusMessage = "Sampled \(sampled.hexString)"
        }
    }
    
    public func executeFloodFill(at point: CGPoint) {
        guard let active = activeLayer, let data = active.rawPixelData,
              active.pixelWidth > 0, active.pixelHeight > 0 else { return }
        
        let oldData = data
        var buffer = [UInt8](data)
        FloodFillEngine.shared.fill(
            startPoint: point,
            fillColor: brushColor,
            tolerance: floodFillTolerance,
            isContiguous: floodFillContiguous,
            buffer: &buffer,
            width: active.pixelWidth,
            height: active.pixelHeight
        )
        let newData = Data(buffer)
        let cmd = PaintStrokeCommand(layer: active, previousData: oldData, newData: newData)
        executeCommand(cmd)
        refreshHistogram()
    }
    
    public func executeGradient(from start: CGPoint, to end: CGPoint) {
        guard let active = activeLayer, let data = active.rawPixelData,
              active.pixelWidth > 0, active.pixelHeight > 0 else { return }
        
        let oldData = data
        var buffer = [UInt8](data)
        let stops = [
            GradientStop(location: 0.0, color: brushColor),
            GradientStop(location: 1.0, color: ColorRGBA(r: 255, g: 255, b: 255, a: 0))
        ]
        
        if gradientType == .linear {
            GradientEngine.shared.renderLinearGradient(
                from: start,
                to: end,
                stops: stops,
                width: active.pixelWidth,
                height: active.pixelHeight,
                buffer: &buffer
            )
        } else {
            let dx = end.x - start.x
            let dy = end.y - start.y
            let radius = sqrt(dx * dx + dy * dy)
            GradientEngine.shared.renderRadialGradient(
                center: start,
                radius: radius,
                stops: stops,
                width: active.pixelWidth,
                height: active.pixelHeight,
                buffer: &buffer
            )
        }
        
        let newData = Data(buffer)
        let cmd = PaintStrokeCommand(layer: active, previousData: oldData, newData: newData)
        executeCommand(cmd)
        refreshHistogram()
    }
    
    // MARK: - Crop & Transform Execution
    
    public func executeCrop() {
        let cmd = CropDocumentCommand(document: document, cropRect: cropConfig.cropRect)
        executeCommand(cmd)
        isCropActive = false
        activeSelectionMask = SelectionMask(width: document.configuration.width, height: document.configuration.height)
        cropConfig.cropRect = CGRect(x: 0, y: 0, width: document.configuration.width, height: document.configuration.height)
        zoomToFit(containerSize: viewport.viewportSize)
        refreshHistogram()
    }
    
    public func cancelCrop() {
        isCropActive = false
        cropConfig.cropRect = CGRect(x: 0, y: 0, width: document.configuration.width, height: document.configuration.height)
    }
    
    // MARK: - Cutout & Background Removal
    
    public func startAutoCutout(personOnly: Bool = false) {
        guard let active = activeLayer else { return }
        isPerformingAutoCutout = true
        statusMessage = "Analyzing image subjects..."
        
        Task {
            if let cgImage = compositor.renderCGImage(document: document) {
                do {
                    let (mask, count) = try await CutoutEngine.shared.performAutoCutout(image: cgImage, personOnly: personOnly)
                    await MainActor.run {
                        self.isPerformingAutoCutout = false
                        active.mask = mask
                        self.isCutoutRefineStudioPresented = true
                        self.statusMessage = "Found \(count) subjects. Opening Refine Studio."
                    }
                    return
                } catch {
                    await MainActor.run {
                        self.isPerformingAutoCutout = false
                        self.statusMessage = "Cutout error: \(error.localizedDescription)"
                    }
                }
            }
            await MainActor.run {
                self.isPerformingAutoCutout = false
                self.isCutoutRefineStudioPresented = true
            }
        }
    }
    
    // MARK: - Viewport & Navigation
    
    public func handlePinch(scaleMultiplier: Double, anchor: CGPoint) {
        let newZoom = viewport.zoom * scaleMultiplier
        viewport.zoom = max(ViewportState.minZoom, min(ViewportState.maxZoom, newZoom))
    }
    
    public func handlePan(delta: CGPoint) {
        viewport.panOffset.x += delta.x
        viewport.panOffset.y += delta.y
    }
    
    public func handleRotate(angleDeltaRadians: Double) {
        viewport.rotationRadians += angleDeltaRadians
    }
    
    public func zoomToFit(containerSize: CGSize) {
        let canvasSize = document.configuration.size
        viewport.fit(canvasSize: canvasSize, in: containerSize)
    }
    
    public func zoomTo100(containerSize: CGSize) {
        let canvasSize = document.configuration.size
        viewport.zoomTo100(canvasSize: canvasSize, in: containerSize)
    }
    
    public func resetRotation() {
        viewport.rotationRadians = 0.0
    }
    
    // MARK: - Undo / Redo
    
    public func undo() {
        Task { @MainActor in
            do {
                try await commandManager.undo()
                statusMessage = "Undo"
                refreshHistogram()
            } catch {
                statusMessage = "Cannot undo: \(error.localizedDescription)"
            }
        }
    }
    
    public func redo() {
        Task { @MainActor in
            do {
                try await commandManager.redo()
                statusMessage = "Redo"
                refreshHistogram()
            } catch {
                statusMessage = "Cannot redo: \(error.localizedDescription)"
            }
        }
    }
    
    private func executeCommand(_ cmd: any Command) {
        Task { @MainActor in
            do {
                try await commandManager.execute(cmd)
                statusMessage = cmd.name
                refreshHistogram()
            } catch {
                statusMessage = "Command failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Document Creation & Import
    
    public func newCanvas(width: Int, height: Int, dpi: Double, colorSpace: LuminaColorSpace, background: CanvasBackgroundColor) {
        let config = CanvasConfiguration(
            width: width,
            height: height,
            dpi: dpi,
            colorSpace: colorSpace,
            backgroundColor: background
        )
        self.document = LuminaDocument(title: "New Canvas", configuration: config)
        self.activeSelectionMask = SelectionMask(width: width, height: height)
        self.cropConfig = CropConfiguration(cropRect: CGRect(x: 0, y: 0, width: width, height: height))
        self.commandManager.clear()
        self.statusMessage = "Created new canvas (\(width)x\(height))"
        refreshHistogram()
    }
    
    #if canImport(UIKit)
    public func importImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let w = cgImage.width
        let h = cgImage.height
        
        let config = CanvasConfiguration(
            width: w,
            height: h,
            dpi: 300.0,
            colorSpace: .displayP3,
            backgroundColor: .transparent
        )
        let newDoc = LuminaDocument(title: "Imported Image", configuration: config)
        newDoc.layers.removeAll()
        
        let totalBytes = w * h * 4
        var rawData = Data(count: totalBytes)
        rawData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: w * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        
        let imageLayer = Layer(
            name: "Imported Photo",
            opacity: 1.0,
            blendMode: .normal,
            isVisible: true,
            isLocked: false,
            transform: .identity,
            mask: nil,
            kind: .raster(assetID: nil),
            rawPixelData: rawData,
            pixelWidth: w,
            pixelHeight: h
        )
        newDoc.addLayer(imageLayer)
        self.document = newDoc
        self.activeSelectionMask = SelectionMask(width: w, height: h)
        self.cropConfig = CropConfiguration(cropRect: CGRect(x: 0, y: 0, width: w, height: h))
        self.commandManager.clear()
        self.statusMessage = "Imported image (\(w)x\(h))"
        refreshHistogram()
    }
    #endif
    
    // MARK: - Export
    
    public func export(format: ExportFormat, jpegQuality: Double) throws -> Data {
        let engine = ExportEngine(compositor: compositor)
        let config = ExportConfiguration(format: format, jpegQuality: jpegQuality)
        return try engine.export(document: document, configuration: config)
    }
}
