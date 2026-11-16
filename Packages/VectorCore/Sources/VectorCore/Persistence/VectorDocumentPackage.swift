import Foundation
import CoreGraphics

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

public final class VectorDocumentPackage: @unchecked Sendable {
    public static let shared = VectorDocumentPackage()
    
    public struct Manifest: Codable, Sendable {
        public var appVersion: String
        public var documentType: String
        public var title: String
        public var createdAt: Date
        public var modifiedAt: Date
        
        public init(
            appVersion: String = "1.0.0",
            documentType: String = "Vector",
            title: String,
            createdAt: Date = Date(),
            modifiedAt: Date = Date()
        ) {
            self.appVersion = appVersion
            self.documentType = documentType
            self.title = title
            self.createdAt = createdAt
            self.modifiedAt = modifiedAt
        }
    }
    
    public init() {}
    
    public func encodePackage(document: VectorDocument) throws -> [String: Data] {
        var files: [String: Data] = [:]
        
        // 1. Manifest
        let manifest = Manifest(title: document.title, createdAt: document.createdAt, modifiedAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        files["manifest.json"] = try encoder.encode(manifest)
        
        // 2. Document JSON
        files["document.json"] = try encoder.encode(document)
        
        // 3. Optional SVG export preview
        let svg = VectorInterchange.shared.exportSVG(document: document)
        if let svgData = svg.data(using: .utf8) {
            files["preview.svg"] = svgData
        }
        
        return files
    }
    
    public func decodePackage(files: [String: Data]) throws -> VectorDocument {
        guard let docData = files["document.json"] else {
            throw NSError(domain: "VectorDocumentPackage", code: 404, userInfo: [NSLocalizedDescriptionKey: "Missing document.json in .luminavec package"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(VectorDocument.self, from: docData)
    }
}
