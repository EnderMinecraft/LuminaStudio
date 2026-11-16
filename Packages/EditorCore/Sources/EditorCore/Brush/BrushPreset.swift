import Foundation
import CoreGraphics

public struct StrokePoint: Sendable, Equatable {
    public var location: CGPoint
    public var pressure: Double // 0.0 to 1.0
    public var tilt: Double     // radians
    public var timestamp: TimeInterval
    
    public init(
        location: CGPoint,
        pressure: Double = 1.0,
        tilt: Double = 0.0,
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        self.location = location
        self.pressure = max(0.01, min(1.0, pressure))
        self.tilt = tilt
        self.timestamp = timestamp
    }
}

public struct BrushPreset: Identifiable, Sendable, Equatable {
    public var id: String
    public var name: String
    public var size: CGFloat // In pixels
    public var spacing: Double // Fraction of diameter (e.g. 0.1 = 10%)
    public var hardness: Double // 0.0 (soft) to 1.0 (hard)
    public var opacity: Double // 0.0 to 1.0
    public var flow: Double    // 0.0 to 1.0
    public var sizeWithPressure: Bool
    public var opacityWithPressure: Bool
    public var isEraser: Bool
    public var isSmudge: Bool
    public var smudgeStrength: Double
    
    public init(
        id: String = UUID().uuidString,
        name: String = "Round Soft",
        size: CGFloat = 24.0,
        spacing: Double = 0.15,
        hardness: Double = 0.0,
        opacity: Double = 1.0,
        flow: Double = 1.0,
        sizeWithPressure: Bool = true,
        opacityWithPressure: Bool = true,
        isEraser: Bool = false,
        isSmudge: Bool = false,
        smudgeStrength: Double = 0.5
    ) {
        self.id = id
        self.name = name
        self.size = max(1.0, min(500.0, size))
        self.spacing = max(0.01, min(2.0, spacing))
        self.hardness = max(0.0, min(1.0, hardness))
        self.opacity = max(0.01, min(1.0, opacity))
        self.flow = max(0.01, min(1.0, flow))
        self.sizeWithPressure = sizeWithPressure
        self.opacityWithPressure = opacityWithPressure
        self.isEraser = isEraser
        self.isSmudge = isSmudge
        self.smudgeStrength = smudgeStrength
    }
    
    // Built-in Presets
    public static let roundSoft = BrushPreset(
        id: "round-soft",
        name: "Round Soft",
        size: 30.0,
        spacing: 0.12,
        hardness: 0.0,
        opacity: 1.0,
        flow: 0.8
    )
    
    public static let roundHard = BrushPreset(
        id: "round-hard",
        name: "Round Hard",
        size: 16.0,
        spacing: 0.1,
        hardness: 1.0,
        opacity: 1.0,
        flow: 1.0
    )
    
    public static let airbrush = BrushPreset(
        id: "airbrush",
        name: "Airbrush",
        size: 60.0,
        spacing: 0.05,
        hardness: 0.0,
        opacity: 0.6,
        flow: 0.3
    )
    
    public static let pencil = BrushPreset(
        id: "pencil",
        name: "Sketch Pencil",
        size: 4.0,
        spacing: 0.08,
        hardness: 0.8,
        opacity: 0.7,
        flow: 0.6
    )
    
    public static let inkPen = BrushPreset(
        id: "ink-pen",
        name: "Studio Ink",
        size: 12.0,
        spacing: 0.06,
        hardness: 0.95,
        opacity: 1.0,
        flow: 1.0
    )
    
    public static let eraser = BrushPreset(
        id: "eraser-soft",
        name: "Soft Eraser",
        size: 32.0,
        spacing: 0.1,
        hardness: 0.2,
        opacity: 1.0,
        flow: 1.0,
        isEraser: true
    )
    
    public static let smudger = BrushPreset(
        id: "smudge-tool",
        name: "Smudger",
        size: 28.0,
        spacing: 0.08,
        hardness: 0.3,
        opacity: 1.0,
        flow: 0.9,
        isSmudge: true,
        smudgeStrength: 0.7
    )
    
    public static let standardPresets: [BrushPreset] = [
        roundSoft,
        roundHard,
        airbrush,
        pencil,
        inkPen,
        eraser,
        smudger
    ]
}
