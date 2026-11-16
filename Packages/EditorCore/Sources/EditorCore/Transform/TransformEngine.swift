import Foundation
import CoreGraphics

public enum TransformHandle: String, CaseIterable, Sendable {
    case topLeft
    case topCenter
    case topRight
    case middleLeft
    case middleRight
    case bottomLeft
    case bottomCenter
    case bottomRight
    case rotation
}

public struct SnappingGuide: Sendable, Equatable {
    public enum GuideOrientation: Sendable, Equatable {
        case horizontal(y: CGFloat)
        case vertical(x: CGFloat)
    }
    
    public let orientation: GuideOrientation
    public let label: String
    
    public init(orientation: GuideOrientation, label: String = "") {
        self.orientation = orientation
        self.label = label
    }
}

public struct TransformState: Sendable, Equatable {
    public var translation: CGPoint
    public var scale: CGSize
    public var rotationRadians: Double
    public var isFlippedHorizontally: Bool
    public var isFlippedVertically: Bool
    public var anchorPoint: CGPoint // Normalized 0..1
    public var isAspectRatioLocked: Bool
    
    public init(
        translation: CGPoint = .zero,
        scale: CGSize = CGSize(width: 1.0, height: 1.0),
        rotationRadians: Double = 0.0,
        isFlippedHorizontally: Bool = false,
        isFlippedVertically: Bool = false,
        anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5),
        isAspectRatioLocked: Bool = false
    ) {
        self.translation = translation
        self.scale = scale
        self.rotationRadians = rotationRadians
        self.isFlippedHorizontally = isFlippedHorizontally
        self.isFlippedVertically = isFlippedVertically
        self.anchorPoint = anchorPoint
        self.isAspectRatioLocked = isAspectRatioLocked
    }
    
    public static let identity = TransformState()
    
    public func affineTransform(forSize size: CGSize) -> CGAffineTransform {
        let ax = size.width * anchorPoint.x
        let ay = size.height * anchorPoint.y
        
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: translation.x + ax, y: translation.y + ay)
        t = t.rotated(by: CGFloat(rotationRadians))
        let sx = scale.width * (isFlippedHorizontally ? -1.0 : 1.0)
        let sy = scale.height * (isFlippedVertically ? -1.0 : 1.0)
        t = t.scaledBy(x: sx, y: sy)
        t = t.translatedBy(x: -ax, y: -ay)
        return t
    }
}

public final class TransformEngine: Sendable {
    public static let shared = TransformEngine()
    public static let snappingThreshold: CGFloat = 8.0
    public static let rotationSnapThresholdRadians: Double = 0.087 // ~5 degrees
    
    public init() {}
    
    /// Computes active snapping guides and snaps translation to canvas center / edges
    public func snap(
        translation: CGPoint,
        layerSize: CGSize,
        canvasSize: CGSize
    ) -> (snappedTranslation: CGPoint, activeGuides: [SnappingGuide]) {
        var snapped = translation
        var guides: [SnappingGuide] = []
        
        let centerX = canvasSize.width / 2.0
        let centerY = canvasSize.height / 2.0
        
        let layerCenterX = translation.x + layerSize.width / 2.0
        let layerCenterY = translation.y + layerSize.height / 2.0
        
        // Horizontal Center Snap
        if abs(layerCenterX - centerX) <= Self.snappingThreshold {
            snapped.x = centerX - layerSize.width / 2.0
            guides.append(SnappingGuide(orientation: .vertical(x: centerX), label: "Center X"))
        }
        
        // Vertical Center Snap
        if abs(layerCenterY - centerY) <= Self.snappingThreshold {
            snapped.y = centerY - layerSize.height / 2.0
            guides.append(SnappingGuide(orientation: .horizontal(y: centerY), label: "Center Y"))
        }
        
        // Left Edge Snap
        if abs(translation.x) <= Self.snappingThreshold {
            snapped.x = 0
            guides.append(SnappingGuide(orientation: .vertical(x: 0), label: "Left Edge"))
        }
        
        // Top Edge Snap
        if abs(translation.y) <= Self.snappingThreshold {
            snapped.y = 0
            guides.append(SnappingGuide(orientation: .horizontal(y: 0), label: "Top Edge"))
        }
        
        return (snapped, guides)
    }
    
    /// Snaps rotation angle to 0, 90, 180, 270 degrees
    public func snapRotation(_ radians: Double) -> Double {
        let normalized = radians.truncatingRemainder(dividingBy: .pi * 2.0)
        let targets: [Double] = [0.0, .pi / 2.0, .pi, .pi * 1.5, .pi * 2.0, -.pi / 2.0, -.pi, -.pi * 1.5]
        for target in targets {
            if abs(normalized - target) <= Self.rotationSnapThresholdRadians {
                return target
            }
        }
        return radians
    }
}
