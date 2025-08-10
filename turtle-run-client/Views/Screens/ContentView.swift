import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var showingRecentShellDetail = false
    @State private var recentShellData: WorkoutDetailedData?
    
    var body: some View {
        MainShellDashboardScreen()
            .sheet(isPresented: $showingRecentShellDetail) {
                if let shellData = recentShellData {
                    RecentShellDetailScreen(workoutData: shellData)
                }
            }
            .onReceive(notificationManager.$pendingNotificationResponse) { response in
                handleNotificationResponse(response)
            }
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse?) {
        guard let response = response else { return }
        
        let userInfo = response.notification.request.content.userInfo
        
        // Shell 동기화 완료 알림인지 확인
        if let type = userInfo["type"] as? String,
           type == "shell_sync_completed" {
            
            // 알림 데이터로부터 WorkoutDetailedData 생성
            if let workoutData = WorkoutDetailedData.fromNotificationUserInfo(userInfo) {
                recentShellData = workoutData
                showingRecentShellDetail = true
            }
            
            // 처리 완료 후 pendingNotificationResponse 초기화
            notificationManager.pendingNotificationResponse = nil
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationManager.shared)
        // .environmentObject(WorkoutDataService())
}
