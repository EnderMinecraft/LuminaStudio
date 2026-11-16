import XCTest
@testable import EditorCore

final class LayerStackTests: XCTestCase {
    func testDocumentCreationWithDefaultBackground() {
        let config = CanvasConfiguration(width: 1024, height: 768, dpi: 300, backgroundColor: .white)
        let doc = LuminaDocument(title: "TestDoc", configuration: config)
        
        XCTAssertEqual(doc.layers.count, 1)
        XCTAssertEqual(doc.layers.first?.name, "Background")
        XCTAssertEqual(doc.layers.first?.opacity, 1.0)
        XCTAssertEqual(doc.activeLayerID, doc.layers.first?.id)
        XCTAssertEqual(doc.layers.first?.pixelWidth, 1024)
        XCTAssertEqual(doc.layers.first?.pixelHeight, 768)
    }
    
    func testAddAndRemoveLayers() {
        let doc = LuminaDocument(title: "TestDoc")
        let layer1 = Layer(name: "Layer 1")
        let layer2 = Layer(name: "Layer 2")
        
        doc.addLayer(layer1)
        XCTAssertEqual(doc.layers.count, 2)
        XCTAssertEqual(doc.activeLayerID, layer1.id)
        
        doc.addLayer(layer2)
        XCTAssertEqual(doc.layers.count, 3)
        XCTAssertEqual(doc.activeLayerID, layer2.id)
        
        let removed = doc.removeLayer(byID: layer1.id)
        XCTAssertEqual(removed?.id, layer1.id)
        XCTAssertEqual(doc.layers.count, 2)
        XCTAssertNil(doc.findLayer(byID: layer1.id))
    }
    
    func testDuplicateLayer() {
        let doc = LuminaDocument(title: "TestDoc")
        let layer = Layer(name: "Original", opacity: 0.8, blendMode: .multiply)
        doc.addLayer(layer)
        
        let copy = doc.duplicateLayer(byID: layer.id)
        XCTAssertNotNil(copy)
        XCTAssertEqual(doc.layers.count, 3)
        XCTAssertEqual(copy?.name, "Original Copy")
        XCTAssertEqual(copy?.opacity, 0.8)
        XCTAssertEqual(copy?.blendMode, .multiply)
        XCTAssertNotEqual(copy?.id, layer.id)
    }
    
    func testReorderLayers() {
        let doc = LuminaDocument(title: "TestDoc")
        let l1 = Layer(name: "L1")
        let l2 = Layer(name: "L2")
        doc.addLayer(l1)
        doc.addLayer(l2)
        
        // Initial order: Background (0), L1 (1), L2 (2)
        XCTAssertEqual(doc.layers.map { $0.name }, ["Background", "L1", "L2"])
        
        // Move L2 to index 1
        doc.moveLayer(from: 2, to: 1)
        XCTAssertEqual(doc.layers.map { $0.name }, ["Background", "L2", "L1"])
    }
}
