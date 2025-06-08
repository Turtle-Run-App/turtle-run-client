import SwiftUI

struct SpTierCard: View {
    let currentSP: Int
    let currentRank: TurtleRank
    let nextRankRequiredSP: Int
    
    @State private var progressAnimation: CGFloat = 0
    
    enum TurtleRank {
        case juvenile, subadult, adult
        
        var name: String {
            switch self {
            case .juvenile: return "주니어 (Juvenile)"
            case .subadult: return "서브어덜트 (Subadult)"
            case .adult: return "어덜트 (Adult)"
            }
        }
        
        var description: String {
            switch self {
            case .juvenile: return "활발한 젊은 거북이"
            case .subadult: return "성숙해가는 거북이"
            case .adult: return "완전히 성장한 거북이"
            }
        }
        
        var color: Color {
            switch self {
            case .juvenile: return Color(red: 0.2, green: 0.6, blue: 0.86) // #3498db
            case .subadult: return Color(red: 0.61, green: 0.35, blue: 0.71) // #9b59b6
            case .adult: return Color(red: 0.9, green: 0.49, blue: 0.13) // #e67e22
            }
        }
        
        var nextRank: TurtleRank? {
            switch self {
            case .juvenile: return .subadult
            case .subadult: return .adult
            case .adult: return nil
            }
        }
        
        var nextRankName: String {
            return nextRank?.name ?? "최고 랭크"
        }
    }
    
    private var progressPercentage: CGFloat {
        return CGFloat(currentSP) / CGFloat(nextRankRequiredSP)
    }
    
    private var remainingSP: Int {
        return max(0, nextRankRequiredSP - currentSP)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 랭크 헤더
            HStack(spacing: 16) {
                // 랭크 배지
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [currentRank.color, currentRank.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: currentRank.color.opacity(0.4), radius: 6, x: 0, y: 4)
                    
                    Text("🐢")
                        .font(.system(size: 24))
                }
                
                // 랭크 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentRank.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.turtleRunTheme.textColor)
                    
                    Text(currentRank.description)
                        .font(.system(size: 14))
                        .foregroundColor(.turtleRunTheme.textSecondaryColor)
                }
                
                Spacer()
            }
            
            // 진행도 섹션
            if currentRank.nextRank != nil {
                VStack(spacing: 8) {
                    // 진행도 헤더
                    HStack {
                        Text("\(currentRank.nextRankName)까지")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.turtleRunTheme.textColor)
                        
                        Spacer()
                        
                        Text("\(currentSP.formatted()) / \(nextRankRequiredSP.formatted()) SP")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(currentRank.color)
                    }
                    
                    // 진행바
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 배경
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 12)
                            
                            // 진행도
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [currentRank.color, Color.turtleRunTheme.accentColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * progressAnimation,
                                    height: 12
                                )
                        }
                    }
                    .frame(height: 12)
                    .onAppear {
                        withAnimation(.easeOut(duration: 2).delay(0.5)) {
                            progressAnimation = progressPercentage
                        }
                    }
                    
                    // 남은 SP
                    Text("\(remainingSP.formatted()) SP 더 필요해요!")
                        .font(.system(size: 12))
                        .foregroundColor(.turtleRunTheme.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                }
            } else {
                Text("최고 랭크에 도달했습니다! 🎉")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.turtleRunTheme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
    SpTierCard(
        currentSP: 2847,
        currentRank: .juvenile,
        nextRankRequiredSP: 5000
    )
    .padding(20)
    .background(Color.turtleRunTheme.backgroundColor)
} 
