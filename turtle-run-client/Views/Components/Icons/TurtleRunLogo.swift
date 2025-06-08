import SwiftUI

struct TurtleRunLogo: View {
    let size: CGFloat
    let accentColor = Color(red: 0.29, green: 0.62, blue: 0.5)     // #4a9d7f
    let backgroundColor = Color(red: 0.07, green: 0.07, blue: 0.07) // #121212
    
    init(size: CGFloat = 120) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outer rounded rectangle
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(accentColor)
                .frame(width: size, height: size)
            
            // Inner hexagon shape
            HexagonShape()
                .fill(backgroundColor)
                .frame(width: size * 0.67, height: size * 0.67)
        }
    }
}

// Custom hexagon shape to match the CSS clip-path
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = min(width, height) / 2
        
        for i in 0..<6 {
            let angle = Double(i) * Double.pi / 3
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        TurtleRunLogo(size: 60)
        TurtleRunLogo(size: 120)
        TurtleRunLogo(size: 180)
    }
    .padding()
    .background(Color.black)
} 