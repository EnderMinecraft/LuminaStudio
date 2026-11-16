import SwiftUI
import EditorCore

public struct CurvesSplineEditorView: View {
    @Binding public var curvesData: CurvesData
    public let onCurveChanged: () -> Void
    
    @State private var draggingPointIndex: Int?
    
    public init(curvesData: Binding<CurvesData>, onCurveChanged: @escaping () -> Void = {}) {
        self._curvesData = curvesData
        self.onCurveChanged = onCurveChanged
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Channel Selector
            Picker("Channel", selection: $curvesData.activeChannel) {
                ForEach(CurvesData.Channel.allCases, id: \.self) { ch in
                    Text(ch.rawValue).tag(ch)
                }
            }
            .pickerStyle(.segmented)
            
            // Interactive Spline Graph
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                let points = activePoints
                let spline = MonotoneCubicSpline(points: points)
                
                ZStack {
                    // Grid lines (4x4)
                    Path { p in
                        for i in 1...3 {
                            let x = w * CGFloat(i) / 4.0
                            let y = h * CGFloat(i) / 4.0
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: h))
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                    }
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    
                    // Diagonal neutral reference line
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h))
                        p.addLine(to: CGPoint(x: w, y: 0))
                    }
                    .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    
                    // Evaluated Spline Curve
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * (1.0 - spline.evaluate(at: 0.0))))
                        for step in 1...100 {
                            let nx = Double(step) / 100.0
                            let ny = spline.evaluate(at: nx)
                            p.addLine(to: CGPoint(x: w * CGFloat(nx), y: h * CGFloat(1.0 - ny)))
                        }
                    }
                    .stroke(channelColor, lineWidth: 2.5)
                    
                    // Control Point Dots
                    ForEach(Array(points.enumerated()), id: \.offset) { index, pt in
                        Circle()
                            .fill(Color.white)
                            .stroke(channelColor, lineWidth: 2)
                            .frame(width: 14, height: 14)
                            .position(x: w * CGFloat(pt.x), y: h * CGFloat(1.0 - pt.y))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrag(at: value.location, in: proxy.size)
                        }
                        .onEnded { _ in
                            draggingPointIndex = nil
                            onCurveChanged()
                        }
                )
            }
            .frame(height: 220)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Reset Channel Button
            HStack {
                Spacer()
                Button("Reset Channel") {
                    setActivePoints([SplinePoint(x: 0, y: 0), SplinePoint(x: 1, y: 1)])
                    onCurveChanged()
                }
                .font(.caption)
            }
        }
    }
    
    private var channelColor: Color {
        switch curvesData.activeChannel {
        case .rgb: return .primary
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        }
    }
    
    private var activePoints: [SplinePoint] {
        switch curvesData.activeChannel {
        case .rgb: return curvesData.rgbPoints
        case .red: return curvesData.redPoints
        case .green: return curvesData.greenPoints
        case .blue: return curvesData.bluePoints
        }
    }
    
    private func setActivePoints(_ pts: [SplinePoint]) {
        switch curvesData.activeChannel {
        case .rgb: curvesData.rgbPoints = pts
        case .red: curvesData.redPoints = pts
        case .green: curvesData.greenPoints = pts
        case .blue: curvesData.bluePoints = pts
        }
    }
    
    private func handleDrag(at point: CGPoint, in size: CGSize) {
        let nx = max(0.0, min(1.0, Double(point.x / size.width)))
        let ny = max(0.0, min(1.0, 1.0 - Double(point.y / size.height)))
        var pts = activePoints
        
        if let idx = draggingPointIndex {
            // Endpoints cannot move horizontally
            if idx == 0 {
                pts[0] = SplinePoint(x: 0.0, y: ny)
            } else if idx == pts.count - 1 {
                pts[pts.count - 1] = SplinePoint(x: 1.0, y: ny)
            } else {
                pts[idx] = SplinePoint(x: nx, y: ny)
            }
            pts.sort { $0.x < $1.x }
            setActivePoints(pts)
            return
        }
        
        // Find closest point within touch radius
        for (i, pt) in pts.enumerated() {
            let px = pt.x * Double(size.width)
            let py = (1.0 - pt.y) * Double(size.height)
            let dist = hypot(point.x - CGFloat(px), point.y - CGFloat(py))
            if dist < 24 {
                draggingPointIndex = i
                return
            }
        }
        
        // If not dragging an existing point and under max limit, add new point
        if pts.count < 8 {
            pts.append(SplinePoint(x: nx, y: ny))
            pts.sort { $0.x < $1.x }
            setActivePoints(pts)
            if let newIdx = pts.firstIndex(where: { abs($0.x - nx) < 1e-4 && abs($0.y - ny) < 1e-4 }) {
                draggingPointIndex = newIdx
            }
        }
    }
}
