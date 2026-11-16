import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

public enum ExportFormat: String, Codable, Sendable, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case heic = "HEIC"
    
    public var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .heic: return .heic
        }
    }
    
    public var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .heic: return "heic"
        }
    }
}

public struct ExportConfiguration: Sendable {
    public var format: ExportFormat
    public var jpegQuality: Double // 0.1 to 1.0
    public var scale: Double // 1.0, 2.0, etc.
    public var includeMetadata: Bool
    
    public init(
        format: ExportFormat = .png,
        jpegQuality: Double = 0.9,
        scale: Double = 1.0,
        includeMetadata: Bool = true
    ) {
        self.format = format
        self.jpegQuality = max(0.05, min(1.0, jpegQuality))
        self.scale = max(0.1, min(4.0, scale))
        self.includeMetadata = includeMetadata
    }
}

public final class ExportEngine: Sendable {
    private let compositor: TiledCanvasCompositor
    
    public init(compositor: TiledCanvasCompositor = TiledCanvasCompositor()) {
        self.compositor = compositor
    }
    
    public func export(document: LuminaDocument, configuration: ExportConfiguration) throws -> Data {
        guard let cgImage = compositor.renderCGImage(document: document) else {
            throw NSError(domain: "LuminaExport", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to render document image"])
        }
        
        return try exportCGImage(cgImage, configuration: configuration, colorSpace: document.configuration.colorSpace)
    }
    
    public func exportCGImage(_ image: CGImage, configuration: ExportConfiguration, colorSpace: LuminaColorSpace) throws -> Data {
        let outputData = NSMutableData()
        let uti = configuration.format.utType.identifier as CFString
        
        guard let destination = CGImageDestinationCreateWithData(outputData, uti, 1, nil) else {
            throw NSError(domain: "LuminaExport", code: 501, userInfo: [NSLocalizedDescriptionKey: "Cannot create image destination for \(configuration.format.rawValue)"])
        }
        
        var options: [CFString: Any] = [:]
        if configuration.format == .jpeg {
            options[kCGImageDestinationLossyFactor] = configuration.jpegQuality
        }
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "LuminaExport", code: 502, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize image destination"])
        }
        
        return outputData as Data
    }
}
