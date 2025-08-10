import SwiftUI

struct MainShellDashboardScreen: View {
    @State private var showProfileMenu = false
    
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
        }
        .background(Color.turtleRunTheme.backgroundColor)
        .navigationBarHidden(true)
//        .fullScreenCover(isPresented: $showProfileMenu) {
//            ProfileMenuScreen()
//        }
        .ignoresSafeArea()
    }
}

#Preview {
    MainShellDashboardScreen()
} 
