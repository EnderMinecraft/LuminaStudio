import Foundation
import SwiftUI
import CoreGraphics
import Observation
import EditorCore

#if canImport(UIKit)
import UIKit
#endif

@Observable
public final class PhotoEditorViewModel: @unchecked Sendable {
    public var document: LuminaDocument
    public let commandManager: CommandManager
    public var viewport: ViewportState
    public let compositor: TiledCanvasCompositor
    
    // UI state
    public var isLayerPanelPresented: Bool = false
    public var isHistoryPanelPresented: Bool = false
    public var isNewCanvasSheetPresented: Bool = false
    public var isExportSheetPresented: Bool = false
    public var isPhotoPickerPresented: Bool = false
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
    }
    
    public var activeLayer: Layer? {
        document.activeLayer
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
        self.commandManager.clear()
        self.statusMessage = "Created new canvas (\(width)x\(height))"
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
        
        // Extract raw RGBA bytes
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
        self.commandManager.clear()
        self.statusMessage = "Imported image (\(w)x\(h))"
    }
    #endif
    
    // MARK: - Export
    
    public func export(format: ExportFormat, jpegQuality: Double) throws -> Data {
        let engine = ExportEngine(compositor: compositor)
        let config = ExportConfiguration(format: format, jpegQuality: jpegQuality)
        return try engine.export(document: document, configuration: config)
    }
}
