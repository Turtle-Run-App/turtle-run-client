import Foundation
import HealthKit
import Combine
import UserNotifications
import UIKit

class WorkoutDataService: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    @Published var latestWorkoutData: WorkoutDetailedData?
    @Published var isLoadingDetailedData: Bool = false
    @Published var syncStatus: String? = nil
    @Published var isInitialSyncInProgress: Bool = false
    @Published var isAutoSyncEnabled: Bool = false
    @Published var threeMonthSyncProgress: Double = 0.0
    @Published var threeMonthSyncStatus: String? = nil
    @Published var isThreeMonthSyncInProgress: Bool = false
    @Published var totalWorkoutsToSync: Int = 0
    @Published var syncedWorkoutsCount: Int = 0
    
    private let healthKitManager = HealthKitManager.shared
    
    // 중복 처리 방지를 위한 동시성 제어
    private var isProcessingWorkout = false
    private var processingWorkoutId: String?
    private var lastProcessedTime: Date?
    
    // 중복 알림 방지: 마지막으로 알림을 보낸 워크아웃 ID (UserDefaults에 저장)
    private var lastSyncedWorkoutId: String? {
        get {
            return UserDefaults.standard.string(forKey: "lastNotifiedWorkoutId")
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "lastNotifiedWorkoutId")
                print("💾 워크아웃 ID 저장됨: \(newValue.prefix(8))...")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastNotifiedWorkoutId")
                print("💾 워크아웃 ID 초기화됨")
            }
        }
    }
    
    // MARK: - Authorization
    func requestHealthKitAuthorization() {
        healthKitManager.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if !success {
                    self?.errorMessage = "HealthKit 권한이 필요합니다."
                }
            }
        }
    }
    
    // MARK: - Three Month Workout Data Sync
    func syncThreeMonthWorkoutData() {
        isThreeMonthSyncInProgress = true
        threeMonthSyncProgress = 0.0
        syncedWorkoutsCount = 0
        totalWorkoutsToSync = 0
        threeMonthSyncStatus = "3개월 데이터 동기화 시작..."
        
        // 먼저 권한 확인 및 요청
        healthKitManager.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isThreeMonthSyncInProgress = false
                    self?.threeMonthSyncStatus = "권한 요청 실패"
                    return
                }
                
                if !success {
                    self?.errorMessage = "HealthKit 권한이 필요합니다."
                    self?.isThreeMonthSyncInProgress = false
                    self?.threeMonthSyncStatus = "권한 거부됨"
                    return
                }
                
                // 3개월치 러닝 워크아웃 데이터 수집 및 동기화
                self?.threeMonthSyncStatus = "3개월 워크아웃 데이터 검색 중..."
                self?.healthKitManager.fetchRunningWorkoutsForPeriod(monthsBack: 3) { workouts in
                    guard !workouts.isEmpty else {
                        DispatchQueue.main.async {
                            self?.isThreeMonthSyncInProgress = false
                            self?.threeMonthSyncStatus = "3개월간 러닝 기록이 없습니다."
                            self?.threeMonthSyncProgress = 1.0
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.totalWorkoutsToSync = workouts.count
                        self?.threeMonthSyncStatus = "\(workouts.count)개 워크아웃 발견됨. 동기화 시작..."
                    }
                    
                    self?.syncAllThreeMonthWorkoutData(workouts: workouts)
                }
            }
        }
    }
    
    private func syncAllThreeMonthWorkoutData(workouts: [HKWorkout]) {
        let group = DispatchGroup()
        var allWorkoutData: [WorkoutDetailedData] = []
        var syncErrors: [String] = []
        let totalWorkouts = workouts.count
        
        for (index, workout) in workouts.enumerated() {
            group.enter()
            
            // 진행상황 업데이트
            DispatchQueue.main.async {
                self.threeMonthSyncStatus = "워크아웃 \(index + 1)/\(totalWorkouts) 처리 중..."
                self.threeMonthSyncProgress = Double(index) / Double(totalWorkouts) * 0.8 // 80%까지는 데이터 수집
            }
            
            healthKitManager.fetchCompleteWorkoutData(for: workout) { detailedData in
                allWorkoutData.append(detailedData)
                
                // 각 워크아웃 데이터를 서버에 동기화
                self.postWorkoutData(detailedData) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.syncedWorkoutsCount += 1
                            self.threeMonthSyncStatus = "워크아웃 동기화 완료: \(self.syncedWorkoutsCount)/\(totalWorkouts)"
                        } else {
                            syncErrors.append("워크아웃 \(workout.uuid.uuidString): \(error ?? "알 수 없는 오류")")
                        }
                        
                        // 진행률 업데이트 (80% + 각 워크아웃당 20%/totalWorkouts)
                        let currentProgress = 0.8 + (Double(self.syncedWorkoutsCount + syncErrors.count) / Double(totalWorkouts)) * 0.2
                        self.threeMonthSyncProgress = min(currentProgress, 1.0)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isThreeMonthSyncInProgress = false
            self.threeMonthSyncProgress = 1.0
            
            if syncErrors.isEmpty {
                self.threeMonthSyncStatus = "3개월 동기화 완료! 총 \(allWorkoutData.count)개 워크아웃"
            } else {
                self.threeMonthSyncStatus = "동기화 완료 (성공: \(self.syncedWorkoutsCount), 실패: \(syncErrors.count))"
                self.errorMessage = syncErrors.joined(separator: "\n")
            }
        }
    }
    
    // MARK: - Initial Workout Data Sync
    func syncInitialWorkoutData() {
        isInitialSyncInProgress = true
        syncStatus = "초기 데이터 동기화 시작..."
        
        // 먼저 권한 확인 및 요청
        healthKitManager.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isInitialSyncInProgress = false
                    self?.syncStatus = "권한 요청 실패"
                    return
                }
                
                if !success {
                    self?.errorMessage = "HealthKit 권한이 필요합니다."
                    self?.isInitialSyncInProgress = false
                    self?.syncStatus = "권한 거부됨"
                    return
                }
                
                // 권한이 있으면 모든 러닝 워크아웃 데이터 수집 및 동기화
                self?.healthKitManager.fetchRecentRunningWorkouts(limit: 50) { workouts in
                    guard !workouts.isEmpty else {
                        DispatchQueue.main.async {
                            self?.isInitialSyncInProgress = false
                            self?.syncStatus = "동기화할 러닝 기록이 없습니다."
                        }
                        return
                    }
                    
                    self?.syncAllWorkoutData(workouts: workouts)
                }
            }
        }
    }
    
    private func syncAllWorkoutData(workouts: [HKWorkout]) {
        print("📱 \(workouts.count)개 워크아웃 데이터 로드 시작...")
        
        // 단순히 데이터 개수만 확인 (서버 전송 없음)
        DispatchQueue.main.async {
            self.isInitialSyncInProgress = false
            self.syncStatus = "워크아웃 데이터 확인 완료: \(workouts.count)개"
            print("✅ 초기 워크아웃 데이터 확인 완료: \(workouts.count)개")
        }
    }
    
    // MARK: - Latest Workout Data (기존 로직 유지)
    func loadLatestWorkoutDetailedData() {
        isLoadingDetailedData = true
        
        // 먼저 권한 확인 및 요청
        healthKitManager.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoadingDetailedData = false
                    return
                }
                
                if !success {
                    self?.errorMessage = "HealthKit 권한이 필요합니다."
                    self?.isLoadingDetailedData = false
                    return
                }
                
                // 권한이 있으면 데이터 수집
                self?.healthKitManager.fetchRecentRunningWorkouts(limit: 1) { workouts in
                    guard let workout = workouts.first else {
                        DispatchQueue.main.async {
                            self?.isLoadingDetailedData = false
                            self?.errorMessage = "최근 러닝 기록이 없습니다."
                        }
                        return
                    }
                    
                    self?.healthKitManager.fetchCompleteWorkoutData(for: workout) { detailedData in
                        DispatchQueue.main.async {
                            self?.latestWorkoutData = detailedData
                            self?.isLoadingDetailedData = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Data Check  
    func checkLatestWorkoutData() {
        print("📱 최근 워크아웃 데이터 확인 중...")
        
        healthKitManager.fetchRecentRunningWorkouts(limit: 1) { [weak self] workouts in
            guard let workout = workouts.first else {
                DispatchQueue.main.async { 
                    self?.syncStatus = "러닝 기록이 없습니다."
                    print("⚠️ 러닝 기록이 없습니다.")
                }
                return
            }
            
            // 간단한 워크아웃 정보만 확인
            DispatchQueue.main.async {
                let duration = Int(workout.duration / 60)
                self?.syncStatus = "최근 러닝: \(duration)분"
                print("✅ 최근 러닝 확인: \(duration)분, \(workout.startDate)")
            }
        }
    }
    

    
    // MARK: - Automatic Notification Management
    
    /// 자동 알림 시작 - 새로운 워크아웃 완료 시 자동으로 로컬 알림 발송
    func startAutoSync() {
        guard !isAutoSyncEnabled else {
            print("⚠️ 자동 알림이 이미 활성화되어 있습니다.")
            return
        }
        
        print("🚀 운동 완료 자동 알림 시작")
        
        // 기존 저장된 마지막 알림 워크아웃 ID 확인
        if let lastId = lastSyncedWorkoutId {
            print("📂 마지막 알림 워크아웃 ID: \(lastId.prefix(8))... (중복 방지)")
        } else {
            print("📂 저장된 워크아웃 기록 없음 (첫 실행)")
        }
        
        isAutoSyncEnabled = true
        
        // HealthKit Observer 시작
        healthKitManager.startWorkoutObserver { [weak self] in
            print("🔔 새로운 워크아웃 감지됨!")
            
            guard let strongSelf = self else {
                print("❌ WorkoutDataService 객체가 해제되어 처리를 건너뜁니다.")
                return
            }
            
            strongSelf.handleNewWorkoutDetected()
        }
        
        print("✅ 자동 알림 시작 완료")
    }
    
    /// 개발/테스트용: 저장된 워크아웃 ID 초기화 (모든 운동에 대해 다시 알림 받고 싶을 때)
    func clearLastNotifiedWorkoutId() {
        guard !isProcessingWorkout else {
            print("⚠️ 워크아웃 처리 중이므로 ID 초기화를 건너뜁니다.")
            return
        }
        
        lastSyncedWorkoutId = nil
        print("🗑️ 저장된 워크아웃 ID 초기화 완료 - 모든 운동에 대해 알림 재활성화됨")
    }
    
    /// 자동 알림 중지
    func stopAutoSync() {
        guard isAutoSyncEnabled else {
            print("⚠️ 자동 알림이 이미 비활성화되어 있습니다.")
            return
        }
        
        print("🛑 자동 알림 중지")
        isAutoSyncEnabled = false
        healthKitManager.stopWorkoutObserver()
    }
    
    /// 새로운 워크아웃이 감지되었을 때 처리하는 메서드
    private func handleNewWorkoutDetected() {
        print("📱 워크아웃 데이터 처리 시작")
        
        // 권한이 있는지 먼저 확인
        guard isAuthorized else {
            print("❌ HealthKit 권한이 없어서 동기화를 건너뜁니다.")
            return
        }
        
        // 이미 동기화가 진행 중이면 건너뛰기
        guard !isInitialSyncInProgress && !isLoadingDetailedData else {
            print("⚠️ 다른 동기화가 진행 중이므로 건너뜁니다.")
            return
        }
        
        // 🔥 동시성 제어: 이미 워크아웃 처리 중이면 건너뛰기
        guard !isProcessingWorkout else {
            print("⚠️ 현재 워크아웃 처리 중입니다. 중복 요청 무시됨.")
            return
        }
        
        // 🔥 Debouncing: 너무 빠른 연속 호출 방지 (3초 내)
        let now = Date()
        if let lastTime = lastProcessedTime, now.timeIntervalSince(lastTime) < 3.0 {
            print("⚠️ 너무 빠른 연속 호출 - \(String(format: "%.1f", now.timeIntervalSince(lastTime)))초 전에 처리됨")
            return
        }
        
        lastProcessedTime = now
        
        // 최근 워크아웃을 확인해서 알림 발송
        checkRecentWorkoutForNotification()
    }
    
    /// 최근 워크아웃이 새로운 것인지 확인하고 로컬 알림 발송
    private func checkRecentWorkoutForNotification() {
        // 🔥 처리 시작
        isProcessingWorkout = true
        
        healthKitManager.fetchRecentRunningWorkouts(limit: 1) { [weak self] workouts in
            // 안전장치: self가 해제된 경우 처리 플래그 해제
            defer {
                self?.isProcessingWorkout = false
                self?.processingWorkoutId = nil
            }
            
            guard let workout = workouts.first else {
                print("⚠️ 최근 러닝 워크아웃이 없습니다.")
                return
            }
            
            let workoutId = workout.uuid.uuidString
            print("🏃‍♂️ 워크아웃 확인 중: \(workoutId.prefix(8))...")
            
            // 🔥 같은 워크아웃이 이미 처리 중인지 확인
            if let currentProcessingId = self?.processingWorkoutId, currentProcessingId == workoutId {
                print("⚠️ 같은 워크아웃이 이미 처리 중입니다. (ID: \(workoutId.prefix(8))...)")
                return
            }
            
            // 현재 처리 중인 워크아웃 ID 설정
            self?.processingWorkoutId = workoutId
            
            // 🔥 중요: 운동이 실제로 완료되었는지 확인
            guard self?.isWorkoutCompleted(workout) == true else {
                print("⚠️ 운동이 아직 진행 중입니다. 완료될 때까지 대기...")
                return
            }
            
            print("✅ 운동 완료 확인됨!")
            
            // 이미 알림을 보낸 워크아웃인지 확인
            if let lastNotifiedId = self?.lastSyncedWorkoutId, lastNotifiedId == workoutId {
                print("⚠️ 이미 알림을 보낸 워크아웃입니다. (ID: \(workoutId.prefix(8))...)")
                return
            }
            
            print("🆕 새로운 워크아웃 발견! 알림 발송 시작...")
            
            // 워크아웃 데이터 가져오기 및 로컬 알림 발송
            self?.healthKitManager.fetchCompleteWorkoutData(for: workout) { detailedData in
                // 데이터 fetch가 성공한 경우에만 처리
                guard detailedData.workout.uuid == workout.uuid else {
                    print("❌ 워크아웃 데이터 불일치 - 알림 건너뜀")
                    return
                }
                
                // 중복 방지를 위해 workoutId 저장 (성공한 경우에만)
                self?.lastSyncedWorkoutId = workoutId
                
                // 운동 데이터 로깅
                self?.logWorkoutDataForLocalNotification(detailedData)
                
                // 바로 로컬 알림 발송
                self?.sendLocalNotificationForWorkoutComplete(workoutData: detailedData)
            }
        }
    }
    
    /// 워크아웃이 실제로 완료되었는지 확인
    private func isWorkoutCompleted(_ workout: HKWorkout) -> Bool {
        let now = Date()
        let workoutEndDate = workout.endDate
        let workoutStartDate = workout.startDate
        
        // 기본 검증: 운동 시간이 최소 5초 이상이어야 함  
        guard workout.duration >= 5.0 else {
            print("   ❌ 운동 시간이 너무 짧습니다: \(Int(workout.duration))초")
            return false
        }
        
        // 시작/종료 시간 검증
        guard workoutEndDate > workoutStartDate else {
            print("   ❌ 운동 종료 시간이 시작 시간보다 이릅니다")
            return false
        }
        
        // 운동이 현재 시간보다 최소 0.5초 전에 완료되었는지 확인
        // (HealthKit 데이터 처리를 위한 최소 버퍼)
        let completionBufferTime: TimeInterval = 0.5
        let timeSinceWorkoutEnded = now.timeIntervalSince(workoutEndDate)
        
        guard timeSinceWorkoutEnded >= completionBufferTime else {
            print("   ⏰ 운동이 너무 최근에 완료됨: \(String(format: "%.1f", timeSinceWorkoutEnded))초 전")
            return false
        }
        
        // 운동이 24시간 이내에 완료되었는지 확인 (너무 오래된 데이터 제외)
        let maxWorkoutAge: TimeInterval = 24 * 60 * 60 // 24시간
        guard timeSinceWorkoutEnded <= maxWorkoutAge else {
            print("   ❌ 운동 데이터가 너무 오래됨: \(Int(timeSinceWorkoutEnded / 3600))시간 전")
            return false
        }
        
        // 모든 조건 통과
        let durationMinutes = Int(workout.duration / 60)
        let durationSeconds = Int(workout.duration.truncatingRemainder(dividingBy: 60))
        print("   ✅ 운동 완료 확인: \(durationMinutes)분 \(durationSeconds)초, \(String(format: "%.1f", timeSinceWorkoutEnded))초 전 종료")
        
        return true
    }
    
        /// 운동 완료 데이터 로깅 (간소화 버전)
    private func logWorkoutDataForLocalNotification(_ data: WorkoutDetailedData) {
        let distanceKm = String(format: "%.2f", data.totalDistance/1000.0)
        let durationMin = Int(data.duration/60)
        let calories = Int(data.totalEnergyBurned)
        print("📱 운동 완료: \(distanceKm)km, \(durationMin)분, \(calories)kcal")
    }
    
    /// 운동 완료 시 로컬 알림 전송
    private func sendLocalNotificationForWorkoutComplete(workoutData: WorkoutDetailedData) {
        // 앱 상태 확인
        let appState = UIApplication.shared.applicationState
        let stateString = appState == .background ? "백그라운드" : (appState == .active ? "포그라운드" : "비활성")
        print("🔔 운동 완료 로컬 알림 전송 중... (앱 상태: \(stateString))")
        
        // 운동 정보 요약
        let distanceKm = workoutData.totalDistance / 1000.0
        let durationMinutes = Int(workoutData.duration / 60)
        let calories = Int(workoutData.totalEnergyBurned)
        
        let content = UNMutableNotificationContent()
        content.title = "🏃‍♂️ 운동 완료!"
        
        // 운동 데이터에 따른 개인화된 메시지
        if distanceKm > 0.1 {
            content.body = "\(String(format: "%.1f", distanceKm))km, \(durationMinutes)분 러닝을 완료했습니다. 수고하셨습니다!"
        } else {
            content.body = "\(durationMinutes)분 운동을 완료했습니다. 수고하셨습니다!"
        }
        
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // 알림 데이터
        content.userInfo = [
            "type": "workout_complete",
            "workoutId": workoutData.workout.uuid.uuidString,
            "distance": distanceKm,
            "duration": workoutData.duration,
            "calories": calories,
            "isLocal": true
        ]
        
        // 즉시 알림 표시
        let request = UNNotificationRequest(
            identifier: "workout_complete_\(workoutData.workout.uuid.uuidString)",
            content: content,
            trigger: nil
        )
        
        // 백그라운드에서도 확실한 알림 전송을 위한 Background Task 시작
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        
        if appState == .background {
            print("🌙 백그라운드 상태 - Background Task로 알림 전송 보장")
            // 중복 Background Task 방지를 위해 고유 식별자 사용
            let taskName = "WorkoutNotification_\(workoutData.workout.uuid.uuidString.prefix(8))"
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: taskName) {
                // 시간 초과 시 정리
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
            }
        }
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 로컬 알림 전송 실패: \(error.localizedDescription)")
                } else {
                    let appStateText = appState == .background ? "백그라운드" : "포그라운드"
                    print("✅ 운동 완료 알림 전송 성공! (\(appStateText))")
                }
                
                // Background Task 종료
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
            }
        }
    }
    
    /// 앱이 종료될 때 자동으로 호출되어야 하는 정리 메서드
    deinit {
        stopAutoSync()
    }
    

    
    // MARK: - Helper Methods - Time Formatting
    
    /// 한국 시간으로 포맷팅
    private func formatKoreanTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date) + " (KST)"
    }
} 
