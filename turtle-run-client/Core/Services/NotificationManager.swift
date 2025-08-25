import Foundation
import UserNotifications
import SwiftUI
import HealthKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var pendingNotificationResponse: UNNotificationResponse?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Request
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("알림 권한 요청 실패: \(error)")
            return false
        }
    }
    
    // MARK: - Shell Sync Completion Notification
    func scheduleShellSyncCompletionNotification(workoutData: WorkoutDetailedData) {
        let content = UNMutableNotificationContent()
        content.title = "🐢 TurtleRun"
        content.subtitle = "동기화 완료!"
        content.body = "새로운 Shell이 추가되었습니다. \(workoutData.formattedDistance), \(workoutData.formattedDuration)"
        content.sound = .default
        content.badge = 1
        
        // 사용자 정의 데이터 추가
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
                print("알림 스케줄링 실패: \(error)")
            } else {
                print("Shell 동기화 완료 알림이 스케줄되었습니다.")
            }
        }
    }
    
    // MARK: - Test Notification (개발용)
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
    
    private func createAndScheduleTestNotification() {
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
    
    // MARK: - Clear Notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // 앱이 foreground에 있을 때 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // foreground에서도 알림 표시
        completionHandler([.banner, .sound, .badge])
    }
    
    // 사용자가 알림을 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let type = userInfo["type"] as? String,
              type == "shell_sync_completed" else {
            return
        }
        
        // 메인 스레드에서 UI 업데이트
        DispatchQueue.main.async {
            self.pendingNotificationResponse = response
        }
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
