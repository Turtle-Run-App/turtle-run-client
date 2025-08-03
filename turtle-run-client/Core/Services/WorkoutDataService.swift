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
    
    private let healthKitManager = HealthKitManager.shared
    
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
        let group = DispatchGroup()
        var allWorkoutData: [WorkoutDetailedData] = []
        var syncErrors: [String] = []
        
        for (index, workout) in workouts.enumerated() {
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
                    completion(false, error.localizedDescription)
                } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    completion(false, "서버 응답 \(httpResponse.statusCode)")
                } else {
                    completion(true, nil)
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