import XCTest
@testable import EditorCore

final class SerializationTests: XCTestCase {
    func testDocumentPackageRoundTrip() throws {
        let config = CanvasConfiguration(width: 800, height: 600, dpi: 150, colorSpace: .sRGB, backgroundColor: .black)
        let doc = LuminaDocument(title: "Serialized Doc", configuration: config)
        
        let customLayer = Layer(
            name: "Accent Layer",
            opacity: 0.75,
            blendMode: .screen,
            isVisible: true,
            isLocked: false
        )
        customLayer.rawPixelData = Data([255, 128, 64, 255, 0, 128, 255, 255])
        customLayer.pixelWidth = 2
        customLayer.pixelHeight = 1
        
        let mask = LayerMask(width: 2, height: 1, initialValue: 200)
        customLayer.mask = mask
        
        doc.addLayer(customLayer)
        
        // Encode
        let fileWrapper = try DocumentPackage.encode(document: doc)
        XCTAssertNotNil(fileWrapper.fileWrappers?[DocumentPackage.manifestFilename])
        XCTAssertNotNil(fileWrapper.fileWrappers?[DocumentPackage.documentFilename])
        XCTAssertNotNil(fileWrapper.fileWrappers?[DocumentPackage.assetsDirectoryName])
        
        // Decode
        let decodedDoc = try DocumentPackage.decode(from: fileWrapper)
        XCTAssertEqual(decodedDoc.title, "Serialized Doc")
        XCTAssertEqual(decodedDoc.configuration.width, 800)
        XCTAssertEqual(decodedDoc.configuration.height, 600)
        XCTAssertEqual(decodedDoc.configuration.colorSpace, .sRGB)
        XCTAssertEqual(decodedDoc.layers.count, doc.layers.count)
        
        let decodedLayer = decodedDoc.layers.first(where: { $0.name == "Accent Layer" })
        XCTAssertNotNil(decodedLayer)
        XCTAssertEqual(decodedLayer?.opacity, 0.75)
        XCTAssertEqual(decodedLayer?.blendMode, .screen)
        XCTAssertEqual(decodedLayer?.rawPixelData, customLayer.rawPixelData)
        XCTAssertEqual(decodedLayer?.mask?.maskData, mask.maskData)
    }
}
