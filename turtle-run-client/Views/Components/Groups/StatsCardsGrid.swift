import SwiftUI

struct StatsCardsGrid: View {
    @State private var animatedLargest: Double = 0.0
    @State private var animatedAverage: Double = 0.0
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCardView(
                icon: "👑",
                value: String(format: "%.2f", animatedLargest),
                label: "최대 Shell (km²)"
            )
            
            StatCardView(
                icon: "📈",
                value: String(format: "%.2f", animatedAverage),
                label: "평균 크기 (km²)"
            )
            
            StatCardView(
                icon: "🕒",
                value: "3일",
                label: "최근 점령"
            )
            
            StatCardView(
                icon: "🔥",
                value: "12일",
                label: "연속 확장"
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8)) {
                animatedLargest = 0.52
            }
            
            withAnimation(.easeOut(duration: 2.2)) {
                animatedAverage = 0.33
            }
        }
    }
}

struct StatCardView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.turtleRunTheme.accentColor)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color.turtleRunTheme.mainColor.background(.ultraThinMaterial)
        )
        .overlay(
            VStack {
                Rectangle()
                    .frame(height: 3)
                    .foregroundColor(.turtleRunTheme.accentColor)
                Spacer()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    StatsCardsGrid()
        .background(Color.turtleRunTheme.backgroundColor)
        .padding()
}
