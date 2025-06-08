import SwiftUI

struct AchievementCard: View {
    let achievements = [
        Achievement(badge: "🥇", title: "영토 개척자", description: "첫 Shell 점령 달성"),
        Achievement(badge: "🌟", title: "영역 확장가", description: "5개 이상 Shell 점령"),
        Achievement(badge: "👑", title: "대형 Shell 정복자", description: "0.5km² 이상 Shell 점령")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.turtleRunTheme.accentColor.opacity(0.2))
                    .overlay(
                        Text("🏆")
                            .font(.system(size: 20))
                    )
                
                Text("Shell 성과")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // 성과 목록
            VStack(spacing: 12) {
                ForEach(achievements.indices, id: \.self) { index in
                    AchievementItemView(achievement: achievements[index])
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .turtleRunTheme.accentColor.opacity(0.1), location: 0),
                    .init(color: .turtleRunTheme.secondaryColor.opacity(0.1), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.turtleRunTheme.accentColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

struct Achievement {
    let badge: String
    let title: String
    let description: String
}

struct AchievementItemView: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            // 배지
            Circle()
                .frame(width: 32, height: 32)
                .foregroundColor(.turtleRunTheme.accentColor)
                .overlay(
                    Text(achievement.badge)
                        .font(.system(size: 16))
                )
            
            // 성과 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            Color.turtleRunTheme.accentColor.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AchievementCard()
        .background(Color.turtleRunTheme.backgroundColor)
        .padding()
}
