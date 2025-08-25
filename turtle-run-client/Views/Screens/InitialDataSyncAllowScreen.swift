import SwiftUI

struct InitialDataSyncAllowScreen: View {
    @State private var isWatchSyncAllowed = false
    @State private var isDataSyncAllowed = false
    @State private var watchSyncProgress: Double = 0
    @State private var dataSyncProgress: Double = 0
    @State private var showProgressScreen = false
    
    var body: some View {
        ZStack {
            // Background
            Color.turtleRunTheme.backgroundColor
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 45) {
                // Header
                VStack(spacing: 12) {
                    Text("데이터 연동")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.turtleRunTheme.textColor)
                    
                    Text("러닝 데이터를 연동하여 Shell을 생성해보세요")
                        .font(.system(size: 16))
                        .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
                }
                .padding(.top, 20)
                
                // Sync Sections
                VStack(spacing: 20) {
                    // Apple Watch Sync
                    DataSyncInfoCard(
                        icon: "⌚",
                        title: "애플워치 연동",
                        description: "애플워치의 피트니스 데이터를 연동하여 러닝 활동을 자동으로 기록합니다.",
                        status: isWatchSyncAllowed ? "승인 완료" : "승인 대기 중...",
                        progress: watchSyncProgress,
                        buttonTitle: isWatchSyncAllowed ? nil : "승인"
                    )
                    {
                       handleWatchSync()
                    }
                    
                    // Running Data Sync
                    DataSyncInfoCard(
                        icon: "📊",
                        title: "러닝 데이터 동기화",
                        description: "기존 러닝 세션 데이터를 동기화하여 Shell을 생성합니다. 최대 30일치의 데이터를 가져올 수 있습니다.",
                        status: isDataSyncAllowed ? "승인 완료" : "승인 대기 중",
                        progress: dataSyncProgress,
                        buttonTitle: isDataSyncAllowed ? nil : "데이터 동기화하기"
                    ) {
                        handleDataSync()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Next Button
                Button(action: handleNext) {
                    Text("다음")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.turtleRunTheme.textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isWatchSyncAllowed && isDataSyncAllowed ? Color.turtleRunTheme.accentColor : Color.turtleRunTheme.textSecondaryColor)
                        .cornerRadius(8)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isWatchSyncAllowed || !isDataSyncAllowed)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
            }
        }
        .fullScreenCover(isPresented: $showProgressScreen) {
            InitialDataSyncProgresSplashScreen(onSyncComplete: {
                // 동기화 완료 후 처리
                showProgressScreen = false
                isDataSyncAllowed = true
                dataSyncProgress = 1.0
            })
        }
    }
    
    private func handleWatchSync() {
        // Simulate watch sync progress
        withAnimation(.easeInOut(duration: 2)) {
            watchSyncProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isWatchSyncAllowed = true
        }
    }
    
    private func handleDataSync() {
        // 즉시 ProgressSplashScreen으로 전환
        showProgressScreen = true
    }
    
    private func handleNext() {
        // TODO: Navigate to next screen
        print("Next tapped")
    }
}

#Preview {
    InitialDataSyncAllowScreen()
}
