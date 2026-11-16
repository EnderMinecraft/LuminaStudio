import Foundation
import CoreGraphics

public struct CanvasConfiguration: Codable, Sendable, Equatable {
    public var width: Int
    public var height: Int
    public var dpi: Double
    public var colorSpace: LuminaColorSpace
    public var backgroundColor: CanvasBackgroundColor
    
    public init(
        width: Int = 2048,
        height: Int = 2048,
        dpi: Double = 300.0,
        colorSpace: LuminaColorSpace = .displayP3,
        backgroundColor: CanvasBackgroundColor = .white
    ) {
        self.width = max(16, min(width, 8192))
        self.height = max(16, min(height, 8192))
        self.dpi = dpi
        self.colorSpace = colorSpace
        self.backgroundColor = backgroundColor
    }
    
    public var size: CGSize {
        CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    
    public var aspectRatio: Double {
        Double(width) / Double(max(1, height))
    }
}

public enum CanvasBackgroundColor: Codable, Sendable, Equatable {
    case white
    case black
    case transparent
    case custom(r: Double, g: Double, b: Double, a: Double)
    
    public var rgba: (r: Double, g: Double, b: Double, a: Double) {
        switch self {
        case .white:
            return (1.0, 1.0, 1.0, 1.0)
        case .black:
            return (0.0, 0.0, 0.0, 1.0)
        case .transparent:
            return (0.0, 0.0, 0.0, 0.0)
        case .custom(let r, let g, let b, let a):
            return (r, g, b, a)
        }
    }
}
