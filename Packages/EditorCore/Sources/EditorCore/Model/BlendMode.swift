import Foundation

public enum LuminaBlendMode: String, Codable, Sendable, CaseIterable {
    case normal = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    case softLight = "Soft Light"
    case hardLight = "Hard Light"
    case colorDodge = "Color Dodge"
    case colorBurn = "Color Burn"
    case darken = "Darken"
    case lighten = "Lighten"
    case difference = "Difference"
    case exclusion = "Exclusion"
    case hue = "Hue"
    case saturation = "Saturation"
    case color = "Color"
    case luminosity = "Luminosity"
    
    public var metalBlendModeIndex: Int32 {
        switch self {
        case .normal: return 0
        case .multiply: return 1
        case .screen: return 2
        case .overlay: return 3
        case .softLight: return 4
        case .hardLight: return 5
        case .colorDodge: return 6
        case .colorBurn: return 7
        case .darken: return 8
        case .lighten: return 9
        case .difference: return 10
        case .exclusion: return 11
        case .hue: return 12
        case .saturation: return 13
        case .color: return 14
        case .luminosity: return 15
        }
    }
    
    /// CPU blend math for RGBA float channels in [0, 1] range
    public func blend(backdrop: (r: Double, g: Double, b: Double), source: (r: Double, g: Double, b: Double)) -> (r: Double, g: Double, b: Double) {
        let b = backdrop
        let s = source
        
        switch self {
        case .normal:
            return s
            
        case .multiply:
            return (b.r * s.r, b.g * s.g, b.b * s.b)
            
        case .screen:
            return (
                1.0 - (1.0 - b.r) * (1.0 - s.r),
                1.0 - (1.0 - b.g) * (1.0 - s.g),
                1.0 - (1.0 - b.b) * (1.0 - s.b)
            )
            
        case .overlay:
            return (
                Self.overlayChannel(b: b.r, s: s.r),
                Self.overlayChannel(b: b.g, s: s.g),
                Self.overlayChannel(b: b.b, s: s.b)
            )
            
        case .softLight:
            return (
                Self.softLightChannel(b: b.r, s: s.r),
                Self.softLightChannel(b: b.g, s: s.g),
                Self.softLightChannel(b: b.b, s: s.b)
            )
            
        case .hardLight:
            return (
                Self.overlayChannel(b: s.r, s: b.r),
                Self.overlayChannel(b: s.g, s: b.g),
                Self.overlayChannel(b: s.b, s: b.b)
            )
            
        case .colorDodge:
            return (
                Self.dodgeChannel(b: b.r, s: s.r),
                Self.dodgeChannel(b: b.g, s: s.g),
                Self.dodgeChannel(b: b.b, s: s.b)
            )
            
        case .colorBurn:
            return (
                Self.burnChannel(b: b.r, s: s.r),
                Self.burnChannel(b: b.g, s: s.g),
                Self.burnChannel(b: b.b, s: s.b)
            )
            
        case .darken:
            return (min(b.r, s.r), min(b.g, s.g), min(b.b, s.b))
            
        case .lighten:
            return (max(b.r, s.r), max(b.g, s.g), max(b.b, s.b))
            
        case .difference:
            return (abs(b.r - s.r), abs(b.g - s.g), abs(b.b - s.b))
            
        case .exclusion:
            return (
                b.r + s.r - 2.0 * b.r * s.r,
                b.g + s.g - 2.0 * b.g * s.g,
                b.b + s.b - 2.0 * b.b * s.b
            )
            
        case .hue:
            let (hS, _, _) = Self.rgbToHsl(s)
            let (_, sB, lB) = Self.rgbToHsl(b)
            return Self.hslToRgb(h: hS, s: sB, l: lB)
            
        case .saturation:
            let (hB, _, _) = Self.rgbToHsl(b)
            let (_, sS, _) = Self.rgbToHsl(s)
            let (_, _, lB) = Self.rgbToHsl(b)
            return Self.hslToRgb(h: hB, s: sS, l: lB)
            
        case .color:
            let (hS, sS, _) = Self.rgbToHsl(s)
            let (_, _, lB) = Self.rgbToHsl(b)
            return Self.hslToRgb(h: hS, s: sS, l: lB)
            
        case .luminosity:
            let (hB, sB, _) = Self.rgbToHsl(b)
            let (_, _, lS) = Self.rgbToHsl(s)
            return Self.hslToRgb(h: hB, s: sB, l: lS)
        }
    }
    
    // MARK: - Channel Math Helpers
    
    private static func overlayChannel(b: Double, s: Double) -> Double {
        if b <= 0.5 {
            return 2.0 * b * s
        } else {
            return 1.0 - 2.0 * (1.0 - b) * (1.0 - s)
        }
    }
    
    private static func softLightChannel(b: Double, s: Double) -> Double {
        if s <= 0.5 {
            return b - (1.0 - 2.0 * s) * b * (1.0 - b)
        } else {
            let d = b <= 0.25 ? ((16.0 * b - 12.0) * b + 4.0) * b : sqrt(b)
            return b + (2.0 * s - 1.0) * (d - b)
        }
    }
    
    private static func dodgeChannel(b: Double, s: Double) -> Double {
        if b <= 0.0 { return 0.0 }
        if s >= 1.0 { return 1.0 }
        return min(1.0, b / (1.0 - s))
    }
    
    private static func burnChannel(b: Double, s: Double) -> Double {
        if b >= 1.0 { return 1.0 }
        if s <= 0.0 { return 0.0 }
        return 1.0 - min(1.0, (1.0 - b) / s)
    }
    
    // MARK: - HSL conversion
    
    private static func rgbToHsl(_ c: (r: Double, g: Double, b: Double)) -> (h: Double, s: Double, l: Double) {
        let maxC = max(c.r, max(c.g, c.b))
        let minC = min(c.r, min(c.g, c.b))
        let delta = maxC - minC
        let l = (maxC + minC) / 2.0
        
        if delta < 1e-6 {
            return (0.0, 0.0, l)
        }
        
        let s = l > 0.5 ? delta / (2.0 - maxC - minC) : delta / (maxC + minC)
        var h: Double = 0.0
        if maxC == c.r {
            h = ((c.g - c.b) / delta) + (c.g < c.b ? 6.0 : 0.0)
        } else if maxC == c.g {
            h = ((c.b - c.r) / delta) + 2.0
        } else {
            h = ((c.r - c.g) / delta) + 4.0
        }
        h /= 6.0
        return (h, s, l)
    }
    
    private static func hslToRgb(h: Double, s: Double, l: Double) -> (r: Double, g: Double, b: Double) {
        if s < 1e-6 {
            return (l, l, l)
        }
        
        let q = l < 0.5 ? l * (1.0 + s) : l + s - l * s
        let p = 2.0 * l - q
        
        func hue2rgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var temp = t
            if temp < 0.0 { temp += 1.0 }
            if temp > 1.0 { temp -= 1.0 }
            if temp < 1.0 / 6.0 { return p + (q - p) * 6.0 * temp }
            if temp < 1.0 / 2.0 { return q }
            if temp < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - temp) * 6.0 }
            return p
        }
        
        let r = hue2rgb(p, q, h + 1.0 / 3.0)
        let g = hue2rgb(p, q, h)
        let b = hue2rgb(p, q, h - 1.0 / 3.0)
        return (r, g, b)
    }
}
