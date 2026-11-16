import Foundation
import CoreGraphics

public enum AspectRatioPreset: String, Codable, Sendable, CaseIterable {
    case square = "1:1"
    case portrait4_5 = "4:5"
    case portrait3_4 = "3:4"
    case story9_16 = "9:16"
    case landscape16_9 = "16:9"
    case classic2_3 = "2:3"
    case a4 = "A4"
    
    public var ratio: Double {
        switch self {
        case .square: return 1.0
        case .portrait4_5: return 4.0 / 5.0
        case .portrait3_4: return 3.0 / 4.0
        case .story9_16: return 9.0 / 16.0
        case .landscape16_9: return 16.0 / 9.0
        case .classic2_3: return 2.0 / 3.0
        case .a4: return 1.0 / 1.4142
        }
    }
    
    public func targetSize(longEdge: CGFloat = 2048) -> CGSize {
        let r = CGFloat(ratio)
        if r >= 1.0 {
            return CGSize(width: longEdge, height: longEdge / r)
        } else {
            return CGSize(width: longEdge * r, height: longEdge)
        }
    }
}
