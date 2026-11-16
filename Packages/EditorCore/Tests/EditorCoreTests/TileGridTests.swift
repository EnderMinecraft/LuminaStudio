import XCTest
import CoreGraphics
@testable import EditorCore

final class TileGridTests: XCTestCase {
    func testTileGridDimensions() {
        let grid = TileGrid(canvasWidth: 1024, canvasHeight: 768, tileSize: 256)
        XCTAssertEqual(grid.columns, 4) // 1024 / 256 = 4
        XCTAssertEqual(grid.rows, 3)    // 768 / 256 = 3
        XCTAssertEqual(grid.totalTiles, 12)
    }
    
    func testNonMultipleTileGridDimensions() {
        let grid = TileGrid(canvasWidth: 1000, canvasHeight: 600, tileSize: 256)
        XCTAssertEqual(grid.columns, 4) // ceil(1000 / 256) = 4
        XCTAssertEqual(grid.rows, 3)    // ceil(600 / 256) = 3
        XCTAssertEqual(grid.totalTiles, 12)
    }
    
    func testMaxCanvasGrid() {
        let grid = TileGrid(canvasWidth: 8192, canvasHeight: 8192, tileSize: 256)
        XCTAssertEqual(grid.columns, 32)
        XCTAssertEqual(grid.rows, 32)
        XCTAssertEqual(grid.totalTiles, 1024)
    }
    
    func testTileIntersection() {
        let grid = TileGrid(canvasWidth: 1024, canvasHeight: 1024, tileSize: 256)
        // Rect inside top-left tile
        let rect1 = CGRect(x: 10, y: 10, width: 50, height: 50)
        let tiles1 = grid.tiles(intersecting: rect1)
        XCTAssertEqual(tiles1.count, 1)
        XCTAssertEqual(tiles1.first?.x, 0)
        XCTAssertEqual(tiles1.first?.y, 0)
        
        // Rect spanning boundary between tile (0,0), (1,0), (0,1), (1,1)
        let rect2 = CGRect(x: 250, y: 250, width: 20, height: 20)
        let tiles2 = grid.tiles(intersecting: rect2)
        XCTAssertEqual(tiles2.count, 4)
    }
    
    func testTileCoordinateClampedRect() {
        let coord = TileCoordinate(x: 3, y: 2, tileSize: 256)
        let rect = coord.clampedRect(canvasWidth: 1000, canvasHeight: 700)
        // x: 3 * 256 = 768. 768 + 256 = 1024 > 1000, so width should be 1000 - 768 = 232.
        XCTAssertEqual(rect.minX, 768)
        XCTAssertEqual(rect.width, 232)
        // y: 2 * 256 = 512. 512 + 256 = 768 > 700, so height should be 700 - 512 = 188.
        XCTAssertEqual(rect.minY, 512)
        XCTAssertEqual(rect.height, 188)
    }
}
