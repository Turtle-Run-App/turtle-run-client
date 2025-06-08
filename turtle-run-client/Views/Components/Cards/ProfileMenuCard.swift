import SwiftUI

struct ProfileMenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isFullWidth: Bool
    let isDisabled: Bool
    let isComingSoon: Bool
    let specialStyle: SpecialStyle?
    let action: () -> Void
    
    enum SpecialStyle {
        case spInfo(spValue: String, rank: String, rankBadge: String)
        case achievements
    }
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        isFullWidth: Bool = false,
        isDisabled: Bool = false,
        isComingSoon: Bool = false,
        specialStyle: SpecialStyle? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
        self.isComingSoon = isComingSoon
        self.specialStyle = specialStyle
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            cardContent
                .scaleEffect(1.0)
                .opacity(isDisabled ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isDisabled)
        }
        .buttonStyle(CardButtonStyle(isDisabled: isDisabled))
    }
    
    @ViewBuilder
    private var cardContent: some View {
        if isFullWidth {
            fullWidthCard
        } else {
            regularCard
        }
    }
    
    private var regularCard: some View {
        VStack(spacing: 8) {
            ZStack {
                iconView
                
                if isComingSoon {
                    VStack {
                        HStack {
                            Spacer()
                            comingSoonBadge
                        }
                        Spacer()
                    }
                }
            }
            
            VStack(spacing: 4) {
                if case .spInfo(let spValue, let rank, let rankBadge) = specialStyle {
                    spInfoContent(spValue: spValue, rank: rank, rankBadge: rankBadge)
                } else {
                    regularContent
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
    
    private var fullWidthCard: some View {
        HStack(spacing: 16) {
            iconView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
    
    private var iconView: some View {
        Text(icon)
            .font(.system(size: 20))
            .frame(width: 40, height: 40)
            .background(iconBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var iconBackground: some View {
        Group {
            if case .achievements = specialStyle {
                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2) // 금색 배경
            } else {
                Color.turtleRunTheme.accentColor.opacity(0.2)
            }
        }
    }
    
    private var cardBackground: some View {
        Group {
            if case .spInfo = specialStyle {
                LinearGradient(
                    colors: [
                        Color.turtleRunTheme.accentColor.opacity(0.2),
                        Color.turtleRunTheme.secondaryColor.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.turtleRunTheme.accentColor.opacity(0.3), lineWidth: 1)
                )
            } else if case .achievements = specialStyle {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1),
                        Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(isDisabled ? 0.15 : 0.3), lineWidth: 1)
                )
            } else {
                Color.turtleRunTheme.mainColor
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    private var regularContent: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.turtleRunTheme.textColor)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
    
    private func spInfoContent(spValue: String, rank: String, rankBadge: String) -> some View {
        VStack(spacing: 4) {
            Text(spValue)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.turtleRunTheme.accentColor)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.turtleRunTheme.textColor)
            
            HStack(spacing: 4) {
                Text(rank)
                    .font(.system(size: 12))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
                
                Text(rankBadge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.backgroundColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.turtleRunTheme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var comingSoonBadge: some View {
        Text("준비중")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
    }
}

struct CardButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                isDisabled ? 1.0 : (configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            ProfileMenuCard(
                icon: "🏆",
                title: "SP & 랭킹",
                subtitle: "",
                specialStyle: .spInfo(spValue: "2,847", rank: "전체 #142위", rankBadge: "주니어"),
                action: {}
            )
            
            ProfileMenuCard(
                icon: "📊",
                title: "러닝 통계",
                subtitle: "총 거리, 시간\n평균 페이스",
                action: {}
            )
        }
        
        HStack(spacing: 16) {
            ProfileMenuCard(
                icon: "🗺️",
                title: "Shell 현황",
                subtitle: "점령한 영토\n총 면적 정보",
                action: {}
            )
            
            ProfileMenuCard(
                icon: "🏅",
                title: "업적 & 배지",
                subtitle: "획득한 업적\n진행 중인 도전",
                isDisabled: true,
                isComingSoon: true,
                specialStyle: .achievements,
                action: {}
            )
        }
        
        ProfileMenuCard(
            icon: "👤",
            title: "기본 정보",
            subtitle: "프로필 설정 • 가입 정보 • 계정 관리",
            isFullWidth: true,
            action: {}
        )
    }
    .padding(20)
    .background(Color.turtleRunTheme.backgroundColor)
} 
