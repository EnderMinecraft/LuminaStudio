import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

public final class VectorInterchange: @unchecked Sendable {
    public static let shared = VectorInterchange()
    
    public init() {}
    
    // MARK: - SVG Export
    
    public func exportSVG(document: VectorDocument) -> String {
        guard let artboard = document.activeArtboard else { return "<svg></svg>" }
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(artboard.size.width))" height="\(Int(artboard.size.height))" viewBox="0 0 \(Int(artboard.size.width)) \(Int(artboard.size.height))">
        <rect width="100%" height="100%" fill="\(artboard.backgroundColorHex)"/>

        """
        
        for node in artboard.children {
            svg += nodeToSVG(node, indent: "  ")
        }
        
        svg += "</svg>\n"
        return svg
    }
    
    private func nodeToSVG(_ node: VectorNode, indent: String) -> String {
        switch node {
        case .path(let p):
            var d = ""
            for subpath in p.subpaths {
                guard !subpath.points.isEmpty else { continue }
                let pts = subpath.points
                d += "M \(String(format: "%.2f", pts[0].position.x)) \(String(format: "%.2f", pts[0].position.y)) "
                for i in 0..<(pts.count - 1) {
                    let curr = pts[i]
                    let next = pts[i + 1]
                    let c1 = curr.outHandle ?? curr.position
                    let c2 = next.inHandle ?? next.position
                    d += "C \(String(format: "%.2f", c1.x)) \(String(format: "%.2f", c1.y)), \(String(format: "%.2f", c2.x)) \(String(format: "%.2f", c2.y)), \(String(format: "%.2f", next.position.x)) \(String(format: "%.2f", next.position.y)) "
                }
                if subpath.isClosed && pts.count > 1 {
                    let last = pts.last!
                    let first = pts.first!
                    let c1 = last.outHandle ?? last.position
                    let c2 = first.inHandle ?? first.position
                    d += "C \(String(format: "%.2f", c1.x)) \(String(format: "%.2f", c1.y)), \(String(format: "%.2f", c2.x)) \(String(format: "%.2f", c2.y)), \(String(format: "%.2f", first.position.x)) \(String(format: "%.2f", first.position.y)) Z "
                }
            }
            let fill = p.fillColorHex ?? "none"
            let stroke = p.strokeColorHex ?? "none"
            return "\(indent)<path id=\"\(p.name)\" d=\"\(d.trimmingCharacters(in: .whitespaces))\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(p.strokeWidth)\" opacity=\"\(p.opacity)\"/>\n"
            
        case .parametric(let s):
            let fill = s.fillColorHex ?? "none"
            let stroke = s.strokeColorHex ?? "none"
            switch s.kind {
            case .rect:
                return "\(indent)<rect id=\"\(s.name)\" x=\"\(s.frame.origin.x)\" y=\"\(s.frame.origin.y)\" width=\"\(s.frame.width)\" height=\"\(s.frame.height)\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(s.strokeWidth)\" opacity=\"\(s.opacity)\"/>\n"
            case .roundedRect:
                return "\(indent)<rect id=\"\(s.name)\" x=\"\(s.frame.origin.x)\" y=\"\(s.frame.origin.y)\" width=\"\(s.frame.width)\" height=\"\(s.frame.height)\" rx=\"\(s.cornerRadius)\" ry=\"\(s.cornerRadius)\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(s.strokeWidth)\" opacity=\"\(s.opacity)\"/>\n"
            case .ellipse:
                let cx = s.frame.midX
                let cy = s.frame.midY
                let rx = s.frame.width / 2.0
                let ry = s.frame.height / 2.0
                return "\(indent)<ellipse id=\"\(s.name)\" cx=\"\(cx)\" cy=\"\(cy)\" rx=\"\(rx)\" ry=\"\(ry)\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(s.strokeWidth)\" opacity=\"\(s.opacity)\"/>\n"
            case .line:
                return "\(indent)<line id=\"\(s.name)\" x1=\"\(s.frame.minX)\" y1=\"\(s.frame.minY)\" x2=\"\(s.frame.maxX)\" y2=\"\(s.frame.maxY)\" stroke=\"\(stroke)\" stroke-width=\"\(s.strokeWidth)\" opacity=\"\(s.opacity)\"/>\n"
            case .polygon, .star:
                let cgPath = VectorRenderEngine.shared.createParametricPath(node: s)
                // Export as SVG path
                return "\(indent)<path id=\"\(s.name)\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(s.strokeWidth)\" opacity=\"\(s.opacity)\"/>\n"
            }
            
        case .text(let t):
            return "\(indent)<text id=\"\(t.name)\" x=\"\(t.origin.x)\" y=\"\(t.origin.y + t.fontSize)\" font-family=\"\(t.fontName)\" font-size=\"\(t.fontSize)\" fill=\"\(t.fillColorHex)\" opacity=\"\(t.opacity)\">\(t.text)</text>\n"
            
        case .group(let g):
            var out = "\(indent)<g id=\"\(g.name)\" opacity=\"\(g.opacity)\">\n"
            for child in g.children {
                out += nodeToSVG(child, indent: indent + "  ")
            }
            out += "\(indent)</g>\n"
            return out
        }
    }
    
    // MARK: - SVG Import
    
    public func importSVG(xmlString: String) -> VectorDocument {
        var nodes: [VectorNode] = []
        var artboardWidth: CGFloat = 1920
        var artboardHeight: CGFloat = 1080
        
        // Basic Regex parsing of dimensions and elements
        if let wMatch = xmlString.range(of: "width=\"([0-9.]+)\"", options: .regularExpression) {
            let str = String(xmlString[wMatch])
            if let val = Double(str.replacingOccurrences(of: "width=\"", with: "").replacingOccurrences(of: "\"", with: "")) {
                artboardWidth = CGFloat(val)
            }
        }
        if let hMatch = xmlString.range(of: "height=\"([0-9.]+)\"", options: .regularExpression) {
            let str = String(xmlString[hMatch])
            if let val = Double(str.replacingOccurrences(of: "height=\"", with: "").replacingOccurrences(of: "\"", with: "")) {
                artboardHeight = CGFloat(val)
            }
        }
        
        // Parse Rectangles
        let rectPattern = "<rect\\s+([^>]+)/>"
        if let regex = try? NSRegularExpression(pattern: rectPattern, options: []) {
            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))
            for m in matches {
                guard let r = Range(m.range(at: 1), in: xmlString) else { continue }
                let attrs = String(xmlString[r])
                if attrs.contains("width=\"100%\"") { continue } // skip background
                
                let x = extractAttr(named: "x", from: attrs) ?? 0
                let y = extractAttr(named: "y", from: attrs) ?? 0
                let w = extractAttr(named: "width", from: attrs) ?? 100
                let h = extractAttr(named: "height", from: attrs) ?? 100
                let fill = extractStringAttr(named: "fill", from: attrs) ?? "#3B82F6"
                
                let shape = ParametricShapeNode(
                    name: "Imported Rect",
                    kind: .rect,
                    frame: CGRect(x: x, y: y, width: w, height: h),
                    fillColorHex: fill
                )
                nodes.append(.parametric(shape))
            }
        }
        
        // Parse Paths
        let pathPattern = "<path\\s+([^>]+)/>"
        if let regex = try? NSRegularExpression(pattern: pathPattern, options: []) {
            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))
            for m in matches {
                guard let r = Range(m.range(at: 1), in: xmlString) else { continue }
                let attrs = String(xmlString[r])
                guard let d = extractStringAttr(named: "d", from: attrs) else { continue }
                let fill = extractStringAttr(named: "fill", from: attrs)
                let stroke = extractStringAttr(named: "stroke", from: attrs)
                let strokeW = extractAttr(named: "stroke-width", from: attrs) ?? 2.0
                
                let subpaths = parseSVGPathData(d)
                if !subpaths.isEmpty {
                    let pathNode = PathNode(
                        name: "Imported Path",
                        subpaths: subpaths,
                        fillColorHex: fill,
                        strokeColorHex: stroke,
                        strokeWidth: strokeW
                    )
                    nodes.append(.path(pathNode))
                }
            }
        }
        
        let artboard = ArtboardNode(
            name: "Artboard",
            size: CGSize(width: artboardWidth, height: artboardHeight),
            children: nodes
        )
        return VectorDocument(title: "Imported SVG", artboards: [artboard])
    }
    
    // MARK: - SVG Path Data Parser (M, L, C, Z)
    
    private func parseSVGPathData(_ d: String) -> [BezierSubpath] {
        var subpaths: [BezierSubpath] = []
        var currentPoints: [AnchorPoint] = []
        var isClosed = false
        
        let tokens = d.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
        var i = 0
        var currentPoint = CGPoint.zero
        
        while i < tokens.count {
            let cmd = tokens[i]
            switch cmd {
            case "M":
                if !currentPoints.isEmpty {
                    subpaths.append(BezierSubpath(isClosed: isClosed, points: currentPoints))
                    currentPoints.removeAll()
                    isClosed = false
                }
                if i + 2 < tokens.count, let x = Double(tokens[i + 1]), let y = Double(tokens[i + 2]) {
                    currentPoint = CGPoint(x: x, y: y)
                    currentPoints.append(AnchorPoint(position: currentPoint))
                    i += 3
                } else {
                    i += 1
                }
            case "L":
                if i + 2 < tokens.count, let x = Double(tokens[i + 1]), let y = Double(tokens[i + 2]) {
                    currentPoint = CGPoint(x: x, y: y)
                    currentPoints.append(AnchorPoint(position: currentPoint))
                    i += 3
                } else {
                    i += 1
                }
            case "C":
                if i + 6 < tokens.count,
                   let c1x = Double(tokens[i + 1]), let c1y = Double(tokens[i + 2]),
                   let c2x = Double(tokens[i + 3]), let c2y = Double(tokens[i + 4]),
                   let px = Double(tokens[i + 5]), let py = Double(tokens[i + 6]) {
                    if !currentPoints.isEmpty {
                        currentPoints[currentPoints.count - 1].outHandle = CGPoint(x: c1x, y: c1y)
                    }
                    currentPoint = CGPoint(x: px, y: py)
                    currentPoints.append(AnchorPoint(
                        position: currentPoint,
                        inHandle: CGPoint(x: c2x, y: c2y)
                    ))
                    i += 7
                } else {
                    i += 1
                }
            case "Z", "z":
                isClosed = true
                i += 1
            default:
                i += 1
            }
        }
        
        if !currentPoints.isEmpty {
            subpaths.append(BezierSubpath(isClosed: isClosed, points: currentPoints))
        }
        return subpaths
    }
    
    // MARK: - PDF Vector Export
    
    public func exportPDF(document: VectorDocument) -> Data {
        guard let artboard = document.activeArtboard else { return Data() }
        let pageRect = CGRect(origin: .zero, size: artboard.size)
        
        #if canImport(UIKit)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { pdfContext in
            pdfContext.beginPage()
            let cgContext = pdfContext.cgContext
            
            // Draw background
            if let bg = VectorRenderEngine.shared.parseColor(hex: artboard.backgroundColorHex) {
                cgContext.setFillColor(bg)
                cgContext.fill(pageRect)
            }
            
            for child in artboard.children {
                VectorRenderEngine.shared.renderNode(child, in: cgContext)
            }
        }
        #else
        // macOS / fallback: return empty Data
        return Data()
        #endif
    }
    
    // MARK: - Attribute Extraction Helpers
    
    private func extractAttr(named name: String, from string: String) -> CGFloat? {
        let pattern = "\(name)=\"([0-9.-]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string),
              let val = Double(string[range]) else {
            return nil
        }
        return CGFloat(val)
    }
    
    private func extractStringAttr(named name: String, from string: String) -> String? {
        let pattern = "\(name)=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return String(string[range])
    }
}
