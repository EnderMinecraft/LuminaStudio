import Foundation
import CoreGraphics

public struct ViewportState: Sendable, Equatable {
    public var zoom: Double
    public var panOffset: CGPoint
    public var rotationRadians: Double
    public var viewportSize: CGSize
    
    public static let minZoom: Double = 0.05
    public static let maxZoom: Double = 32.0 // 3200%
    public static let pixelGridThresholdZoom: Double = 8.0 // 800%
    
    public init(
        zoom: Double = 1.0,
        panOffset: CGPoint = .zero,
        rotationRadians: Double = 0.0,
        viewportSize: CGSize = .zero
    ) {
        self.zoom = max(Self.minZoom, min(Self.maxZoom, zoom))
        self.panOffset = panOffset
        self.rotationRadians = rotationRadians
        self.viewportSize = viewportSize
    }
    
    public var isPixelGridVisible: Bool {
        zoom >= Self.pixelGridThresholdZoom
    }
    
    public mutating func fit(canvasSize: CGSize, in containerSize: CGSize, padding: CGFloat = 32.0) {
        guard canvasSize.width > 0, canvasSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return }
        
        let availW = max(10, containerSize.width - padding * 2)
        let availH = max(10, containerSize.height - padding * 2)
        
        let scaleX = availW / canvasSize.width
        let scaleY = availH / canvasSize.height
        let fitZoom = min(scaleX, scaleY)
        
        self.zoom = max(Self.minZoom, min(Self.maxZoom, Double(fitZoom)))
        self.panOffset = CGPoint(
            x: containerSize.width / 2.0,
            y: containerSize.height / 2.0
        )
        self.rotationRadians = 0.0
        self.viewportSize = containerSize
    }
    
    public mutating func zoomTo100(canvasSize: CGSize, in containerSize: CGSize) {
        self.zoom = 1.0
        self.panOffset = CGPoint(
            x: containerSize.width / 2.0,
            y: containerSize.height / 2.0
        )
        self.rotationRadians = 0.0
        self.viewportSize = containerSize
    }
    
    /// Converts a screen touch coordinate to canvas pixel space
    public func canvasPoint(from screenPoint: CGPoint, canvasSize: CGSize) -> CGPoint {
        let centerScreen = panOffset
        let dx = screenPoint.x - centerScreen.x
        let dy = screenPoint.y - centerScreen.y
        
        // Unrotate
        let cosA = cos(-rotationRadians)
        let sinA = sin(-rotationRadians)
        let unrotatedX = dx * cosA - dy * sinA
        let unrotatedY = dx * sinA + dy * cosA
        
        // Unscale
        let unscaledX = unrotatedX / CGFloat(zoom)
        let unscaledY = unrotatedY / CGFloat(zoom)
        
        // Offset to canvas top-left
        let canvasX = unscaledX + canvasSize.width / 2.0
        let canvasY = unscaledY + canvasSize.height / 2.0
        
        return CGPoint(x: canvasX, y: canvasY)
    }
    
    /// Converts a canvas pixel coordinate to screen space
    public func screenPoint(from canvasPoint: CGPoint, canvasSize: CGSize) -> CGPoint {
        let unscaledX = canvasPoint.x - canvasSize.width / 2.0
        let unscaledY = canvasPoint.y - canvasSize.height / 2.0
        
        let scaledX = unscaledX * CGFloat(zoom)
        let scaledY = unscaledY * CGFloat(zoom)
        
        let cosA = cos(rotationRadians)
        let sinA = sin(rotationRadians)
        let rotatedX = scaledX * cosA - scaledY * sinA
        let rotatedY = scaledX * sinA + scaledY * cosA
        
        return CGPoint(x: rotatedX + panOffset.x, y: rotatedY + panOffset.y)
    }
}
