import Foundation

public struct PackageManifest: Codable, Sendable {
    public var version: Int
    public var appName: String
    public var documentType: String
    public var title: String
    public var width: Int
    public var height: Int
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        version: Int = 1,
        appName: String = "Lumina Studio",
        documentType: String = "photo",
        title: String,
        width: Int,
        height: Int,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.version = version
        self.appName = appName
        self.documentType = documentType
        self.title = title
        self.width = width
        self.height = height
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

public final class DocumentPackage: Sendable {
    public static let manifestFilename = "manifest.json"
    public static let documentFilename = "document.json"
    public static let assetsDirectoryName = "assets"
    
    public static func encode(document: LuminaDocument) throws -> FileWrapper {
        let manifest = PackageManifest(
            title: document.title,
            width: document.configuration.width,
            height: document.configuration.height,
            createdAt: document.createdAt,
            modifiedAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let manifestData = try encoder.encode(manifest)
        let documentData = try encoder.encode(document)
        
        var packageWrappers: [String: FileWrapper] = [
            manifestFilename: FileWrapper(regularFileWithContents: manifestData),
            documentFilename: FileWrapper(regularFileWithContents: documentData)
        ]
        
        // Encode layer assets if any
        var assetWrappers: [String: FileWrapper] = [:]
        for layer in document.layers {
            if let pixelData = layer.rawPixelData {
                let assetFilename = "\(layer.id.uuidString).raw"
                assetWrappers[assetFilename] = FileWrapper(regularFileWithContents: pixelData)
            }
            if let mask = layer.mask {
                let maskFilename = "\(mask.id.uuidString).mask"
                assetWrappers[maskFilename] = FileWrapper(regularFileWithContents: mask.maskData)
            }
        }
        
        let assetsDir = FileWrapper(directoryWithFileWrappers: assetWrappers)
        packageWrappers[assetsDirectoryName] = assetsDir
        
        return FileWrapper(directoryWithFileWrappers: packageWrappers)
    }
    
    public static func decode(from fileWrapper: FileWrapper) throws -> LuminaDocument {
        guard let wrappers = fileWrapper.fileWrappers,
              let docWrapper = wrappers[documentFilename],
              let docData = docWrapper.regularFileContents else {
            throw NSError(
                domain: "LuminaPackage",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid package: missing \(documentFilename)"]
            )
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(LuminaDocument.self, from: docData)
        
        // Attach raw asset bytes if assets directory exists
        if let assetsWrapper = wrappers[assetsDirectoryName],
           let assetFiles = assetsWrapper.fileWrappers {
            for layer in document.layers {
                let assetFilename = "\(layer.id.uuidString).raw"
                if let rawFile = assetFiles[assetFilename], let rawBytes = rawFile.regularFileContents {
                    layer.rawPixelData = rawBytes
                }
                if let mask = layer.mask {
                    let maskFilename = "\(mask.id.uuidString).mask"
                    if let maskFile = assetFiles[maskFilename], let maskBytes = maskFile.regularFileContents {
                        mask.maskData = maskBytes
                    }
                }
            }
        }
        
        return document
    }
}
