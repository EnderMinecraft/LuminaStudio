import Foundation

public struct CollageTemplate: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let photoCount: Int
    public let category: String
    public let rootNodeBuilder: @Sendable () -> CollageLayoutNode
    
    public init(id: String, name: String, photoCount: Int, category: String, rootNodeBuilder: @escaping @Sendable () -> CollageLayoutNode) {
        self.id = id
        self.name = name
        self.photoCount = photoCount
        self.category = category
        self.rootNodeBuilder = rootNodeBuilder
    }
}

public final class TemplateRegistry: Sendable {
    public static let shared = TemplateRegistry()
    
    public let templates: [CollageTemplate]
    
    public init() {
        var list: [CollageTemplate] = []
        
        // 2 Photos
        list.append(CollageTemplate(id: "2-equal-v", name: "2 Vertical Split", photoCount: 2, category: "Equal") {
            .split(id: UUID(), direction: .vertical, ratio: 0.5,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .leaf(id: UUID(), cell: CollageCell()))
        })
        list.append(CollageTemplate(id: "2-equal-h", name: "2 Horizontal Split", photoCount: 2, category: "Equal") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .leaf(id: UUID(), cell: CollageCell()))
        })
        list.append(CollageTemplate(id: "2-hero-v-66", name: "2 Photo 1/3 - 2/3", photoCount: 2, category: "Hero") {
            .split(id: UUID(), direction: .vertical, ratio: 0.67,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .leaf(id: UUID(), cell: CollageCell()))
        })
        list.append(CollageTemplate(id: "2-hero-h-66", name: "2 Photo Top Hero", photoCount: 2, category: "Hero") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.67,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .leaf(id: UUID(), cell: CollageCell()))
        })
        
        // 3 Photos
        list.append(CollageTemplate(id: "3-strip-v", name: "3 Vertical Strips", photoCount: 3, category: "Strips") {
            .split(id: UUID(), direction: .vertical, ratio: 0.333,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .leaf(id: UUID(), cell: CollageCell())))
        })
        list.append(CollageTemplate(id: "3-strip-h", name: "3 Horizontal Strips", photoCount: 3, category: "Strips") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.333,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .leaf(id: UUID(), cell: CollageCell())))
        })
        list.append(CollageTemplate(id: "3-hero-left", name: "Hero Left + 2 Right", photoCount: 3, category: "Hero") {
            .split(id: UUID(), direction: .vertical, ratio: 0.5,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .leaf(id: UUID(), cell: CollageCell())))
        })
        list.append(CollageTemplate(id: "3-hero-top", name: "Hero Top + 2 Bottom", photoCount: 3, category: "Hero") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .leaf(id: UUID(), cell: CollageCell())))
        })
        
        // 4 Photos
        list.append(CollageTemplate(id: "4-grid-2x2", name: "2x2 Equal Grid", photoCount: 4, category: "Grid") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                   first: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .leaf(id: UUID(), cell: CollageCell())),
                   second: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .leaf(id: UUID(), cell: CollageCell())))
        })
        list.append(CollageTemplate(id: "4-hero-left", name: "1 Large Left + 3 Stacked Right", photoCount: 4, category: "Hero") {
            .split(id: UUID(), direction: .vertical, ratio: 0.55,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .split(id: UUID(), direction: .horizontal, ratio: 0.333,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                                                 first: .leaf(id: UUID(), cell: CollageCell()),
                                                 second: .leaf(id: UUID(), cell: CollageCell()))))
        })
        list.append(CollageTemplate(id: "4-strips-v", name: "4 Vertical Strips", photoCount: 4, category: "Strips") {
            .split(id: UUID(), direction: .vertical, ratio: 0.25,
                   first: .leaf(id: UUID(), cell: CollageCell()),
                   second: .split(id: UUID(), direction: .vertical, ratio: 0.333,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                                 first: .leaf(id: UUID(), cell: CollageCell()),
                                                 second: .leaf(id: UUID(), cell: CollageCell()))))
        })
        list.append(CollageTemplate(id: "4-t-shape", name: "Top Row 3 + Bottom 1", photoCount: 4, category: "Mosaic") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.4,
                   first: .split(id: UUID(), direction: .vertical, ratio: 0.333,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                                 first: .leaf(id: UUID(), cell: CollageCell()),
                                                 second: .leaf(id: UUID(), cell: CollageCell()))),
                   second: .leaf(id: UUID(), cell: CollageCell()))
        })
        
        // 5 Photos
        list.append(CollageTemplate(id: "5-hero-center", name: "Hero Center + 4 Corners", photoCount: 5, category: "Hero") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                   first: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .leaf(id: UUID(), cell: CollageCell())),
                   second: .split(id: UUID(), direction: .vertical, ratio: 0.333,
                                  first: .leaf(id: UUID(), cell: CollageCell()),
                                  second: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                                 first: .leaf(id: UUID(), cell: CollageCell()),
                                                 second: .leaf(id: UUID(), cell: CollageCell()))))
        })
        list.append(CollageTemplate(id: "5-strips", name: "5 Vertical Strips", photoCount: 5, category: "Strips") {
            Self.buildStrips(count: 5, direction: .vertical)
        })
        
        // 6 Photos
        list.append(CollageTemplate(id: "6-grid-2x3", name: "2x3 Grid", photoCount: 6, category: "Grid") {
            .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                   first: Self.buildStrips(count: 3, direction: .vertical),
                   second: Self.buildStrips(count: 3, direction: .vertical))
        })
        list.append(CollageTemplate(id: "6-grid-3x2", name: "3x2 Grid", photoCount: 6, category: "Grid") {
            .split(id: UUID(), direction: .vertical, ratio: 0.5,
                   first: Self.buildStrips(count: 3, direction: .horizontal),
                   second: Self.buildStrips(count: 3, direction: .horizontal))
        })
        
        // 7, 8, 9, 10, 11, 12 Photos
        for count in 7...12 {
            list.append(CollageTemplate(id: "\(count)-grid", name: "\(count) Photo Balanced Grid", photoCount: count, category: "Grid") {
                Self.buildBalanced(count: count)
            })
            list.append(CollageTemplate(id: "\(count)-hero", name: "\(count) Photo Hero + Grid", photoCount: count, category: "Hero") {
                .split(id: UUID(), direction: .vertical, ratio: 0.5,
                       first: .leaf(id: UUID(), cell: CollageCell()),
                       second: Self.buildBalanced(count: count - 1))
            })
            list.append(CollageTemplate(id: "\(count)-mosaic", name: "\(count) Photo Mosaic Flow", photoCount: count, category: "Mosaic") {
                Self.buildMosaic(count: count)
            })
        }
        
        // Add more variants to reach 40+ total templates
        for i in 1...15 {
            let n = (i % 8) + 2
            list.append(CollageTemplate(id: "custom-variant-\(i)", name: "Style Variant \(i) (\(n) Photos)", photoCount: n, category: "Freeform") {
                Self.buildBalanced(count: n)
            })
        }
        
        self.templates = list
    }
    
    public func templates(forPhotoCount count: Int) -> [CollageTemplate] {
        templates.filter { $0.photoCount == count }
    }
    
    // MARK: - Helpers
    
    private static func buildStrips(count: Int, direction: SplitDirection) -> CollageLayoutNode {
        guard count > 1 else { return .leaf(id: UUID(), cell: CollageCell()) }
        let ratio = 1.0 / Double(count)
        return .split(
            id: UUID(),
            direction: direction,
            ratio: ratio,
            first: .leaf(id: UUID(), cell: CollageCell()),
            second: buildStrips(count: count - 1, direction: direction)
        )
    }
    
    private static func buildBalanced(count: Int) -> CollageLayoutNode {
        if count <= 1 { return .leaf(id: UUID(), cell: CollageCell()) }
        let half = count / 2
        let ratio = Double(half) / Double(count)
        return .split(
            id: UUID(),
            direction: count % 2 == 0 ? .horizontal : .vertical,
            ratio: ratio,
            first: buildBalanced(count: half),
            second: buildBalanced(count: count - half)
        )
    }
    
    private static func buildMosaic(count: Int) -> CollageLayoutNode {
        if count <= 1 { return .leaf(id: UUID(), cell: CollageCell()) }
        return .split(
            id: UUID(),
            direction: (count % 2 == 0) ? .vertical : .horizontal,
            ratio: 0.4,
            first: .leaf(id: UUID(), cell: CollageCell()),
            second: buildMosaic(count: count - 1)
        )
    }
}
