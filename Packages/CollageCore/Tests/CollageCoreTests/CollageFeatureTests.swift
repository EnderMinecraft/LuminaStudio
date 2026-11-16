import XCTest
import CoreGraphics
@testable import CollageCore

final class CollageFeatureTests: XCTestCase {
    func testMagneticDividerSnapping() {
        let root: CollageLayoutNode = .split(
            id: UUID(),
            direction: .vertical,
            ratio: 0.5,
            first: .leaf(id: UUID(), cell: CollageCell()),
            second: .leaf(id: UUID(), cell: CollageCell())
        )
        let splitID = root.id
        
        // Target ratio 0.51 is within snap threshold (0.025) of 0.5
        let (_, snappedRatio, didSnap) = CollageDividerEngine.shared.updateRatio(
            in: root,
            splitID: splitID,
            newRatio: 0.51,
            enableSnapping: true
        )
        
        XCTAssertTrue(didSnap)
        XCTAssertEqual(snappedRatio, 0.5, accuracy: 1e-4)
    }
    
    func testCellRotationAndFlipping() {
        let cellID = UUID()
        var root: CollageLayoutNode = .leaf(id: cellID, cell: CollageCell(id: cellID))
        
        // Rotate 90 deg twice
        root = CollageCellEngine.shared.rotateCell90Degrees(in: root, cellID: cellID)
        root = CollageCellEngine.shared.rotateCell90Degrees(in: root, cellID: cellID)
        XCTAssertEqual(root.allCells().first?.rotationQuarterTurns, 2)
        
        // Flip horizontal
        root = CollageCellEngine.shared.flipCell(in: root, cellID: cellID, horizontal: true)
        XCTAssertTrue(root.allCells().first?.isFlippedHorizontally == true)
    }
    
    func testCellSwapping() {
        let idA = UUID()
        let idB = UUID()
        let cellA = CollageCell(id: idA, assetID: "photo-1")
        let cellB = CollageCell(id: idB, assetID: "photo-2")
        
        let root: CollageLayoutNode = .split(
            id: UUID(),
            direction: .horizontal,
            ratio: 0.5,
            first: .leaf(id: idA, cell: cellA),
            second: .leaf(id: idB, cell: cellB)
        )
        
        let swapped = CollageCellEngine.shared.swapCells(in: root, idA: idA, idB: idB)
        let all = swapped.allCells()
        
        let newA = all.first(where: { $0.id == idA })
        let newB = all.first(where: { $0.id == idB })
        
        XCTAssertEqual(newA?.assetID, "photo-2")
        XCTAssertEqual(newB?.assetID, "photo-1")
    }
    
    func testCollageRasterization() {
        let doc = CollageDocument(aspectRatioPreset: .square)
        let (buf, size) = CollageRenderEngine.shared.renderCollage(document: doc, baseDimension: 512)
        
        XCTAssertEqual(size.width, 512)
        XCTAssertEqual(size.height, 512)
        XCTAssertEqual(buf.count, 512 * 512 * 4)
    }
    
    func testAll40TemplatesSolvable() {
        let templates = TemplateRegistry.shared.templates
        XCTAssertGreaterThanOrEqual(templates.count, 40)
        
        let testBounds = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let solver = BSPLayoutSolver.shared
        
        for template in templates {
            let root = template.rootNodeBuilder()
            let (cells, _) = solver.solve(node: root, in: testBounds, spacing: 8, margin: 16)
            
            XCTAssertEqual(cells.count, template.photoCount, "Template \(template.id) photo count mismatch")
            for cell in cells {
                XCTAssertGreaterThan(cell.rect.width, 0, "Cell in \(template.id) has non-positive width")
                XCTAssertGreaterThan(cell.rect.height, 0, "Cell in \(template.id) has non-positive height")
            }
        }
    }
}
