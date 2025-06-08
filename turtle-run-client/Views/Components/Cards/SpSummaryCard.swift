import SwiftUI

struct SpSummaryCard: View {
    @State private var animatedSP = 0
    let targetSP: Int
    let weeklyTrend: Int
    
    init(targetSP: Int, weeklyTrend: Int) {
        self.targetSP = targetSP
        self.weeklyTrend = weeklyTrend
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 메인 SP 값
            Text(animatedSP.formatted())
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.turtleRunTheme.accentColor)
                .shadow(color: Color.turtleRunTheme.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // SP 라벨
            Text("총 Shell Points")
                .font(.system(size: 14))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
            
            // 주간 트렌드
            HStack(spacing: 8) {
                Text("📈")
                    .font(.system(size: 14))
                
                Text("+\(weeklyTrend) SP (이번 주)")
                    .font(.system(size: 14))
                    .foregroundColor(Color.green)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color.turtleRunTheme.accentColor.opacity(0.2),
                    Color.turtleRunTheme.secondaryColor.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.turtleRunTheme.accentColor.opacity(0.3), lineWidth: 1)
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 8)
        .onAppear {
            startSPAnimation()
        }
    }
    
    private func startSPAnimation() {
        let increment = targetSP / 60
        let timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if animatedSP >= targetSP {
                animatedSP = targetSP
                timer.invalidate()
            } else {
                animatedSP += increment
            }
        }
        timer.fire()
    }
}

#Preview {
    SpSummaryCard(targetSP: 2847, weeklyTrend: 124)
        .padding(20)
        .background(Color.turtleRunTheme.backgroundColor)
} 
