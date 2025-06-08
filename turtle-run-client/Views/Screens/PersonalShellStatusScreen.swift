import SwiftUI

struct PersonalShellStatusScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 상단 바
                TopBar(
                    title: "Shell 현황",
                    leftButton: .back {
                        dismiss()
                    }
                )
                .zIndex(1)
                
                // 스크롤 가능한 콘텐츠
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Shell 요약 카드
                        ShellSummaryCard()
                        
                        // 통계 그리드
                        StatsCardsGrid()
                        
                        // Shell 시각화
                        ShellVisualizationCard()
                        
                        // Shell 목록
                        ShellList()
                        
                        // 성과 카드
                        AchievementCard()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .background(Color.turtleRunTheme.backgroundColor)
    }

}

#Preview {
    PersonalShellStatusScreen()
}
