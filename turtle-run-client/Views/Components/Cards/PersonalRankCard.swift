import SwiftUI

struct PersonalRankCard: View {
    let currentRank: Int
    let totalUsers: Int
    let weeklyChange: Int
    
    private var percentile: Double {
        return (Double(currentRank) / Double(totalUsers)) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack(spacing: 8) {
                Text("🏆")
                    .font(.system(size: 16))
                
                Text("전체 순위")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
            }
            
            // 메인 순위
            VStack(spacing: 4) {
                Text("#\(currentRank)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.turtleRunTheme.accentColor)
                
                Text("전체 \(totalUsers.formatted())명 중")
                    .font(.system(size: 14))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
            }
            
            // 통계 그리드
            HStack(spacing: 16) {
                // 백분율
                VStack(spacing: 4) {
                    Text("상위 \(String(format: "%.1f", percentile))%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.turtleRunTheme.accentColor)
                    
                    Text("백분율")
                        .font(.system(size: 12))
                        .foregroundColor(.turtleRunTheme.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 주간 변화
                VStack(spacing: 4) {
                    HStack(spacing: 2) {
                        Text(weeklyChange >= 0 ? "+" : "")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(weeklyChange >= 0 ? .green : .red)
                        
                        Text("\(weeklyChange)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(weeklyChange >= 0 ? .green : .red)
                    }
                    
                    Text("이번 주 \(weeklyChange >= 0 ? "상승" : "하락")")
                        .font(.system(size: 12))
                        .foregroundColor(.turtleRunTheme.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            Color.turtleRunTheme.mainColor.background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    PersonalRankCard(
        currentRank: 142,
        totalUsers: 8247,
        weeklyChange: 12
    )
    .padding(20)
    .background(Color.turtleRunTheme.backgroundColor)
} 
