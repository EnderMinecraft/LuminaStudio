import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    public static var luminaDocument: UTType {
        UTType(exportedAs: "com.lumina.studio.photo", conformingTo: .package)
    }
    public static var luminaVectorDocument: UTType {
        UTType(exportedAs: "com.lumina.studio.vector", conformingTo: .package)
    }
    public static var luminaCollageDocument: UTType {
        UTType(exportedAs: "com.lumina.studio.collage", conformingTo: .package)
    }
}

public struct LuminaFileDocument: FileDocument {
    public static var readableContentTypes: [UTType] {
        [.luminaDocument]
    }
    
    public var document: LuminaDocument
    
    public init(document: LuminaDocument = LuminaDocument()) {
        self.document = document
    }
    
    public init(configuration: ReadConfiguration) throws {
        guard let fileWrapper = configuration.file.fileWrappers != nil ? configuration.file : nil else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.document = try DocumentPackage.decode(from: fileWrapper)
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try DocumentPackage.encode(document: document)
    }
}
