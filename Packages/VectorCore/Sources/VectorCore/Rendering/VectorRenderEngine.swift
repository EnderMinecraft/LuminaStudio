import Foundation
import CoreGraphics
import CoreText

#if canImport(UIKit)
import UIKit
#endif

public final class VectorRenderEngine: @unchecked Sendable {
    public static let shared = VectorRenderEngine()
    
    public init() {}
    
    // MARK: - Artboard Rendering to Pixel Buffer
    
    public func renderArtboard(
        _ artboard: ArtboardNode,
        scale: CGFloat = 1.0
    ) -> (buffer: [UInt8], size: CGSize) {
        let width = max(1, Int(artboard.size.width * scale))
        let height = max(1, Int(artboard.size.height * scale))
        let bytesPerRow = width * 4
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return (pixelData, CGSize(width: width, height: height))
        }
        
        // Setup coordinate space: origin at top-left
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        
        // Draw background
        if let bgColor = parseColor(hex: artboard.backgroundColorHex) {
            context.setFillColor(bgColor)
            context.fill(CGRect(origin: .zero, size: artboard.size))
        }
        
        // Render child nodes in order
        for child in artboard.children {
            renderNode(child, in: context)
        }
        
        return (pixelData, CGSize(width: width, height: height))
    }
    
    // MARK: - Node Rendering
    
    public func renderNode(_ node: VectorNode, in context: CGContext) {
        switch node {
        case .path(let pathNode):
            renderPathNode(pathNode, in: context)
        case .parametric(let shapeNode):
            renderParametricShapeNode(shapeNode, in: context)
        case .text(let textNode):
            renderTextNode(textNode, in: context)
        case .group(let groupNode):
            context.saveGState()
            context.setAlpha(CGFloat(groupNode.opacity))
            for child in groupNode.children {
                renderNode(child, in: context)
            }
            context.restoreGState()
        }
    }
    
    private func renderPathNode(_ node: PathNode, in context: CGContext) {
        let cgPath = createCGPath(from: node.subpaths)
        guard !cgPath.isEmpty else { return }
        
        context.saveGState()
        context.setAlpha(CGFloat(node.opacity))
        
        // Fill
        if let fillHex = node.fillColorHex, let fillColor = parseColor(hex: fillHex) {
            context.setFillColor(fillColor)
            context.addPath(cgPath)
            context.fillPath()
        }
        
        // Stroke
        if node.strokeWidth > 0, let strokeHex = node.strokeColorHex, let strokeColor = parseColor(hex: strokeHex) {
            context.setStrokeColor(strokeColor)
            context.setLineWidth(node.strokeWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(cgPath)
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    private func renderParametricShapeNode(_ node: ParametricShapeNode, in context: CGContext) {
        let cgPath = createParametricPath(node: node)
        guard !cgPath.isEmpty else { return }
        
        context.saveGState()
        context.setAlpha(CGFloat(node.opacity))
        
        // Fill
        if let fillHex = node.fillColorHex, let fillColor = parseColor(hex: fillHex) {
            context.setFillColor(fillColor)
            context.addPath(cgPath)
            context.fillPath()
        }
        
        // Stroke
        if node.strokeWidth > 0, let strokeHex = node.strokeColorHex, let strokeColor = parseColor(hex: strokeHex) {
            context.setStrokeColor(strokeColor)
            context.setLineWidth(node.strokeWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(cgPath)
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    private func renderTextNode(_ node: VectorTextNode, in context: CGContext) {
        context.saveGState()
        context.setAlpha(CGFloat(node.opacity))
        
        let font = CTFontCreateWithName(node.fontName as CFString, node.fontSize, nil)
        let color = parseColor(hex: node.fillColorHex) ?? CGColor(gray: 0, alpha: 1)
        
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
        ]
        
        let attrString = NSAttributedString(string: node.text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)
        
        // Text in CoreGraphics needs origin adjustment
        context.textPosition = CGPoint(x: node.origin.x, y: node.origin.y + node.fontSize)
        CTLineDraw(line, context)
        
        context.restoreGState()
    }
    
    // MARK: - Path Conversion Helpers
    
    public func createCGPath(from subpaths: [BezierSubpath]) -> CGPath {
        let path = CGMutablePath()
        for subpath in subpaths {
            guard !subpath.points.isEmpty else { continue }
            let points = subpath.points
            path.move(to: points[0].position)
            
            for i in 0..<(points.count - 1) {
                let curr = points[i]
                let next = points[i + 1]
                let c1 = curr.outHandle ?? curr.position
                let c2 = next.inHandle ?? next.position
                path.addCurve(to: next.position, control1: c1, control2: c2)
            }
            
            if subpath.isClosed && points.count > 1 {
                let last = points.last!
                let first = points.first!
                let c1 = last.outHandle ?? last.position
                let c2 = first.inHandle ?? first.position
                path.addCurve(to: first.position, control1: c1, control2: c2)
                path.closeSubpath()
            }
        }
        return path
    }
    
    public func createParametricPath(node: ParametricShapeNode) -> CGPath {
        let path = CGMutablePath()
        let frame = node.frame
        
        switch node.kind {
        case .rect:
            path.addRect(frame)
        case .roundedRect:
            path.addRoundedRect(in: frame, cornerWidth: node.cornerRadius, cornerHeight: node.cornerRadius)
        case .ellipse:
            path.addEllipse(in: frame)
        case .polygon:
            let sides = max(3, min(12, node.polygonSides))
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let radius = min(frame.width, frame.height) / 2.0
            for i in 0..<sides {
                let angle = Double(i) * (2.0 * .pi / Double(sides)) - .pi / 2.0
                let pt = CGPoint(
                    x: center.x + radius * CGFloat(cos(angle)),
                    y: center.y + radius * CGFloat(sin(angle))
                )
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
        case .star:
            let points = 5
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let outerR = min(frame.width, frame.height) / 2.0
            let innerR = outerR * 0.45
            for i in 0..<(points * 2) {
                let angle = Double(i) * (.pi / Double(points)) - .pi / 2.0
                let r = (i % 2 == 0) ? outerR : innerR
                let pt = CGPoint(
                    x: center.x + r * CGFloat(cos(angle)),
                    y: center.y + r * CGFloat(sin(angle))
                )
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
        case .line:
            path.move(to: frame.origin)
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
        }
        return path
    }
    
    // MARK: - Color Parsing
    
    public func parseColor(hex: String) -> CGColor? {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 {
            clean += "FF"
        }
        guard clean.count == 8, let val = UInt32(clean, radix: 16) else { return nil }
        let r = CGFloat((val >> 24) & 0xFF) / 255.0
        let g = CGFloat((val >> 16) & 0xFF) / 255.0
        let b = CGFloat((val >> 8) & 0xFF) / 255.0
        let a = CGFloat(val & 0xFF) / 255.0
        return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
    }
}
