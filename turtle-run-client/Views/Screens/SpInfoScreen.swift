import SwiftUI

struct SpInfoScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cardsVisible = [false, false, false, false]
    
    // 데이터 (추후 ViewModel로 분리 가능)
    private let currentSP = 2847
    private let weeklyTrend = 124
    private let currentRank = SpTierCard.TurtleRank.juvenile
    private let nextRankRequiredSP = 5000
    private let globalRank = 142
    private let totalUsers = 8247
    private let weeklyRankChange = 12
    
    private let spHistory = [
        SpHistoryList.SPHistoryItem(date: "2024.12.29", change: 89),
        SpHistoryList.SPHistoryItem(date: "2024.12.28", change: 45),
        SpHistoryList.SPHistoryItem(date: "2024.12.27", change: 67),
        SpHistoryList.SPHistoryItem(date: "2024.12.26", change: 52),
        SpHistoryList.SPHistoryItem(date: "2024.12.25", change: -12)
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 상단 네비게이션 바
                TopBar(
                    title: "SP & 랭킹",
                    leftButton: .back {
                        dismiss()
                    },
                    rightButton: .logo
                )
                .zIndex(100)
                
                // 스크롤 가능한 콘텐츠
                ScrollView {
                    VStack(spacing: 20) {
                        // SP 카드
                        SpSummaryCard(
                            targetSP: currentSP,
                            weeklyTrend: weeklyTrend
                        )
                        .opacity(cardsVisible[0] ? 1 : 0)
                        .offset(y: cardsVisible[0] ? 0 : 20)
                        .animation(.easeOut(duration: 0.6), value: cardsVisible[0])
                        
                        // 랭크 카드
                        SpTierCard(
                            currentSP: currentSP,
                            currentRank: currentRank,
                            nextRankRequiredSP: nextRankRequiredSP
                        )
                        .opacity(cardsVisible[1] ? 1 : 0)
                        .offset(y: cardsVisible[1] ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: cardsVisible[1])
                        
                        // 순위 카드
                        PersonalRankCard(
                            currentRank: globalRank,
                            totalUsers: totalUsers,
                            weeklyChange: weeklyRankChange
                        )
                        .opacity(cardsVisible[2] ? 1 : 0)
                        .offset(y: cardsVisible[2] ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: cardsVisible[2])
                        
                        // SP 히스토리 카드
                        SpHistoryList(historyItems: spHistory)
                            .opacity(cardsVisible[3] ? 1 : 0)
                            .offset(y: cardsVisible[3] ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: cardsVisible[3])
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.turtleRunTheme.backgroundColor)
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            startFadeInAnimation()
        }
    }
    
    private func startFadeInAnimation() {
        // 순차적으로 카드들을 표시
        for i in 0..<cardsVisible.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                cardsVisible[i] = true
            }
        }
    }
}

#Preview {
    SpInfoScreen()
} 
