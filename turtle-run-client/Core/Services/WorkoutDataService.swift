import Foundation
import HealthKit
import Combine

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
    private var lastSyncedWorkoutId: String? = nil
    private var periodicTimer: Timer?
    
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
        // TODO: Bulk Sync API 구현 후 수정 예정
        let group = DispatchGroup()
        var allWorkoutData: [WorkoutDetailedData] = []
        var syncErrors: [String] = []
        
        for (_, workout) in workouts.enumerated() {
            group.enter()
            
            healthKitManager.fetchCompleteWorkoutData(for: workout) { detailedData in
                allWorkoutData.append(detailedData)
                
                // 각 워크아웃 데이터를 서버에 동기화
                self.postWorkoutData(detailedData) { success, error in
                    if !success {
                        syncErrors.append("워크아웃 \(workout.uuid.uuidString): \(error ?? "알 수 없는 오류")")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isInitialSyncInProgress = false
            
            if syncErrors.isEmpty {
                self.syncStatus = "초기 동기화 완료: \(allWorkoutData.count)개 워크아웃"
            } else {
                self.syncStatus = "동기화 완료 (일부 오류: \(syncErrors.count)개)"
                self.errorMessage = syncErrors.joined(separator: "\n")
            }
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
    
    // MARK: - Sync Data
    func syncLatestWorkoutRoute() {
        // 1. 최근 워크아웃 가져오기
        healthKitManager.fetchRecentRunningWorkouts(limit: 1) { [weak self] workouts in
            guard let workout = workouts.first else {
                DispatchQueue.main.async { self?.syncStatus = "러닝 기록이 없습니다." }
                return
            }
            
            // 2. 전체 워크아웃 데이터 가져오기
            self?.healthKitManager.fetchCompleteWorkoutData(for: workout) { detailedData in
                // 3. JSON 변환 - 지정된 형식으로
                let payload = self?.createWorkoutPayload(from: detailedData) ?? [:]
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
                    DispatchQueue.main.async { self?.syncStatus = "JSON 변환 실패" }
                    return
                }
                
                // 4. API POST
                self?.postRouteData(jsonData: jsonData)
            }
        }
    }
    
    // MARK: - Automatic Sync Management
    
    /// 자동 동기화 시작 - 새로운 워크아웃이 추가될 때마다 자동으로 서버에 동기화
    func startAutoSync() {
        guard !isAutoSyncEnabled else {
            print("⚠️ 자동 동기화가 이미 활성화되어 있습니다.")
            return
        }
        
        print("🚀 운동 종료 자동 감지 시작")
        print("   - HealthKit 권한 상태: \(isAuthorized)")
        
        isAutoSyncEnabled = true
        
        // HealthKit Observer 시작
        healthKitManager.startWorkoutObserver { [weak self] in
            print("🔔 HealthKit Observer 콜백 실행됨! - 새로운 워크아웃 감지")
            print("   - 콜백 실행 시간: \(Date())")
            
            guard let strongSelf = self else {
                print("❌ self가 nil이 되어 워크아웃 처리를 건너뜁니다.")
                return
            }
            
            print("✅ self 존재 확인 완료, handleNewWorkoutDetected 호출")
            strongSelf.handleNewWorkoutDetected()
        }
        
        // Fallback: 주기적으로 최근 워크아웃 체크 (30초마다)
        startPeriodicWorkoutCheck()
        
        print("✅ 자동 감지 설정 완료")
    }
    
    /// 자동 동기화 중지
    func stopAutoSync() {
        guard isAutoSyncEnabled else {
            print("⚠️ 자동 동기화가 이미 비활성화되어 있습니다.")
            return
        }
        
        print("🛑 운동 종료 자동 감지 중지")
        isAutoSyncEnabled = false
        
        // HealthKit Observer 중지
        healthKitManager.stopWorkoutObserver()
        
        // 주기적 체크 중지
        stopPeriodicWorkoutCheck()
    }
    
    /// Observer fallback용 주기적 워크아웃 체크 시작
    private func startPeriodicWorkoutCheck() {
        print("⏰ 주기적 워크아웃 체크 시작 (30초 간격)")
        
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            print("🔄 주기적 워크아웃 체크 실행...")
            self?.handleNewWorkoutDetected()
        }
    }
    
    /// 주기적 워크아웃 체크 중지
    private func stopPeriodicWorkoutCheck() {
        periodicTimer?.invalidate()
        periodicTimer = nil
        print("⏰ 주기적 워크아웃 체크 중지")
    }
    
    /// 수동으로 최근 워크아웃 동기화 테스트 (디버깅용)
    func testManualWorkoutSync() {
        print("🧪 수동 워크아웃 동기화 테스트 시작...")
        print("   - 현재 시간: \(Date())")
        print("   - 권한 상태: \(isAuthorized)")
        print("   - 자동 감지 활성화: \(isAutoSyncEnabled)")
        
        // 권한 확인
        guard isAuthorized else {
            print("❌ HealthKit 권한이 필요합니다.")
            return
        }
        
        handleNewWorkoutDetected()
    }
    
    /// 새로운 워크아웃이 감지되었을 때 처리하는 메서드
    private func handleNewWorkoutDetected() {
        print("📱 handleNewWorkoutDetected 실행됨")
        print("   - 현재 시간: \(Date())")
        print("   - 권한 상태: \(isAuthorized)")
        print("   - 초기 동기화 진행 중: \(isInitialSyncInProgress)")
        print("   - 상세 데이터 로딩 중: \(isLoadingDetailedData)")
        
        // 권한이 있는지 먼저 확인
        guard isAuthorized else {
            print("❌ HealthKit 권한이 없어서 동기화를 건너뜁니다.")
            return
        }
        
        // 이미 동기화가 진행 중이면 건너뛰기
        guard !isInitialSyncInProgress && !isLoadingDetailedData else {
            print("⚠️ 다른 동기화가 진행 중이므로 건너뜁니다.")
            print("   - 초기 동기화 중: \(isInitialSyncInProgress)")
            print("   - 상세 데이터 로딩 중: \(isLoadingDetailedData)")
            return
        }
        
        print("✅ 조건 확인 완료, 최근 워크아웃 확인 시작")
        
        // 최근 워크아웃을 가져와서 동기화
        syncRecentWorkoutIfNew()
    }
    
    /// 최근 워크아웃이 새로운 것인지 확인하고 JSON 형태로 동기화
    private func syncRecentWorkoutIfNew() {
        print("🔍 최근 워크아웃 데이터 확인 중...")
        
        healthKitManager.fetchRecentRunningWorkouts(limit: 1) { [weak self] workouts in
            print("📋 HealthKit에서 워크아웃 조회 결과: \(workouts.count)개")
            
            guard let workout = workouts.first else {
                print("⚠️ 최근 러닝 워크아웃이 없습니다.")
                return
            }
            
            let workoutId = workout.uuid.uuidString
            print("🆔 발견된 워크아웃 ID: \(workoutId.prefix(8))...")
            print("⏰ 운동 시간: \(workout.startDate) ~ \(workout.endDate)")
            
            // 이미 동기화한 워크아웃인지 확인
            if let lastSyncedId = self?.lastSyncedWorkoutId, lastSyncedId == workoutId {
                print("⚠️ 이미 동기화된 워크아웃입니다: \(workoutId.prefix(8))...")
                return
            }
            
            print("🏃‍♂️ 새로운 워크아웃 발견! 서버 전송 시작")
            
            // 워크아웃 데이터 가져오기 및 JSON으로 동기화
            self?.healthKitManager.fetchCompleteWorkoutData(for: workout) { detailedData in
                print("📊 상세 워크아웃 데이터 수집 완료")
                
                // 전송할 데이터 로깅
                self?.logWorkoutDataForAutoSync(detailedData)
                
                // 서버로 JSON 데이터 전송
                print("🚀 http://127.0.0.1/syncworkout 으로 데이터 전송 시작...")
                
                self?.postWorkoutData(detailedData) { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            self?.lastSyncedWorkoutId = workoutId
                            print("✅ 운동 데이터 자동 전송 완료!")
                            print("🎉 서버 전송 성공 시간: \(Date())")
                        } else {
                            print("❌ 운동 데이터 자동 전송 실패: \(error ?? "알 수 없는 오류")")
                        }
                    }
                }
            }
        }
    }
    
    /// 운동 종료 후 자동 전송되는 데이터 로깅 (간단 버전)
    private func logWorkoutDataForAutoSync(_ data: WorkoutDetailedData) {
        print("📤 서버로 전송되는 운동 데이터:")
        print("   🏃‍♂️ 운동: \(String(format: "%.2f", data.totalDistance/1000.0))km, \(Int(data.duration/60))분")
        print("   💓 심박수: 평균 \(Int(data.averageHeartRate))bpm")
        print("   🔥 칼로리: \(Int(data.totalEnergyBurned))kcal")
        print("   🗺️ GPS: \(data.routePoints.count)개 위치점")
        print("   👟 걸음: \(data.steps.reduce(0) { $0 + Int($1.quantity.doubleValue(for: .count())) })보")
        
        // JSON 크기 정보
        let payload = createWorkoutPayload(from: data)
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload) {
            let sizeKB = Double(jsonData.count) / 1024.0
            print("   📊 전송 데이터 크기: \(String(format: "%.1f", sizeKB))KB")
        }
    }
    
    /// 앱이 종료될 때 자동으로 호출되어야 하는 정리 메서드
    deinit {
        stopAutoSync()
    }
    
    // MARK: - Helper Methods
    private func createWorkoutPayload(from workoutData: WorkoutDetailedData) -> [String: Any] {
        return [
            "workoutId": workoutData.workout.uuid.uuidString,
            "startTime": ISO8601DateFormatter().string(from: workoutData.startDate),
            "endTime": ISO8601DateFormatter().string(from: workoutData.endDate),
            "workoutType": "running",
            "distance": workoutData.totalDistance,
            "duration": Int(workoutData.duration),
            "calories": Int(workoutData.totalEnergyBurned),
            "avgHeartRate": Int(workoutData.averageHeartRate),
            "route": workoutData.routePoints.map { point in
                [
                    "latitude": point.latitude,
                    "longitude": point.longitude,
                    "timestamp": ISO8601DateFormatter().string(from: point.timestamp)
                ]
            }
        ]
    }
    
    private func postWorkoutData(_ workoutData: WorkoutDetailedData, completion: @escaping (Bool, String?) -> Void) {
        // 워크아웃 데이터를 서버 형식으로 변환
        let payload = createWorkoutPayload(from: workoutData)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(false, "JSON 변환 실패")
            return
        }
        
        var request = URLRequest(url: URL(string: "http://127.0.0.1/syncworkout")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "네트워크 오류: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        completion(true, nil)
                    } else {
                        completion(false, "서버 응답 오류 (\(httpResponse.statusCode))")
                    }
                } else {
                    completion(false, "알 수 없는 응답")
                }
            }
        }
        task.resume()
    }
    
    private func postRouteData(jsonData: Data) {
        var request = URLRequest(url: URL(string: "http://127.0.0.1/syncdata")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = "동기화 실패: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    self?.syncStatus = "동기화 실패: 서버 응답 \(httpResponse.statusCode)"
                } else {
                    self?.syncStatus = "동기화 성공"
                }
            }
        }
        task.resume()
    }
} 
