import Foundation
import UserNotifications
import UIKit

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var deviceToken: String?
    @Published var isNotificationAuthorized: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Notification Authorization
    
    /// 푸시 알림 권한 요청 (백그라운드 알림 포함)
    func requestNotificationAuthorization() {
        // 백그라운드에서도 알림을 받을 수 있도록 모든 필요 옵션 포함
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .carPlay]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = granted
                
                if granted {
                    print("✅ Push 알림 권한 승인됨")
                    self?.registerForPushNotifications()
                } else {
                    print("❌ Push 알림 권한 거부됨")
                    if let error = error {
                        print("오류: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Push 알림 등록
    private func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Device Token Management
    
    /// Device Token 수신 처리  
    func didReceiveDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        print("📱 Device Token 수신됨: \(tokenString.prefix(16))...")
        
        DispatchQueue.main.async {
            self.deviceToken = tokenString
            print("✅ Device Token 저장 완료")
        }
    }
    
    /// Device Token 등록 실패 처리
    func didFailToRegisterForPush(with error: Error) {
        print("❌ Push 알림 등록 실패: \(error.localizedDescription)")
    }
    
        // MARK: - Notification Handling
    
    /// 앱이 활성 상태일 때 알림 수신 처리
    func handleForegroundNotification(_ notification: UNNotification) -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        
        print("🔔 포그라운드 알림 수신:")
        print("   - 제목: \(notification.request.content.title)")
        print("   - 내용: \(notification.request.content.body)")
        print("   - 데이터: \(userInfo)")
        
        // Sync 완료 알림인지 확인
        if let notificationType = userInfo["type"] as? String,
           notificationType == "sync_complete" {
            handleSyncCompleteNotification(userInfo)
        }
        
        // 포그라운드에서도 알림 표시
        return [.alert, .badge, .sound]
    }
    
    /// 알림 탭 시 처리
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        print("👆 알림 탭됨:")
        print("   - 액션: \(response.actionIdentifier)")
        print("   - 데이터: \(userInfo)")
        
        // Sync 완료 알림 탭 처리
        if let notificationType = userInfo["type"] as? String,
           notificationType == "sync_complete" {
            handleSyncCompleteNotificationTap(userInfo)
        }
    }
    
    // MARK: - Sync Complete Notification Handling
    
    /// Sync 완료 알림 처리 로직
    private func handleSyncCompleteNotification(_ userInfo: [AnyHashable: Any]) {
        print("🏃‍♂️ 운동 데이터 동기화 완료 알림 처리")
        
        // 추가적인 UI 업데이트나 데이터 새로고침 로직
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkoutSyncCompleted"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    /// Sync 완료 알림 탭 시 특정 화면으로 이동
    private func handleSyncCompleteNotificationTap(_ userInfo: [AnyHashable: Any]) {
        print("📊 운동 데이터 화면으로 이동 예정...")
        
        // 추후 NavigationManager나 Router를 통해 특정 화면 이동 구현
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToWorkoutStats"),
            object: nil,
            userInfo: userInfo
        )
    }
    

    
    // MARK: - Helper Methods
    
    /// 한국 시간으로 포맷팅
    private func formatKoreanTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date) + " (KST)"
    }
    
    }

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    /// 앱이 포그라운드에 있을 때 알림 수신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let options = handleForegroundNotification(notification)
        completionHandler(options)
    }
    
    /// 알림 상호작용 처리 (탭, 액션 등)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
} 