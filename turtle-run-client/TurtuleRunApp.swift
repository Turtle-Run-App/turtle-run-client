import SwiftUI
import SwiftData
import UserNotifications

@main
struct TurtleRunApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var workoutDataService = WorkoutDataService()
    @StateObject private var pushNotificationManager = PushNotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutDataService)
                .environmentObject(pushNotificationManager)
                .onAppear {
                    pushNotificationManager.requestNotificationAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // MARK: - App Lifecycle Management for Auto Sync
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // 앱이 활성화되었을 때 자동 동기화 시작
            print("📱 앱 활성화됨 - 자동 알림 상태 확인 중...")
            startAutoSyncIfNeeded()
            
        case .inactive:
            // 앱이 비활성화되었을 때 (전화 수신 등)
            print("📱 앱 비활성화됨")
            
        case .background:
            // 앱이 백그라운드로 전환되었을 때
            print("📱 앱 백그라운드 전환됨 - 운동 감지는 계속 동작")
            // 백그라운드에서도 운동 감지가 활성 상태인지 확인
            ensureBackgroundWorkoutDetection()
            
        @unknown default:
            print("📱 알 수 없는 씬 페이즈: \(newPhase)")
        }
    }
    
    /// 백그라운드에서도 운동 감지가 확실히 동작하도록 보장
    private func ensureBackgroundWorkoutDetection() {
        print("🌙 백그라운드 운동 감지 상태 확인...")
        
        // 자동 동기화가 활성화되어 있는지 확인
        if workoutDataService.isAutoSyncEnabled {
            print("✅ 운동 감지 활성 상태 - 백그라운드에서도 계속 동작")
        } else {
            print("⚠️ 운동 감지 비활성 상태 - 백그라운드에서 재시작 시도")
            workoutDataService.startAutoSync()
        }
    }
    
    private func startAutoSyncIfNeeded() {
        // HealthKit 권한 요청 및 자동 동기화 시작
        workoutDataService.requestHealthKitAuthorization()
        
        // 권한 확인 후 자동 동기화 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.workoutDataService.isAuthorized {
                print("✅ HealthKit 권한 승인됨")
                self.workoutDataService.startAutoSync()
            } else {
                print("⚠️ HealthKit 권한이 필요합니다")
            }
        }
    }
}
