import SwiftUI
import EditorCore

public struct SelectionOverlayView: View {
    public let segments: [LineSegment]
    public let canvasSize: CGSize
    public let viewport: ViewportState
    
    public init(segments: [LineSegment], canvasSize: CGSize, viewport: ViewportState) {
        self.segments = segments
        self.canvasSize = canvasSize
        self.viewport = viewport
    }
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            let phase = CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.8) / 0.8 * 8.0)
            
            Canvas { context, size in
                guard !segments.isEmpty else { return }
                
                var path = Path()
                for seg in segments {
                    let startScreen = viewport.screenPoint(from: seg.start, canvasSize: canvasSize)
                    let endScreen = viewport.screenPoint(from: seg.end, canvasSize: canvasSize)
                    path.move(to: startScreen)
                    path.addLine(to: endScreen)
                }
                
                // Base white line
                context.stroke(
                    path,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 4], dashPhase: phase)
                )
                
                // Alternating black dash
                context.stroke(
                    path,
                    with: .color(.black),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 4], dashPhase: phase + 4)
                )
            }
            .allowsHitTesting(false)
        }
    }
}
