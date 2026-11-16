import Foundation
import CoreGraphics

public final class ShapeEngine: Sendable {
    public static let shared = ShapeEngine()
    
    public init() {}
    
    public func renderShape(
        data: ShapeLayerData,
        bounds: CGSize
    ) -> [UInt8] {
        let w = max(16, Int(ceil(bounds.width)))
        let h = max(16, Int(ceil(bounds.height)))
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        buffer.withUnsafeMutableBytes { ptr in
            guard let ctx = CGContext(
                data: ptr.baseAddress,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: w * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return }
            
            let rect = CGRect(x: 4, y: 4, width: CGFloat(w) - 8, height: CGFloat(h) - 8)
            let path = CGMutablePath()
            
            switch data.type {
            case .rectangle:
                path.addRect(rect)
                
            case .roundedRectangle:
                path.addRoundedRect(in: rect, cornerWidth: data.cornerRadius, cornerHeight: data.cornerRadius)
                
            case .ellipse:
                path.addEllipse(in: rect)
                
            case .polygon:
                let sides = max(3, data.polygonSides)
                let cx = rect.midX
                let cy = rect.midY
                let r = min(rect.width, rect.height) / 2.0
                for i in 0..<sides {
                    let angle = Double(i) * 2.0 * .pi / Double(sides) - .pi / 2.0
                    let x = cx + r * CGFloat(cos(angle))
                    let y = cy + r * CGFloat(sin(angle))
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
                
            case .star:
                let points = 5
                let cx = rect.midX
                let cy = rect.midY
                let outerR = min(rect.width, rect.height) / 2.0
                let innerR = outerR * 0.45
                for i in 0..<(points * 2) {
                    let r = i % 2 == 0 ? outerR : innerR
                    let angle = Double(i) * .pi / Double(points) - .pi / 2.0
                    let x = cx + r * CGFloat(cos(angle))
                    let y = cy + r * CGFloat(sin(angle))
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
                
            case .line:
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            }
            
            // Fill
            if let fillHex = data.fillColorHex {
                let (r, g, b) = Self.parseHex(fillHex)
                ctx.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
                ctx.addPath(path)
                ctx.fillPath()
            }
            
            // Stroke
            if let strokeHex = data.strokeColorHex, data.strokeWidth > 0 {
                let (r, g, b) = Self.parseHex(strokeHex)
                ctx.setStrokeColor(red: r, green: g, blue: b, alpha: 1.0)
                ctx.setLineWidth(data.strokeWidth)
                ctx.addPath(path)
                ctx.strokePath()
            }
        }
        
        return buffer
    }
    
    private static func parseHex(_ hex: String) -> (CGFloat, CGFloat, CGFloat) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") { str.removeFirst() }
        var rgbValue: UInt64 = 0
        Scanner(string: str).scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        return (r, g, b)
    }
}
