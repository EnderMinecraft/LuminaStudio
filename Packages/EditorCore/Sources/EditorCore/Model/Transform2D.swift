import Foundation
import CoreGraphics

public struct Transform2D: Codable, Sendable, Equatable {
    public var translation: CGPoint
    public var scale: CGSize
    public var rotationRadians: Double
    public var anchorPoint: CGPoint // In normalized 0..1 coordinates
    
    public init(
        translation: CGPoint = .zero,
        scale: CGSize = CGSize(width: 1.0, height: 1.0),
        rotationRadians: Double = 0.0,
        anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    ) {
        self.translation = translation
        self.scale = scale
        self.rotationRadians = rotationRadians
        self.anchorPoint = anchorPoint
    }
    
    public static let identity = Transform2D()
    
    public func affineTransform(forSize size: CGSize) -> CGAffineTransform {
        let anchorX = size.width * anchorPoint.x
        let anchorY = size.height * anchorPoint.y
        
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: translation.x + anchorX, y: translation.y + anchorY)
        t = t.rotated(by: CGFloat(rotationRadians))
        t = t.scaledBy(x: scale.width, y: scale.height)
        t = t.translatedBy(x: -anchorX, y: -anchorY)
        return t
    }
    
    public func inverted(forSize size: CGSize) -> CGAffineTransform? {
        let t = affineTransform(forSize: size)
        guard t.determinant != 0 else { return nil }
        return t.inverted()
    }
}
