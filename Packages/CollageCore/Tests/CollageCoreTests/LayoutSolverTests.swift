import XCTest
import CoreGraphics
@testable import CollageCore

final class LayoutSolverTests: XCTestCase {
    func testTemplateRegistryCount() {
        let registry = TemplateRegistry.shared
        XCTAssertGreaterThanOrEqual(registry.templates.count, 40)
    }
    
    func testTwoByTwoGridSolving() {
        guard let template = TemplateRegistry.shared.templates.first(where: { $0.id == "4-grid-2x2" }) else {
            XCTFail("Missing 4-grid-2x2 template")
            return
        }
        
        let rootNode = template.rootNodeBuilder()
        let solver = BSPLayoutSolver.shared
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 800)
        let spacing: CGFloat = 10.0
        let margin: CGFloat = 20.0
        
        let (cells, dividers) = solver.solve(node: rootNode, in: bounds, spacing: spacing, margin: margin)
        
        XCTAssertEqual(cells.count, 4)
        XCTAssertEqual(dividers.count, 3)
        
        // Content area = 800 - 40 = 760. Width of each cell = (760 - 10) / 2 = 375.
        for cell in cells {
            XCTAssertEqual(cell.rect.width, 375.0, accuracy: 1e-3)
            XCTAssertEqual(cell.rect.height, 375.0, accuracy: 1e-3)
        }
    }
}
