import SwiftUI

struct TribeSymbol: View {
    let tribe: Tribe
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [tribe.color, tribe.color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 8)
                
                // Icon
                Text(tribe.icon)
                    .font(.system(size: 40))
                
                // Recommendation pulse effect
                if tribe.isRecommended {
                    Circle()
                        .stroke(Color.turtleRunTheme.accentColor, lineWidth: 4)
                        .frame(width: 110, height: 110)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0.3 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 2)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        .onAppear {
                            isAnimating = true
                        }
                }
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 30) {
        TribeSymbol(tribe: Tribe.allTribes[0], isSelected: false) { }
        TribeSymbol(tribe: Tribe.allTribes[1], isSelected: true) { }
        TribeSymbol(tribe: Tribe.allTribes[2], isSelected: false) { }
    }
    .padding()
    .background(Color.black)
} 