import Foundation
import UserNotifications
import UIKit
import SwiftUI
import HealthKit

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var deviceToken: String?
    @Published var isNotificationAuthorized: Bool = false
    @Published var pendingNotificationResponse: UNNotificationResponse?
    
    private override init() {
        super.init()
        setupNotificationCenter()
    }
    
    func requestNotificationAuthorization() {
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
        
        // Shell 동기화 완료 알림인지 확인 (통일된 타입 사용)
        if let notificationType = userInfo["type"] as? String,
           (notificationType == "sync_complete" || notificationType == "shell_sync_completed") {
            handleSyncCompleteNotification(userInfo)
        }
        
        // 포그라운드에서도 알림 표시 (iOS 14+ 호환성)
        if #available(iOS 14.0, *) {
            return [.banner, .badge, .sound]
        } else {
            return [.alert, .badge, .sound]
        }
    }
    
    /// 알림 탭 시 처리
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        print("👆 알림 탭됨:")
        print("   - 액션: \(response.actionIdentifier)")
        print("   - 데이터: \(userInfo)")
        
        // Shell 동기화 완료 알림 탭 처리 (통일된 타입 사용)
        if let notificationType = userInfo["type"] as? String,
           (notificationType == "sync_complete" || notificationType == "shell_sync_completed") {
            handleSyncCompleteNotificationTap(userInfo)
        }
    }
    
    // MARK: - Local Notification Scheduling
    
    /// Shell 동기화 완료 알림 스케줄링
    func scheduleShellSyncCompletionNotification(workoutData: WorkoutDetailedData) {
        let content = UNMutableNotificationContent()
        content.title = "🐢 TurtleRun"
        content.subtitle = "동기화 완료!"
        content.body = "새로운 Shell이 추가되었습니다. \(workoutData.formattedDistance), \(workoutData.formattedDuration)"
        content.sound = .default
        content.badge = 1
        
        // 사용자 정의 데이터 추가 (통일된 타입 사용)
        content.userInfo = [
            "type": "shell_sync_completed",
            "workout_start_date": workoutData.startDate.timeIntervalSince1970,
            "workout_duration": workoutData.duration,
            "workout_distance": workoutData.totalDistance,
            "workout_calories": workoutData.totalEnergyBurned
        ]
        
        // 즉시 트리거 (실제로는 서버 동기화 완료 후 호출)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "shell_sync_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Shell 동기화 알림 스케줄링 실패: \(error)")
            } else {
                print("✅ Shell 동기화 완료 알림이 스케줄되었습니다.")
            }
        }
    }
    
    /// 테스트 알림 스케줄링
    func scheduleTestNotification() {
        // 먼저 현재 알림 권한 상태 확인
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 알림 권한 상태: \(settings.authorizationStatus.rawValue)")
            print("🔔 Alert 설정: \(settings.alertSetting.rawValue)")
            print("🔔 Sound 설정: \(settings.soundSetting.rawValue)")
            print("🔔 Badge 설정: \(settings.badgeSetting.rawValue)")
            
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                    self.createAndScheduleTestNotification()
                } else {
                    print("❌ 알림 권한이 없습니다. 설정에서 권한을 허용해주세요.")
                }
            }
        }
    }
    
    /// 모든 알림 정리
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // iOS 16+ 호환성을 위한 배지 숫자 초기화
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("❌ 배지 초기화 실패: \(error)")
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
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
        
        // UI 업데이트를 위한 추가 처리
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String,
           (type == "sync_complete" || type == "shell_sync_completed") {
            DispatchQueue.main.async {
                self.pendingNotificationResponse = response
            }
        }
        
        completionHandler()
    }
}

// MARK: - Private Implementation
private extension PushNotificationManager {
    
    /// 알림 센터 델리게이트 설정
    func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// Push 알림 등록
    func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Sync 완료 알림 처리 로직
    func handleSyncCompleteNotification(_ userInfo: [AnyHashable: Any]) {
        print("🏃‍♂️ 운동 데이터 동기화 완료 알림 처리")
        
        // 추가적인 UI 업데이트나 데이터 새로고침 로직
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkoutSyncCompleted"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    /// Sync 완료 알림 탭 시 특정 화면으로 이동
    func handleSyncCompleteNotificationTap(_ userInfo: [AnyHashable: Any]) {
        print("📊 운동 데이터 화면으로 이동 예정...")
        
        // NavigationManager나 Router를 통한 화면 이동
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToWorkoutStats"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    /// 테스트 알림 생성 및 스케줄링
    func createAndScheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🐢 TurtleRun 테스트"
        content.subtitle = "동기화 완료!"
        content.body = "새로운 Shell이 추가되었습니다. 5.2km, 32:15"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "type": "shell_sync_completed",
            "workout_start_date": Date().addingTimeInterval(-3600).timeIntervalSince1970,
            "workout_duration": 1935.0, // 32분 15초
            "workout_distance": 5200.0,  // 5.2km
            "workout_calories": 380.0
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_shell_sync",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 테스트 알림 스케줄링 실패: \(error)")
            } else {
                print("✅ 테스트 알림이 2초 후에 표시됩니다.")
            }
        }
    }
    
    /// 한국 시간으로 포맷팅
    func formatKoreanTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date) + " (KST)"
    }
}

// MARK: - WorkoutDetailedData Extension for Notification
extension WorkoutDetailedData {
    static func fromNotificationUserInfo(_ userInfo: [AnyHashable: Any]) -> WorkoutDetailedData? {
        guard let startDateInterval = userInfo["workout_start_date"] as? TimeInterval,
              let duration = userInfo["workout_duration"] as? TimeInterval,
              let distance = userInfo["workout_distance"] as? Double,
              let calories = userInfo["workout_calories"] as? Double else {
            return nil
        }
        
        let startDate = Date(timeIntervalSince1970: startDateInterval)
        let endDate = startDate.addingTimeInterval(duration)
        
        let workout = HKWorkout(
            activityType: .running,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: distance),
            metadata: nil
        )
        
        return WorkoutDetailedData(workout: workout)
    }
}