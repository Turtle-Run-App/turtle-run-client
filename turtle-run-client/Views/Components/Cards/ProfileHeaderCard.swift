import SwiftUI

struct ProfileHeaderCard: View {
    let userName: String
    let activeDays: Int
    let species: TurtleSpecies
    
    enum TurtleSpecies {
        case red, desert, greek
        
        var emoji: String {
            switch self {
            case .red: return "🔴"
            case .desert: return "🟡"
            case .greek: return "🔵"
            }
        }
        
        var name: String {
            switch self {
            case .red: return "붉은귀거북"
            case .desert: return "사막거북"
            case .greek: return "그리스거북"
            }
        }
        
        var color: Color {
            switch self {
            case .red: return Color.turtleRunTheme.redTurtle
            case .desert: return Color.turtleRunTheme.yellowTurtle
            case .greek: return Color.turtleRunTheme.blueTurtle
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 프로필 아바타
            profileAvatar
            
            // 사용자 이름
            Text(userName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.turtleRunTheme.textColor)
            
            // 활동 정보와 종족 배지
            HStack(spacing: 8) {
                Text("활동 \(activeDays)일째")
                    .font(.system(size: 14))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
                
                speciesBadge
            }
        }
        .padding(20)
        .background(
            Color.turtleRunTheme.mainColor.opacity(0.3)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
    
    private var profileAvatar: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [
                    Color.turtleRunTheme.accentColor,
                    Color.turtleRunTheme.secondaryColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            // 거북이 이모지
            Text("🐢")
                .font(.system(size: 32))
        }
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
    
    private var speciesBadge: some View {
        HStack(spacing: 4) {
            Text(species.emoji)
                .font(.system(size: 12))
            
            Text(species.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(species.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProfileHeaderCard(
        userName: "터틀러너",
        activeDays: 32,
        species: .greek
    )
    .padding(20)
    .background(Color.turtleRunTheme.backgroundColor)
} 
