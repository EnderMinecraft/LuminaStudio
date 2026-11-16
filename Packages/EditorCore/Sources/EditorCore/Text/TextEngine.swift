import Foundation
import CoreGraphics
import CoreText

#if canImport(UIKit)
import UIKit
#endif

public struct TextStyleData: Codable, Sendable, Equatable {
    public var fontName: String
    public var fontSize: CGFloat
    public var tracking: CGFloat   // Letter spacing in points
    public var lineHeight: CGFloat // Multiplier e.g. 1.2
    public var colorHex: String
    public var alignment: Int      // 0: left, 1: center, 2: right
    public var strokeWidth: CGFloat
    public var strokeColorHex: String?
    public var shadowColorHex: String?
    public var shadowRadius: CGFloat
    public var shadowOffset: CGSize
    
    public init(
        fontName: String = "HelveticaNeue",
        fontSize: CGFloat = 48.0,
        tracking: CGFloat = 0.0,
        lineHeight: CGFloat = 1.2,
        colorHex: String = "#FFFFFF",
        alignment: Int = 1,
        strokeWidth: CGFloat = 0.0,
        strokeColorHex: String? = nil,
        shadowColorHex: String? = nil,
        shadowRadius: CGFloat = 0.0,
        shadowOffset: CGSize = .zero
    ) {
        self.fontName = fontName
        self.fontSize = max(8.0, min(288.0, fontSize))
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.colorHex = colorHex
        self.alignment = alignment
        self.strokeWidth = strokeWidth
        self.strokeColorHex = strokeColorHex
        self.shadowColorHex = shadowColorHex
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
}

public final class TextEngine: Sendable {
    public static let shared = TextEngine()
    
    public init() {}
    
    /// Registers a custom TTF or OTF font from raw data
    public func registerCustomFont(data: Data) -> String? {
        guard let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider) else {
            return nil
        }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            return cgFont.postScriptName as String?
        }
        return nil
    }
    
    /// Renders text with typography styling into an RGBA8 buffer of the given size
    public func renderText(
        text: String,
        style: TextStyleData,
        bounds: CGSize
    ) -> (buffer: [UInt8], renderedSize: CGSize) {
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
            
            // Flip Y for CoreText
            ctx.translateBy(x: 0, y: CGFloat(h))
            ctx.scaleBy(x: 1.0, y: -1.0)
            
            // Build Attributed String
            let ctFont = CTFontCreateWithName(style.fontName as CFString, style.fontSize, nil)
            var attributes: [NSAttributedString.Key: Any] = [
                .font: ctFont,
                .kern: style.tracking
            ]
            
            // Text Color
            let (r, g, b) = Self.parseHex(style.colorHex)
            let textColor = CGColor(colorSpace: colorSpace, components: [r, g, b, 1.0])!
            attributes[.foregroundColor] = textColor
            
            // Paragraph Alignment
            let ctAlignment: CTTextAlignment
            switch style.alignment {
            case 0: ctAlignment = .left
            case 2: ctAlignment = .right
            default: ctAlignment = .center
            }
            var alignmentSetting = ctAlignment
            let alignStyle = withUnsafeBytes(of: &alignmentSetting) { ptr in
                CTParagraphStyleSetting(
                    spec: .alignment,
                    valueSize: MemoryLayout<CTTextAlignment>.size,
                    value: ptr.baseAddress!
                )
            }
            var settings = [alignStyle]
            let paragraphStyle = CTParagraphStyleCreate(&settings, settings.count)
            attributes[.paragraphStyle] = paragraphStyle
            
            let attrStr = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attrStr as CFAttributedString)
            
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: w, height: h))
            
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrStr.length), path, nil)
            CTFrameDraw(frame, ctx)
        }
        
        return (buffer, CGSize(width: w, height: h))
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
