import SwiftUI

struct TribeInfoScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animateValues = false
    
    // 종족 정보
    private let currentSpecies = Tribes.greek
    private let speciesLevel = 12
    private let activeDays = 32
    private let daysUntilChange = 18
    
    // 버프 데이터
    private let buffStats = [
        BuffStat(value: 50, label: "기본 버프", description: "3km 이상 달릴 시"),
        BuffStat(value: 25, label: "페이스 버프", description: "6'30\"/km 이하 시"),
        BuffStat(value: 15, label: "거리 버프", description: "5km 이상 달릴 시"),
        BuffStat(value: 10, label: "탐사 버프", description: "새로운 경로 30% 이상")
    ]
    
    // 성과 데이터
    private let achievements = [
        AchievementSummary(value: 89, label: "기본 버프\n획득 횟수"),
        AchievementSummary(value: 34, label: "페이스 버프\n획득 횟수"),
        AchievementSummary(value: 12, label: "탐사 버프\n획득 횟수")
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {

                TopBar(
                    title: "종족 관리",
                    leftButton: .back {
                        dismiss()
                    },
                    rightButton: .logo
                )
                ScrollView {
                    VStack(spacing: 20) {
                        currentSpeciesCard
                        buffStatsCard
                        tribesComparisonCard
                        changeTribeCard
                        achievementSummaryCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.turtleRunTheme.backgroundColor)
            .navigationBarHidden(true)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    animateValues = true
                }
            }
        }
    }
    
    // MARK: - 현재 종족 카드
    private var currentSpeciesCard: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.blue)
                .frame(width: 80, height: 80)
                .overlay(Text("🔵").font(.system(size: 36)))
            
            VStack(spacing: 8) {
                Text("그리스거북")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("다양한 경로 탐색 특화")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text("Lv.12 · 활동 32일")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.2))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue, lineWidth: 2))
        )
    }
    
    // MARK: - 버프 현황 카드
    private var buffStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("⚡")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.2)))
                
                Text("그리스거북 버프 현황")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                buffItem(value: "50%", label: "기본 버프", description: "3km 이상 달릴 시")
                buffItem(value: "25%", label: "페이스 버프", description: "6'30\"/km 이하 시")
                buffItem(value: "15%", label: "거리 버프", description: "5km 이상 달릴 시")
                buffItem(value: "10%", label: "탐사 버프", description: "새로운 경로 30% 이상")
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.turtleRunTheme.accentColor.opacity(0.2)))
    }
    
    private func buffItem(value: String, label: String, description: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.blue)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
    
    // MARK: - 부족 비교표
    private var tribesComparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🏆")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.2)))
                
                Text("종족별 최대 버프 비교")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                speciesRow(emoji: "🔴", name: "붉은귀거북", description: "빠른 속도와 민첩성", color: .red)
                speciesRow(emoji: "🟡", name: "사막거북", description: "장거리와 지구력", color: .orange)
                speciesRow(emoji: "🔵", name: "그리스거북", description: "다양한 경로 탐색", color: .blue, isCurrent: true)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.turtleRunTheme.accentColor.opacity(0.2)))
    }
    
    private func speciesRow(emoji: String, name: String, description: String, color: Color, isCurrent: Bool = false) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(Text(emoji).font(.system(size: 16)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("100%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? color.opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? color : Color.clear, lineWidth: 1)
                )
        )
    }
    
    // MARK: - 종족 변경 카드
    private var changeTribeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🔄")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.2)))
                
                Text("종족 변경")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("⏰")
                    Text("변경 가능까지 18일 남음")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Text("종족 변경은 30일마다 1회 가능합니다. 마지막 변경일: 2024.12.11")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
            )
            
            Button("종족 변경하기 (18일 후 가능)") {}
                .disabled(true)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.2)))
                .foregroundColor(.gray)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.turtleRunTheme.accentColor.opacity(0.2)))
    }
    
    // MARK: - 성과 요약 카드
    private var achievementSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📊")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.2)))
                
                Text("그리스거북 성과")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 12) {
                achievementItem(value: "89", label: "기본 버프\n획득 횟수")
                achievementItem(value: "34", label: "페이스 버프\n획득 횟수")
                achievementItem(value: "12", label: "탐사 버프\n획득 횟수")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
        )
    }
    
    private func achievementItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.green)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.turtleRunTheme.accentColor.opacity(0.1)))
    }
}

// MARK: - 데이터 모델들
struct BuffStat {
    let value: Int
    let label: String
    let description: String
}

struct AchievementSummary {
    let value: Int
    let label: String
}

enum Tribes: CaseIterable {
    case redEared
    case desert
    case greek
    
    var name: String {
        switch self {
        case .redEared: return "붉은귀거북"
        case .desert: return "사막거북"
        case .greek: return "그리스거북"
        }
    }
    
    var description: String {
        switch self {
        case .redEared: return "빠른 속도와 민첩성"
        case .desert: return "장거리와 지구력"
        case .greek: return "다양한 경로 탐색"
        }
    }
    
    var color: Color {
        switch self {
        case .redEared: return .red
        case .desert: return .orange
        case .greek: return .blue
        }
    }
    
    var emoji: String {
        switch self {
        case .redEared: return "🔴"
        case .desert: return "🟡"
        case .greek: return "🔵"
        }
    }
}

// MARK: - Preview
#Preview {
    TribeInfoScreen()
        .preferredColorScheme(.dark)
} 
