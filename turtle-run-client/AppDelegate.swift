import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    // MARK: - Application Lifecycle
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        print("📱 AppDelegate - 앱 시작 완료")
        
        // Push 알림 기본 설정은 TurtleRunApp에서 처리
        return true
    }
    
    // MARK: - Push Notifications
    
    /// Device Token 등록 성공
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("📱 AppDelegate - Device Token 등록 성공")
        PushNotificationManager.shared.didReceiveDeviceToken(deviceToken)
    }
    
    /// Device Token 등록 실패
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("📱 AppDelegate - Device Token 등록 실패")
        PushNotificationManager.shared.didFailToRegisterForPush(with: error)
    }
    
    /// 백그라운드 원격 알림 수신 (현재는 로컬 알림만 사용하므로 간소화)
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📱 AppDelegate - 원격 알림 수신 (로컬 알림 전용 앱)")
        completionHandler(.noData)
    }
} 