import SwiftUI

struct RunningStatsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cardsAppeared = [false, false, false, false]
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // 상단 바
                TopBar(
                    title: "러닝 통계",
                    leftButton: .back {
                        dismiss()
                    },
                    rightButton: .logo,
                )
                
                // 메인 콘텐츠
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 주요 통계 카드
                        RunningStatsMainCard()
                            .opacity(cardsAppeared[0] ? 1 : 0)
                            .offset(y: cardsAppeared[0] ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: cardsAppeared[0])
                        
                        // 이번 달 활동 카드
                        MonthlyActivityCard()
                            .opacity(cardsAppeared[1] ? 1 : 0)
                            .offset(y: cardsAppeared[1] ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: cardsAppeared[1])
                        
                        // 개인 기록 카드
                        PersonalRecordsCard()
                            .opacity(cardsAppeared[2] ? 1 : 0)
                            .offset(y: cardsAppeared[2] ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: cardsAppeared[2])
                        
                        // 페이스 분석 카드
                        PaceAnalysisCard()
                            .opacity(cardsAppeared[3] ? 1 : 0)
                            .offset(y: cardsAppeared[3] ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.9), value: cardsAppeared[3])
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.turtleRunTheme.backgroundColor)
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            startCardAnimations()
        }
    }
    
    private func startCardAnimations() {
        // 순차적으로 카드 등장 애니메이션
        for i in 0..<cardsAppeared.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                cardsAppeared[i] = true
            }
        }
    }
}

#Preview {
    RunningStatsScreen()
} 
