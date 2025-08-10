import SwiftUI

struct MainShellDashboardScreen: View {
    @State private var showProfileMenu = false
    @EnvironmentObject private var notificationManager: NotificationManager
    
    var body: some View {
        ZStack {
            // 배경색
            VStack(spacing: 0) {
                // 상단 네비게이션 바
                TopBar(
                    title: "TurtleRun",
                    leftButton: .logo,
                    rightButton: .profile {
                        showProfileMenu = true
                    }
                )
                .zIndex(100)
                
                // 지도 영역
                ShellMap()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // 테스트 버튼 (개발용)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    testNotificationButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                }
            }
        }
        .background(Color.turtleRunTheme.backgroundColor)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showProfileMenu) {
            ProfileMenuScreen()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Test Notification Button
    private var testNotificationButton: some View {
        Button(action: {
            notificationManager.scheduleTestNotification()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                Text("테스트 알림")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .turtleRunTheme.accentColor,
                        .turtleRunTheme.secondaryColor
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    MainShellDashboardScreen()
        .environmentObject(NotificationManager.shared)
} 
