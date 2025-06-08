import SwiftUI

struct MonthlyActivityCard: View {
    @State private var chartBarsAnimated = Array(repeating: false, count: 7)
    
    let monthlyData = MonthlyData(
        runCount: 12,
        totalDistance: 48.2,
        totalTime: "8:15"
    )
    
    // 주간 차트 데이터 (높이 비율)
    let weeklyData: [Double] = [0.45, 0.60, 0.35, 0.80, 0.55, 0.70, 0.90]
    let weekDays = ["월", "화", "수", "목", "금", "토", "일"]
    
    struct MonthlyData {
        let runCount: Int
        let totalDistance: Double
        let totalTime: String
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack(spacing: 12) {
                Text("📅")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(Color.turtleRunTheme.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("이번 달 활동")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
            }
            
            // 월간 통계
            HStack(spacing: 12) {
                MonthlyStatItem(
                    value: "\(monthlyData.runCount)",
                    label: "러닝 횟수"
                )
                
                MonthlyStatItem(
                    value: String(format: "%.1f", monthlyData.totalDistance),
                    label: "총 거리 (km)"
                )
                
                MonthlyStatItem(
                    value: monthlyData.totalTime,
                    label: "총 시간"
                )
            }
            
            // 주간 차트
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<weeklyData.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.turtleRunTheme.accentColor,
                                            Color.turtleRunTheme.secondaryColor
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: (geometry.size.width - CGFloat(weeklyData.count - 1) * 8) / CGFloat(weeklyData.count),
                                    height: chartBarsAnimated[index] ? 
                                        geometry.size.height * CGFloat(weeklyData[index]) : 20
                                )
                                .animation(
                                    .easeOut(duration: 1.0)
                                    .delay(Double(index) * 0.1),
                                    value: chartBarsAnimated[index]
                                )
                        }
                    }
                }
                .frame(height: 120)
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 차트 라벨
                HStack {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10))
                            .foregroundColor(.turtleRunTheme.textSecondaryColor)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(20)
        .background(
            Color.turtleRunTheme.mainColor.background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
        .onAppear {
            startChartAnimation()
        }
    }
    
    private func startChartAnimation() {
        for i in 0..<chartBarsAnimated.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                chartBarsAnimated[i] = true
            }
        }
    }
}

struct MonthlyStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.turtleRunTheme.accentColor)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MonthlyActivityCard()
        .padding(20)
        .background(Color.turtleRunTheme.backgroundColor)
} 
