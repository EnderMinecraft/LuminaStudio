import Foundation
import CoreGraphics

public enum CutoutOverlayMode: Sendable, Equatable {
    case fadedOriginal(removedOpacity: Double) // Default 25%, adjustable 0-60%
    case redTint                              // Quick-mask ruby overlay
    case checkerboard                         // Standard transparency grid
    case solidColor(r: Double, g: Double, b: Double) // User-picked matte
    case maskOnly                             // Grayscale alpha visualization
    case original                             // Full unmasked preview
    
    public var id: String {
        switch self {
        case .fadedOriginal: return "fadedOriginal"
        case .redTint: return "redTint"
        case .checkerboard: return "checkerboard"
        case .solidColor: return "solidColor"
        case .maskOnly: return "maskOnly"
        case .original: return "original"
        }
    }
    
    public var displayName: String {
        switch self {
        case .fadedOriginal: return "Faded"
        case .redTint: return "Red Tint"
        case .checkerboard: return "Checkerboard"
        case .solidColor: return "Solid"
        case .maskOnly: return "Mask Only"
        case .original: return "Original"
        }
    }
}
