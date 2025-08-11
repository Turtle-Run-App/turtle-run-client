import SwiftUI
import SwiftData

@main
struct TurtleRunApp: App {
    @StateObject private var workoutDataService = WorkoutDataService()
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
            print("📱 앱 활성화됨")
            startAutoSyncIfNeeded()
            
        case .inactive:
            // 앱이 비활성화되었을 때 (전화 수신 등)
            print("📱 앱 비활성화됨")
            
        case .background:
            // 앱이 백그라운드로 전환되었을 때
            print("📱 앱 백그라운드 전환됨 - 운동 감지는 계속 동작")
            
        @unknown default:
            print("📱 알 수 없는 씬 페이즈: \(newPhase)")
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
