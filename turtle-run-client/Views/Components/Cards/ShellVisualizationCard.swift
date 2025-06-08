import SwiftUI

struct ShellVisualizationCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // 패턴 시각화
            ZStack {
                // 배경 패턴
                PatternBackground()
                
                // 지도 아이콘
                Text("🗺️")
                    .font(.system(size: 32))
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.turtleRunTheme.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            )
            
            Text("나만의 Shell 패턴")
                .font(.system(size: 14))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
            
            Text("주로 공원과 강변을 따라 형성된 독특한 패턴")
                .font(.system(size: 12))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color.turtleRunTheme.mainColor.background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

struct PatternBackground: View {
    var body: some View {
        ZStack {
            Color.turtleRunTheme.accentColor.opacity(0.1)
            
            Path { path in
                let size: CGFloat = 20
                let rows = Int(120 / size) + 1
                let cols = Int(120 / size) + 1
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * size
                        let y = CGFloat(row) * size
                        
                        if (row + col) % 2 == 0 {
                            path.addRect(CGRect(x: x, y: y, width: size/2, height: size/2))
                        }
                    }
                }
            }
            .fill(Color.turtleRunTheme.accentColor.opacity(0.1))
        }
    }
}

#Preview {
    ShellVisualizationCard()
        .background(Color.turtleRunTheme.backgroundColor)
        .padding()
}
