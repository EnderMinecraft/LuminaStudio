import Foundation
import CoreGraphics

public enum VectorNode: Codable, Sendable, Identifiable, Equatable {
    case path(PathNode)
    case parametric(ParametricShapeNode)
    case text(VectorTextNode)
    case group(VectorGroupNode)
    
    public var id: UUID {
        switch self {
        case .path(let n): return n.id
        case .parametric(let n): return n.id
        case .text(let n): return n.id
        case .group(let n): return n.id
        }
    }
    
    public var name: String {
        switch self {
        case .path(let n): return n.name
        case .parametric(let n): return n.name
        case .text(let n): return n.name
        case .group(let n): return n.name
        }
    }
}

public struct PathNode: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var subpaths: [BezierSubpath]
    public var fillColorHex: String?
    public var strokeColorHex: String?
    public var strokeWidth: CGFloat
    public var opacity: Float
    
    public init(
        id: UUID = UUID(),
        name: String = "Path",
        subpaths: [BezierSubpath] = [],
        fillColorHex: String? = "#3B82F6",
        strokeColorHex: String? = "#1E40AF",
        strokeWidth: CGFloat = 2.0,
        opacity: Float = 1.0
    ) {
        self.id = id
        self.name = name
        self.subpaths = subpaths
        self.fillColorHex = fillColorHex
        self.strokeColorHex = strokeColorHex
        self.strokeWidth = strokeWidth
        self.opacity = opacity
    }
}

public struct ParametricShapeNode: Codable, Sendable, Identifiable, Equatable {
    public enum ShapeKind: String, Codable, Sendable {
        case rect
        case roundedRect
        case ellipse
        case polygon
        case star
        case line
    }
    
    public var id: UUID
    public var name: String
    public var kind: ShapeKind
    public var frame: CGRect
    public var cornerRadius: CGFloat
    public var polygonSides: Int
    public var fillColorHex: String?
    public var strokeColorHex: String?
    public var strokeWidth: CGFloat
    public var opacity: Float
    
    public init(
        id: UUID = UUID(),
        name: String = "Shape",
        kind: ShapeKind = .rect,
        frame: CGRect = CGRect(x: 0, y: 0, width: 200, height: 200),
        cornerRadius: CGFloat = 0.0,
        polygonSides: Int = 5,
        fillColorHex: String? = "#10B981",
        strokeColorHex: String? = nil,
        strokeWidth: CGFloat = 0.0,
        opacity: Float = 1.0
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.frame = frame
        self.cornerRadius = cornerRadius
        self.polygonSides = polygonSides
        self.fillColorHex = fillColorHex
        self.strokeColorHex = strokeColorHex
        self.strokeWidth = strokeWidth
        self.opacity = opacity
    }
}

public struct VectorTextNode: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var text: String
    public var fontName: String
    public var fontSize: CGFloat
    public var origin: CGPoint
    public var fillColorHex: String
    public var opacity: Float
    
    public init(
        id: UUID = UUID(),
        name: String = "Vector Text",
        text: String = "Vector",
        fontName: String = "HelveticaNeue",
        fontSize: CGFloat = 48.0,
        origin: CGPoint = .zero,
        fillColorHex: String = "#000000",
        opacity: Float = 1.0
    ) {
        self.id = id
        self.name = name
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.origin = origin
        self.fillColorHex = fillColorHex
        self.opacity = opacity
    }
}

public struct VectorGroupNode: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var children: [VectorNode]
    public var opacity: Float
    
    public init(
        id: UUID = UUID(),
        name: String = "Group",
        children: [VectorNode] = [],
        opacity: Float = 1.0
    ) {
        self.id = id
        self.name = name
        self.children = children
        self.opacity = opacity
    }
}
