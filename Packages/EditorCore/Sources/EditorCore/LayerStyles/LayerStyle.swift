import Foundation
import CoreGraphics

public struct DropShadowStyle: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var colorHex: String
    public var opacity: Double
    public var offset: CGSize
    public var blurRadius: CGFloat
    
    public init(
        isEnabled: Bool = false,
        colorHex: String = "#000000",
        opacity: Double = 0.5,
        offset: CGSize = CGSize(width: 4, height: 4),
        blurRadius: CGFloat = 8.0
    ) {
        self.isEnabled = isEnabled
        self.colorHex = colorHex
        self.opacity = opacity
        self.offset = offset
        self.blurRadius = blurRadius
    }
}

public struct StrokeStyleData: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var width: CGFloat
    public var colorHex: String
    
    public init(
        isEnabled: Bool = false,
        width: CGFloat = 2.0,
        colorHex: String = "#FFFFFF"
    ) {
        self.isEnabled = isEnabled
        self.width = width
        self.colorHex = colorHex
    }
}

public struct OuterGlowStyle: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var colorHex: String
    public var opacity: Double
    public var radius: CGFloat
    
    public init(
        isEnabled: Bool = false,
        colorHex: String = "#3B82F6",
        opacity: Double = 0.7,
        radius: CGFloat = 12.0
    ) {
        self.isEnabled = isEnabled
        self.colorHex = colorHex
        self.opacity = opacity
        self.radius = radius
    }
}

public struct LayerStyle: Codable, Sendable, Equatable {
    public var dropShadow: DropShadowStyle
    public var stroke: StrokeStyleData
    public var outerGlow: OuterGlowStyle
    
    public init(
        dropShadow: DropShadowStyle = DropShadowStyle(),
        stroke: StrokeStyleData = StrokeStyleData(),
        outerGlow: OuterGlowStyle = OuterGlowStyle()
    ) {
        self.dropShadow = dropShadow
        self.stroke = stroke
        self.outerGlow = outerGlow
    }
}
