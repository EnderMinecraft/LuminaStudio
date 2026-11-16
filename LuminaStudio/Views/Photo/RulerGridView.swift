import SwiftUI
import EditorCore

public struct RulerGridView: View {
    public let canvasSize: CGSize
    public let viewport: ViewportState
    public let showGrid: Bool
    public let showRulers: Bool
    public let gridSpacing: CGFloat
    
    public init(
        canvasSize: CGSize,
        viewport: ViewportState,
        showGrid: Bool = true,
        showRulers: Bool = true,
        gridSpacing: CGFloat = 64.0
    ) {
        self.canvasSize = canvasSize
        self.viewport = viewport
        self.showGrid = showGrid
        self.showRulers = showRulers
        self.gridSpacing = gridSpacing
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Canvas Grid
                if showGrid {
                    Canvas { context, size in
                        let start = viewport.screenPoint(from: .zero, canvasSize: canvasSize)
                        let scaledStep = gridSpacing * CGFloat(viewport.zoom)
                        guard scaledStep >= 8.0 else { return }
                        
                        var path = Path()
                        // Vertical grid lines
                        for x in stride(from: start.x, to: size.width, by: scaledStep) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        // Horizontal grid lines
                        for y in stride(from: start.y, to: size.height, by: scaledStep) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(path, with: .color(.primary.opacity(0.12)), lineWidth: 1)
                    }
                    .allowsHitTesting(false)
                }
                
                // Top Ruler
                if showRulers {
                    VStack {
                        topRuler(width: proxy.size.width)
                        Spacer()
                    }
                    HStack {
                        leadingRuler(height: proxy.size.height)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func topRuler(width: CGFloat) -> some View {
        Canvas { context, size in
            let rulerH: CGFloat = 18.0
            let start = viewport.screenPoint(from: .zero, canvasSize: canvasSize)
            let scaled100 = 100.0 * CGFloat(viewport.zoom)
            guard scaled100 >= 15.0 else { return }
            
            var path = Path()
            path.addRect(CGRect(x: 0, y: 0, width: width, height: rulerH))
            context.fill(path, with: .color(Color(uiColor: .systemBackground).opacity(0.85)))
            
            var marksPath = Path()
            for px in stride(from: 0, to: canvasSize.width, by: 100.0) {
                let screenX = viewport.screenPoint(from: CGPoint(x: px, y: 0), canvasSize: canvasSize).x
                marksPath.move(to: CGPoint(x: screenX, y: rulerH - 6))
                marksPath.addLine(to: CGPoint(x: screenX, y: rulerH))
                
                let text = Text("\(Int(px))").font(.system(size: 8))
                context.draw(text, at: CGPoint(x: screenX + 12, y: 7))
            }
            context.stroke(marksPath, with: .color(.primary.opacity(0.6)), lineWidth: 1)
        }
        .frame(height: 18)
        .allowsHitTesting(false)
    }
    
    private func leadingRuler(height: CGFloat) -> some View {
        Canvas { context, size in
            let rulerW: CGFloat = 18.0
            let start = viewport.screenPoint(from: .zero, canvasSize: canvasSize)
            let scaled100 = 100.0 * CGFloat(viewport.zoom)
            guard scaled100 >= 15.0 else { return }
            
            var path = Path()
            path.addRect(CGRect(x: 0, y: 0, width: rulerW, height: height))
            context.fill(path, with: .color(Color(uiColor: .systemBackground).opacity(0.85)))
            
            var marksPath = Path()
            for py in stride(from: 0, to: canvasSize.height, by: 100.0) {
                let screenY = viewport.screenPoint(from: CGPoint(x: 0, y: py), canvasSize: canvasSize).y
                marksPath.move(to: CGPoint(x: rulerW - 6, y: screenY))
                marksPath.addLine(to: CGPoint(x: rulerW, y: screenY))
            }
            context.stroke(marksPath, with: .color(.primary.opacity(0.6)), lineWidth: 1)
        }
        .frame(width: 18)
        .allowsHitTesting(false)
    }
}
