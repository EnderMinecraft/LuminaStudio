import Foundation
import CoreGraphics

public enum LuminaColorSpace: String, Codable, Sendable, CaseIterable {
    case sRGB = "sRGB"
    case displayP3 = "Display P3"
    
    public var cgColorSpace: CGColorSpace {
        switch self {
        case .sRGB:
            return CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        case .displayP3:
            return CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
        }
    }
}
