import SwiftUI

struct RunningStatsMainCard: View {
    @State private var animatedDistance: Double = 0
    @State private var animatedTotalMinutes: Int = 0
    @State private var animatedRuns: Int = 0
    
    let targetDistance: Double = 142.7
    let targetHours: Int = 24
    let targetMinutes: Int = 15
    let avgPace: String = "6:24"
    let targetRuns: Int = 47
    
    private var totalTargetMinutes: Int {
        return targetHours * 60 + targetMinutes
    }
    
    private var formattedTime: String {
        let hours = animatedTotalMinutes / 60
        let minutes = animatedTotalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // 총 거리
            StatItemCard(
                value: String(format: "%.1f", animatedDistance),
                label: "총 거리 (km)",
                trend: "📈 +12.3km 이번 주",
                trendColor: .green
            )
            
            // 총 시간
            StatItemCard(
                value: formattedTime,
                label: "총 시간 (시간)",
                trend: "📈 +2:30 이번 주",
                trendColor: .green
            )
            
            // 평균 페이스
            StatItemCard(
                value: avgPace,
                label: "평균 페이스 (/km)",
                trend: "⚡ -0:15 개선",
                trendColor: .green
            )
            
            // 총 러닝 횟수
            StatItemCard(
                value: "\(animatedRuns)",
                label: "총 러닝 횟수",
                trend: "📈 +5회 이번 주",
                trendColor: .green
            )
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // 거리 애니메이션
        withAnimation(.easeOut(duration: 1.5)) {
            animatedDistance = targetDistance
        }
        
        // 시간 애니메이션
        let timeIncrement = totalTargetMinutes / 50
        let timeTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if animatedTotalMinutes >= totalTargetMinutes {
                animatedTotalMinutes = totalTargetMinutes
                timer.invalidate()
            } else {
                animatedTotalMinutes += timeIncrement
            }
        }
        timeTimer.fire()
        
        // 러닝 횟수 애니메이션
        let runsIncrement = targetRuns / 40
        let runsTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if animatedRuns >= targetRuns {
                animatedRuns = targetRuns
                timer.invalidate()
            } else {
                animatedRuns += runsIncrement
            }
        }
        runsTimer.fire()
    }
}

struct StatItemCard: View {
    let value: String
    let label: String
    let trend: String
    let trendColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.turtleRunTheme.accentColor)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Text(trend)
                    .font(.system(size: 11))
                    .foregroundColor(trendColor)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            Color.turtleRunTheme.mainColor
                .background(.ultraThinMaterial)
                .overlay(
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.turtleRunTheme.accentColor,
                                Color.green
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 3)
                        
                        Spacer()
                    }
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    RunningStatsMainCard()
        .padding(20)
        .background(Color.turtleRunTheme.backgroundColor)
} 
