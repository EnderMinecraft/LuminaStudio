import XCTest
@testable import EditorCore

final class CommandTests: XCTestCase {
    func testAddAndUndoLayerCommand() async throws {
        let doc = LuminaDocument(title: "CmdDoc")
        let manager = CommandManager()
        
        let initialCount = doc.layers.count
        let newLayer = Layer(name: "Added Layer")
        let addCmd = AddLayerCommand(document: doc, layer: newLayer)
        
        try await manager.execute(addCmd)
        XCTAssertEqual(doc.layers.count, initialCount + 1)
        XCTAssertTrue(manager.canUndo)
        XCTAssertFalse(manager.canRedo)
        
        try await manager.undo()
        XCTAssertEqual(doc.layers.count, initialCount)
        XCTAssertFalse(manager.canUndo)
        XCTAssertTrue(manager.canRedo)
        
        try await manager.redo()
        XCTAssertEqual(doc.layers.count, initialCount + 1)
        XCTAssertTrue(manager.canUndo)
        XCTAssertFalse(manager.canRedo)
    }
    
    func testOpacityCommandUndoRedo() async throws {
        let layer = Layer(name: "Test", opacity: 1.0)
        let manager = CommandManager()
        
        let cmd = SetOpacityCommand(layer: layer, newOpacity: 0.4)
        try await manager.execute(cmd)
        XCTAssertEqual(layer.opacity, 0.4)
        
        try await manager.undo()
        XCTAssertEqual(layer.opacity, 1.0)
        
        try await manager.redo()
        XCTAssertEqual(layer.opacity, 0.4)
    }
    
    func testHistoryEntriesInspection() async throws {
        let doc = LuminaDocument(title: "Inspection")
        let manager = CommandManager()
        
        let l1 = Layer(name: "L1")
        let l2 = Layer(name: "L2")
        
        try await manager.execute(AddLayerCommand(document: doc, layer: l1))
        try await manager.execute(AddLayerCommand(document: doc, layer: l2))
        
        let entries = manager.historyEntries()
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.last?.isCurrent ?? false)
        
        try await manager.undo()
        let entriesAfterUndo = manager.historyEntries()
        XCTAssertEqual(entriesAfterUndo.count, 2)
        XCTAssertTrue(entriesAfterUndo.first?.isCurrent ?? false)
    }
}
