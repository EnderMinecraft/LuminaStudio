import Foundation
import CoreGraphics

public struct BrightnessContrastData: Codable, Sendable, Equatable {
    public var brightness: Double // -1.0 to 1.0 (default 0.0)
    public var contrast: Double   // -1.0 to 1.0 (default 0.0)
    
    public init(brightness: Double = 0.0, contrast: Double = 0.0) {
        self.brightness = max(-1.0, min(1.0, brightness))
        self.contrast = max(-1.0, min(1.0, contrast))
    }
}

public struct ExposureData: Codable, Sendable, Equatable {
    public var exposureEV: Double // -5.0 to +5.0 EV (default 0.0)
    
    public init(exposureEV: Double = 0.0) {
        self.exposureEV = max(-5.0, min(5.0, exposureEV))
    }
}

public struct LevelsData: Codable, Sendable, Equatable {
    public var blackPoint: Double  // 0.0 to 1.0
    public var midtoneGamma: Double // 0.1 to 10.0 (default 1.0)
    public var whitePoint: Double  // 0.0 to 1.0
    public var outputBlack: Double // 0.0 to 1.0
    public var outputWhite: Double // 0.0 to 1.0
    
    public init(
        blackPoint: Double = 0.0,
        midtoneGamma: Double = 1.0,
        whitePoint: Double = 1.0,
        outputBlack: Double = 0.0,
        outputWhite: Double = 1.0
    ) {
        self.blackPoint = max(0.0, min(0.99, blackPoint))
        self.midtoneGamma = max(0.1, min(10.0, midtoneGamma))
        self.whitePoint = max(self.blackPoint + 0.01, min(1.0, whitePoint))
        self.outputBlack = max(0.0, min(outputWhite, outputBlack))
        self.outputWhite = max(outputBlack, min(1.0, outputWhite))
    }
}

public struct SplinePoint: Codable, Sendable, Equatable {
    public var x: Double // 0.0 to 1.0
    public var y: Double // 0.0 to 1.0
    
    public init(x: Double, y: Double) {
        self.x = max(0.0, min(1.0, x))
        self.y = max(0.0, min(1.0, y))
    }
}

public struct CurvesData: Codable, Sendable, Equatable {
    public enum Channel: String, Codable, Sendable, CaseIterable {
        case rgb = "RGB"
        case red = "Red"
        case green = "Green"
        case blue = "Blue"
    }
    
    public var activeChannel: Channel
    public var rgbPoints: [SplinePoint]
    public var redPoints: [SplinePoint]
    public var greenPoints: [SplinePoint]
    public var bluePoints: [SplinePoint]
    
    public init(
        activeChannel: Channel = .rgb,
        rgbPoints: [SplinePoint] = [SplinePoint(x: 0, y: 0), SplinePoint(x: 1, y: 1)],
        redPoints: [SplinePoint] = [SplinePoint(x: 0, y: 0), SplinePoint(x: 1, y: 1)],
        greenPoints: [SplinePoint] = [SplinePoint(x: 0, y: 0), SplinePoint(x: 1, y: 1)],
        bluePoints: [SplinePoint] = [SplinePoint(x: 0, y: 0), SplinePoint(x: 1, y: 1)]
    ) {
        self.activeChannel = activeChannel
        self.rgbPoints = rgbPoints
        self.redPoints = redPoints
        self.greenPoints = greenPoints
        self.bluePoints = bluePoints
    }
}

public struct HueSaturationData: Codable, Sendable, Equatable {
    public var hueShiftDegrees: Double // -180.0 to +180.0
    public var saturation: Double      // -1.0 to 1.0
    public var lightness: Double       // -1.0 to 1.0
    
    public init(hueShiftDegrees: Double = 0.0, saturation: Double = 0.0, lightness: Double = 0.0) {
        self.hueShiftDegrees = max(-180.0, min(180.0, hueShiftDegrees))
        self.saturation = max(-1.0, min(1.0, saturation))
        self.lightness = max(-1.0, min(1.0, lightness))
    }
}

public struct VibranceData: Codable, Sendable, Equatable {
    public var vibrance: Double // -1.0 to +1.0
    public var saturation: Double // -1.0 to +1.0
    
    public init(vibrance: Double = 0.0, saturation: Double = 0.0) {
        self.vibrance = max(-1.0, min(1.0, vibrance))
        self.saturation = max(-1.0, min(1.0, saturation))
    }
}

public struct ColorBalanceData: Codable, Sendable, Equatable {
    public var cyanRed: Double      // -1.0 to 1.0
    public var magentaGreen: Double  // -1.0 to 1.0
    public var yellowBlue: Double    // -1.0 to 1.0
    public var preserveLuminosity: Bool
    
    public init(cyanRed: Double = 0.0, magentaGreen: Double = 0.0, yellowBlue: Double = 0.0, preserveLuminosity: Bool = true) {
        self.cyanRed = max(-1.0, min(1.0, cyanRed))
        self.magentaGreen = max(-1.0, min(1.0, magentaGreen))
        self.yellowBlue = max(-1.0, min(1.0, yellowBlue))
        self.preserveLuminosity = preserveLuminosity
    }
}

public struct TemperatureTintData: Codable, Sendable, Equatable {
    public var temperature: Double // -1.0 (cool/blue) to +1.0 (warm/amber)
    public var tint: Double        // -1.0 (green) to +1.0 (magenta)
    
    public init(temperature: Double = 0.0, tint: Double = 0.0) {
        self.temperature = max(-1.0, min(1.0, temperature))
        self.tint = max(-1.0, min(1.0, tint))
    }
}

public struct BlackAndWhiteData: Codable, Sendable, Equatable {
    public var redWeight: Double
    public var greenWeight: Double
    public var blueWeight: Double
    
    public init(redWeight: Double = 0.3, greenWeight: Double = 0.59, blueWeight: Double = 0.11) {
        self.redWeight = redWeight
        self.greenWeight = greenWeight
        self.blueWeight = blueWeight
    }
}

public struct VignetteData: Codable, Sendable, Equatable {
    public var intensity: Double // -1.0 to +1.0
    public var radius: Double    // 0.1 to 1.0
    public var softness: Double  // 0.0 to 1.0
    
    public init(intensity: Double = 0.5, radius: Double = 0.8, softness: Double = 0.5) {
        self.intensity = max(-1.0, min(1.0, intensity))
        self.radius = max(0.1, min(1.0, radius))
        self.softness = max(0.0, min(1.0, softness))
    }
}

public enum AdjustmentParameters: Codable, Sendable, Equatable {
    case brightnessContrast(BrightnessContrastData)
    case exposure(ExposureData)
    case levels(LevelsData)
    case curves(CurvesData)
    case hueSaturation(HueSaturationData)
    case vibrance(VibranceData)
    case colorBalance(ColorBalanceData)
    case temperatureTint(TemperatureTintData)
    case blackAndWhite(BlackAndWhiteData)
    case vignette(VignetteData)
}
