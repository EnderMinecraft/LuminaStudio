import Foundation
import CoreGraphics

public final class LayerMask: Codable, @unchecked Sendable, Equatable {
    public var id: UUID
    public var isEnabled: Bool
    public var isInverted: Bool
    public var width: Int
    public var height: Int
    public var maskData: Data // 8-bit unorm grayscale buffer (width * height bytes)
    
    public init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        isInverted: Bool = false,
        width: Int,
        height: Int,
        initialValue: UInt8 = 255
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.isInverted = isInverted
        self.width = width
        self.height = height
        self.maskData = Data(repeating: initialValue, count: width * height)
    }
    
    public static func == (lhs: LayerMask, rhs: LayerMask) -> Bool {
        lhs.id == rhs.id &&
        lhs.isEnabled == rhs.isEnabled &&
        lhs.isInverted == rhs.isInverted &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.maskData == rhs.maskData
    }
    
    public func sample(x: Int, y: Int) -> UInt8 {
        guard x >= 0, x < width, y >= 0, y < height else { return 0 }
        let index = y * width + x
        guard index < maskData.count else { return 0 }
        let val = maskData[index]
        return isInverted ? (255 - val) : val
    }
    
    public func setSample(x: Int, y: Int, value: UInt8) {
        guard x >= 0, x < width, y >= 0, y < height else { return }
        let index = y * width + x
        guard index < maskData.count else { return }
        maskData[index] = isInverted ? (255 - value) : value
    }
}
