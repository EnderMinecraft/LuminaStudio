import SwiftUI
import EditorCore

public struct HistogramView: View {
    public let data: HistogramData
    
    public init(data: HistogramData) {
        self.data = data
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let maxVal = Double(max(1, data.maxBinValue))
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.6))
                
                // Red Channel Curve
                channelPath(bins: data.redBins, maxVal: maxVal, width: w, height: h)
                    .stroke(Color.red.opacity(0.85), lineWidth: 1.2)
                
                // Green Channel Curve
                channelPath(bins: data.greenBins, maxVal: maxVal, width: w, height: h)
                    .stroke(Color.green.opacity(0.85), lineWidth: 1.2)
                
                // Blue Channel Curve
                channelPath(bins: data.blueBins, maxVal: maxVal, width: w, height: h)
                    .stroke(Color.blue.opacity(0.85), lineWidth: 1.2)
                
                // Luminance / Master Curve
                channelPath(bins: data.luminanceBins, maxVal: maxVal, width: w, height: h)
                    .stroke(Color.white, lineWidth: 1.5)
            }
        }
        .frame(width: 180, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func channelPath(bins: [Int], maxVal: Double, width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        guard bins.count == 256 else { return path }
        
        let stepX = width / 255.0
        let startY = height * (1.0 - CGFloat(min(1.0, Double(bins[0]) / maxVal)))
        path.move(to: CGPoint(x: 0, y: startY))
        
        for i in 1..<256 {
            let x = CGFloat(i) * stepX
            let normalized = min(1.0, Double(bins[i]) / maxVal)
            let y = height * (1.0 - CGFloat(normalized))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}
