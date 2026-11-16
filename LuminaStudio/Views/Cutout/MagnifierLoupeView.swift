import SwiftUI
import EditorCore

public struct MagnifierLoupeView: View {
    public let touchPoint: CGPoint
    public let canvasSize: CGSize
    public let viewport: ViewportState
    public let rawPixels: Data?
    public let maskData: Data?
    
    public init(
        touchPoint: CGPoint,
        canvasSize: CGSize,
        viewport: ViewportState,
        rawPixels: Data?,
        maskData: Data?
    ) {
        self.touchPoint = touchPoint
        self.canvasSize = canvasSize
        self.viewport = viewport
        self.rawPixels = rawPixels
        self.maskData = maskData
    }
    
    public var body: some View {
        let loupeSize: CGFloat = 110.0
        let loupeOffset: CGFloat = 85.0
        
        ZStack {
            // Background & Border
            Circle()
                .fill(Color(uiColor: .systemBackground))
                .frame(width: loupeSize, height: loupeSize)
                .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
            
            // 2x Magnified Preview
            Circle()
                .stroke(Color.accentColor, lineWidth: 2.5)
                .frame(width: loupeSize, height: loupeSize)
            
            // Reticle / Crosshair
            Path { p in
                let r = loupeSize / 2.0
                p.move(to: CGPoint(x: r - 12, y: r))
                p.addLine(to: CGPoint(x: r + 12, y: r))
                p.move(to: CGPoint(x: r, y: r - 12))
                p.addLine(to: CGPoint(x: r, y: r + 12))
            }
            .stroke(Color.accentColor.opacity(0.8), lineWidth: 1.5)
            .frame(width: loupeSize, height: loupeSize)
        }
        .position(x: touchPoint.x, y: touchPoint.y - loupeOffset)
        .allowsHitTesting(false)
    }
}

public struct CutoutMiniMapView: View {
    public let canvasSize: CGSize
    public let viewport: ViewportState
    
    public init(canvasSize: CGSize, viewport: ViewportState) {
        self.canvasSize = canvasSize
        self.viewport = viewport
    }
    
    public var body: some View {
        let mapWidth: CGFloat = 100.0
        let aspect = canvasSize.width / max(1.0, canvasSize.height)
        let mapHeight = mapWidth / aspect
        
        // Calculate viewport bounds within canvas
        let normW = min(1.0, viewport.viewportSize.width / (canvasSize.width * CGFloat(viewport.zoom)))
        let normH = min(1.0, viewport.viewportSize.height / (canvasSize.height * CGFloat(viewport.zoom)))
        
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.65))
                .frame(width: mapWidth, height: mapHeight)
            
            // Active Viewport Box
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.accentColor, lineWidth: 1.5)
                .frame(width: max(10, mapWidth * normW), height: max(10, mapHeight * normH))
                .offset(x: mapWidth * 0.5 * (1.0 - normW), y: mapHeight * 0.5 * (1.0 - normH))
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 6)
    }
}
