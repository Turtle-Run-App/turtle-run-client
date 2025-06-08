import SwiftUI

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
    
    // TurtleRun App Color Theme
    static let turtleRunTheme = TurtleRunColorTheme()
}

struct TurtleRunColorTheme {
    let mainColor = Color(red: 0.1, green: 0.23, blue: 0.18)        // #1a3a2f
    let secondaryColor = Color(red: 0.17, green: 0.31, blue: 0.26)  // #2c4f43
    let accentColor = Color(red: 0.29, green: 0.62, blue: 0.5)      // #4a9d7f
    let backgroundColor = Color(red: 0.07, green: 0.07, blue: 0.07) // #121212
    let textColor = Color.white
    let textSecondaryColor = Color(red: 0.7, green: 0.7, blue: 0.7) // #b3b3b3
    
    // Tribe colors (updated to match HTML design)
    let redTurtle = Color(red: 1.0, green: 0.37, blue: 0.37)    // #ff5e5e (붉은귀거북)
    let yellowTurtle = Color(red: 1.0, green: 0.91, blue: 0.37) // #ffe75e (사막거북)
    let blueTurtle = Color(red: 0.37, green: 0.61, blue: 1.0)   // #5e9cff (그리스거북)
}
