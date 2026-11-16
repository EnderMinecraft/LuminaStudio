import Foundation
import CoreGraphics

public final class CollageRenderEngine: @unchecked Sendable {
    public static let shared = CollageRenderEngine()
    
    public init() {}
    
    public func targetSize(for preset: AspectRatioPreset, baseDimension: CGFloat = 2048) -> CGSize {
        switch preset {
        case .square:
            return CGSize(width: baseDimension, height: baseDimension)
        case .story: // 9:16
            return CGSize(width: baseDimension * (9.0 / 16.0), height: baseDimension)
        case .portrait: // 4:5
            return CGSize(width: baseDimension * (4.0 / 5.0), height: baseDimension)
        case .landscape: // 16:9
            return CGSize(width: baseDimension, height: baseDimension * (9.0 / 16.0))
        case .a4: // 1:sqrt(2) ~ 210:297
            return CGSize(width: baseDimension * (210.0 / 297.0), height: baseDimension)
        }
    }
    
    public func renderCollage(
        document: CollageDocument,
        baseDimension: CGFloat = 2048,
        assetProvider: ((_ assetID: String) -> [UInt8]?)? = nil
    ) -> (buffer: [UInt8], size: CGSize) {
        let size = targetSize(for: document.aspectRatioPreset, baseDimension: baseDimension)
        let width = Int(size.width)
        let height = Int(size.height)
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
            return (pixelData, size)
        }
        
        // Fill background
        if let bgColor = parseColor(hex: document.backgroundColorHex) {
            context.setFillColor(bgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        // Solve cell geometry
        let bounds = CGRect(origin: .zero, size: size)
        let (cells, _) = BSPLayoutSolver.shared.solve(
            node: document.rootNode,
            in: bounds,
            spacing: document.cellSpacing * (baseDimension / 1000.0),
            margin: document.outerMargin * (baseDimension / 1000.0)
        )
        
        let cr = document.cornerRadius * (baseDimension / 1000.0)
        
        // Render each cell
        for (idx, item) in cells.enumerated() {
            context.saveGState()
            
            // Rounded rectangle clip
            let clipPath = CGPath(
                roundedRect: item.rect,
                cornerWidth: item.cell.customCornerRadius ?? cr,
                cornerHeight: item.cell.customCornerRadius ?? cr,
                transform: nil
            )
            context.addPath(clipPath)
            context.clip()
            
            // Fallback decorative gradient for empty cells
            let colors = paletteColor(for: idx)
            drawPlaceholderCell(in: context, rect: item.rect, colorA: colors.0, colorB: colors.1)
            
            context.restoreGState()
        }
        
        return (pixelData, size)
    }
    
    private func drawPlaceholderCell(in context: CGContext, rect: CGRect, colorA: CGColor, colorB: CGColor) {
        let space = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: space, colors: [colorA, colorB] as CFArray, locations: [0.0, 1.0])!
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )
    }
    
    private func paletteColor(for index: Int) -> (CGColor, CGColor) {
        let palettes: [(UInt32, UInt32)] = [
            (0x3B82F6FF, 0x1D4ED8FF), // Blue
            (0x10B981FF, 0x047857FF), // Emerald
            (0xF59E0BFF, 0xB45309FF), // Amber
            (0x8B5CF6FF, 0x6D28D9FF), // Purple
            (0xEC4899FF, 0xBE185DFF), // Pink
            (0x06B6D4FF, 0x0E7490FF)  // Cyan
        ]
        let pair = palettes[index % palettes.count]
        return (colorFromUInt(pair.0), colorFromUInt(pair.1))
    }
    
    private func colorFromUInt(_ val: UInt32) -> CGColor {
        let r = CGFloat((val >> 24) & 0xFF) / 255.0
        let g = CGFloat((val >> 16) & 0xFF) / 255.0
        let b = CGFloat((val >> 8) & 0xFF) / 255.0
        let a = CGFloat(val & 0xFF) / 255.0
        return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
    }
    
    private func parseColor(hex: String) -> CGColor? {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 { clean += "FF" }
        guard clean.count == 8, let val = UInt32(clean, radix: 16) else { return nil }
        return colorFromUInt(val)
    }
}
