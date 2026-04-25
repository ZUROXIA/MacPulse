import SwiftUI

public enum ZuroxiaTheme {
    public static let cyan = Color(hex: "#22d3ee")
    public static let purple = Color(hex: "#c084fc")
    public static let emerald = Color(hex: "#34d399")
    public static let crimson = Color(hex: "#ef4444")
    
    public static let bgDark = Color(red: 0.04, green: 0.04, blue: 0.04) // #09090b
    public static let bgPanel = Color(red: 0.05, green: 0.05, blue: 0.05) // #0c0c0e
    public static let borderLight = Color.white.opacity(0.1)
    public static let borderFaint = Color.white.opacity(0.05)
    
    public static let textPrimary = Color(hex: "#f4f4f5") // zinc-100
    public static let textSecondary = Color(hex: "#a1a1aa") // zinc-400
    public static let textMuted = Color(hex: "#71717a") // zinc-500
    
    // Tech font helper
    public static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .monospaced)
    }
}

public struct ChamferedRectangle: Shape {
    public var cornerSize: CGFloat = 8.0
    
    public init(cornerSize: CGFloat = 8.0) {
        self.cornerSize = cornerSize
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: cornerSize, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerSize))
        path.addLine(to: CGPoint(x: rect.maxX - cornerSize, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: cornerSize))
        path.closeSubpath()
        
        return path
    }
}

public extension View {
    func cyberPanel(borderColor: Color = ZuroxiaTheme.borderFaint) -> some View {
        self
            .background(ChamferedRectangle().fill(ZuroxiaTheme.bgPanel))
            .overlay(
                ChamferedRectangle()
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    func cyberGlow(color: Color) -> some View {
        self.shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 0)
    }
    
    func applyZuroxiaEnvironment() -> some View {
        self
            .preferredColorScheme(.dark)
            .background(ZuroxiaTheme.bgDark)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
