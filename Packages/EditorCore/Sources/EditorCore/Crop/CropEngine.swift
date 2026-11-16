import Foundation
import CoreGraphics

public enum CropAspectRatio: String, CaseIterable, Sendable {
    case free = "Free"
    case square = "1:1"
    case portrait4_5 = "4:5"
    case portrait3_4 = "3:4"
    case landscape16_9 = "16:9"
    case portrait9_16 = "9:16"
    case classic2_3 = "2:3"
    
    public var ratio: Double? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .portrait4_5: return 4.0 / 5.0
        case .portrait3_4: return 3.0 / 4.0
        case .landscape16_9: return 16.0 / 9.0
        case .portrait9_16: return 9.0 / 16.0
        case .classic2_3: return 2.0 / 3.0
        }
    }
}

public struct CropConfiguration: Sendable, Equatable {
    public var cropRect: CGRect
    public var aspectRatio: CropAspectRatio
    public var straightenRadians: Double // -pi/4 to +pi/4
    
    public init(
        cropRect: CGRect,
        aspectRatio: CropAspectRatio = .free,
        straightenRadians: Double = 0.0
    ) {
        self.cropRect = cropRect
        self.aspectRatio = aspectRatio
        self.straightenRadians = straightenRadians
    }
    
    /// Generates rule-of-thirds grid line segments inside cropRect
    public var ruleOfThirdsLines: (verticals: (CGFloat, CGFloat), horizontals: (CGFloat, CGFloat)) {
        let v1 = cropRect.minX + cropRect.width / 3.0
        let v2 = cropRect.minX + (cropRect.width * 2.0) / 3.0
        let h1 = cropRect.minY + cropRect.height / 3.0
        let h2 = cropRect.minY + (cropRect.height * 2.0) / 3.0
        return ((v1, v2), (h1, h2))
    }
}

public final class CropEngine: Sendable {
    public static let shared = CropEngine()
    
    public init() {}
    
    /// Crops document to the specified cropRect, updating canvas dimensions and offsetting layers
    public func applyCrop(to document: LuminaDocument, cropRect: CGRect) {
        let newWidth = max(16, Int(round(cropRect.width)))
        let newHeight = max(16, Int(round(cropRect.height)))
        let originX = Int(round(cropRect.origin.x))
        let originY = Int(round(cropRect.origin.y))
        
        document.configuration.width = newWidth
        document.configuration.height = newHeight
        
        for layer in document.layers {
            // Translate layer transform so it stays aligned relative to the new origin
            layer.transform.translation.x -= CGFloat(originX)
            layer.transform.translation.y -= CGFloat(originY)
            
            // If the layer is a background or has full-size pixel buffer, crop its raw bytes
            if let pixelData = layer.rawPixelData, layer.pixelWidth > 0, layer.pixelHeight > 0 {
                let oldW = layer.pixelWidth
                let oldH = layer.pixelHeight
                var croppedBuffer = [UInt8](repeating: 0, count: newWidth * newHeight * 4)
                
                pixelData.withUnsafeBytes { srcPtr in
                    guard let src = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                    for y in 0..<newHeight {
                        let srcY = originY + y
                        guard srcY >= 0, srcY < oldH else { continue }
                        for x in 0..<newWidth {
                            let srcX = originX + x
                            guard srcX >= 0, srcX < oldW else { continue }
                            let srcIndex = (srcY * oldW + srcX) * 4
                            let dstIndex = (y * newWidth + x) * 4
                            croppedBuffer[dstIndex] = src[srcIndex]
                            croppedBuffer[dstIndex + 1] = src[srcIndex + 1]
                            croppedBuffer[dstIndex + 2] = src[srcIndex + 2]
                            croppedBuffer[dstIndex + 3] = src[srcIndex + 3]
                        }
                    }
                }
                
                layer.rawPixelData = Data(croppedBuffer)
                layer.pixelWidth = newWidth
                layer.pixelHeight = newHeight
            }
        }
    }
}

public final class CropDocumentCommand: Command, @unchecked Sendable {
    public let name: String = "Crop Canvas"
    public let estimatedMemoryBytes: Int
    private let document: LuminaDocument
    private let newCropRect: CGRect
    private let oldWidth: Int
    private let oldHeight: Int
    private var previousLayerStates: [(id: UUID, transform: Transform2D, pixelData: Data?, w: Int, h: Int)] = []
    
    public init(document: LuminaDocument, cropRect: CGRect) {
        self.document = document
        self.newCropRect = cropRect
        self.oldWidth = document.configuration.width
        self.oldHeight = document.configuration.height
        self.estimatedMemoryBytes = document.configuration.width * document.configuration.height * 4
    }
    
    public func execute() async throws {
        previousLayerStates = document.layers.map {
            ($0.id, $0.transform, $0.rawPixelData, $0.pixelWidth, $0.pixelHeight)
        }
        CropEngine.shared.applyCrop(to: document, cropRect: newCropRect)
    }
    
    public func undo() async throws {
        document.configuration.width = oldWidth
        document.configuration.height = oldHeight
        for state in previousLayerStates {
            if let layer = document.findLayer(byID: state.id) {
                layer.transform = state.transform
                layer.rawPixelData = state.pixelData
                layer.pixelWidth = state.w
                layer.pixelHeight = state.h
            }
        }
    }
}
