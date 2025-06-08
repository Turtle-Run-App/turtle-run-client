import SwiftUI

struct ShellSummaryCard: View {
    @State private var animatedShellCount: Int = 0
    @State private var animatedArea: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Shell 개수
            Text("\(animatedShellCount)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.turtleRunTheme.accentColor)
                .shadow(color: .turtleRunTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 2)
            
            Text("점령한 Shell")
                .font(.system(size: 14))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
            
            // 총 면적
            Text(String(format: "%.2f", animatedArea))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.turtleRunTheme.accentColor)
            
            Text("총 면적 (km²)")
                .font(.system(size: 12))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .turtleRunTheme.accentColor.opacity(0.2), location: 0),
                    .init(color: .turtleRunTheme.secondaryColor.opacity(0.2), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.turtleRunTheme.accentColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
        .onAppear {
            // 애니메이션 실행
            withAnimation(.easeOut(duration: 1.5)) {
                animatedShellCount = 7
            }
            
            withAnimation(.easeOut(duration: 2.0)) {
                animatedArea = 2.34
            }
        }
    }
}

#Preview {
    ShellSummaryCard()
        .background(Color.turtleRunTheme.backgroundColor)
}
