import Foundation
import CoreGraphics

public enum LayerKind: Codable, Sendable, Equatable {
    case raster(assetID: String?)
    case adjustment(AdjustmentType)
    case text(TextLayerData)
    case shape(ShapeLayerData)
    case vector(vectorDocumentID: String?)
    case group(childLayerIDs: [UUID])
}

public enum AdjustmentType: String, Codable, Sendable, CaseIterable {
    case brightnessContrast = "Brightness / Contrast"
    case exposure = "Exposure"
    case levels = "Levels"
    case curves = "Curves"
    case hueSaturation = "Hue / Saturation"
    case vibrance = "Vibrance"
    case colorBalance = "Color Balance"
    case temperatureTint = "Temperature / Tint"
    case blackAndWhite = "Black & White"
    case vignette = "Vignette"
    case sharpen = "Sharpen"
}

public struct TextLayerData: Codable, Sendable, Equatable {
    public var text: String
    public var fontName: String
    public var fontSize: CGFloat
    public var tracking: CGFloat
    public var lineHeight: CGFloat
    public var textColorHex: String
    public var alignment: Int // 0: left, 1: center, 2: right
    
    public init(
        text: String = "Text",
        fontName: String = "HelveticaNeue",
        fontSize: CGFloat = 36.0,
        tracking: CGFloat = 0.0,
        lineHeight: CGFloat = 1.2,
        textColorHex: String = "#FFFFFF",
        alignment: Int = 1
    ) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.textColorHex = textColorHex
        self.alignment = alignment
    }
}

public struct ShapeLayerData: Codable, Sendable, Equatable {
    public enum ShapeType: String, Codable, Sendable {
        case rectangle
        case roundedRectangle
        case ellipse
        case polygon
        case star
        case line
    }
    
    public var type: ShapeType
    public var fillColorHex: String?
    public var strokeColorHex: String?
    public var strokeWidth: CGFloat
    public var cornerRadius: CGFloat
    public var polygonSides: Int
    
    public init(
        type: ShapeType = .rectangle,
        fillColorHex: String? = "#3B82F6",
        strokeColorHex: String? = nil,
        strokeWidth: CGFloat = 0.0,
        cornerRadius: CGFloat = 0.0,
        polygonSides: Int = 5
    ) {
        self.type = type
        self.fillColorHex = fillColorHex
        self.strokeColorHex = strokeColorHex
        self.strokeWidth = strokeWidth
        self.cornerRadius = cornerRadius
        self.polygonSides = polygonSides
    }
}

public final class Layer: Codable, @unchecked Sendable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var opacity: Float
    public var blendMode: LuminaBlendMode
    public var isVisible: Bool
    public var isLocked: Bool
    public var transform: Transform2D
    public var mask: LayerMask?
    public var kind: LayerKind
    public var isClippingMask: Bool
    public var style: LayerStyle?
    
    // In-memory raw RGBA8 image buffer (nil if empty or tile-streamed)
    public var rawPixelData: Data?
    public var pixelWidth: Int
    public var pixelHeight: Int
    
    public init(
        id: UUID = UUID(),
        name: String = "New Layer",
        opacity: Float = 1.0,
        blendMode: LuminaBlendMode = .normal,
        isVisible: Bool = true,
        isLocked: Bool = false,
        transform: Transform2D = .identity,
        mask: LayerMask? = nil,
        kind: LayerKind = .raster(assetID: nil),
        isClippingMask: Bool = false,
        style: LayerStyle? = nil,
        rawPixelData: Data? = nil,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0
    ) {
        self.id = id
        self.name = name
        self.opacity = max(0.0, min(1.0, opacity))
        self.blendMode = blendMode
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.transform = transform
        self.mask = mask
        self.kind = kind
        self.isClippingMask = isClippingMask
        self.style = style
        self.rawPixelData = rawPixelData
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
    
    public func duplicate() -> Layer {
        let copy = Layer(
            id: UUID(),
            name: "\(name) Copy",
            opacity: opacity,
            blendMode: blendMode,
            isVisible: isVisible,
            isLocked: isLocked,
            transform: transform,
            mask: mask != nil ? LayerMask(
                isEnabled: mask!.isEnabled,
                isInverted: mask!.isInverted,
                width: mask!.width,
                height: mask!.height
            ) : nil,
            kind: kind,
            isClippingMask: isClippingMask,
            style: style,
            rawPixelData: rawPixelData,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        )
        if let mask = self.mask, let copyMask = copy.mask {
            copyMask.maskData = mask.maskData
        }
        return copy
    }
    
    public static func == (lhs: Layer, rhs: Layer) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.opacity == rhs.opacity &&
        lhs.blendMode == rhs.blendMode &&
        lhs.isVisible == rhs.isVisible &&
        lhs.isLocked == rhs.isLocked &&
        lhs.transform == rhs.transform &&
        lhs.mask == rhs.mask &&
        lhs.kind == rhs.kind &&
        lhs.pixelWidth == rhs.pixelWidth &&
        lhs.pixelHeight == rhs.pixelHeight
    }
}
