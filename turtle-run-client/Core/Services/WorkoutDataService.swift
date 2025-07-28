import Foundation
import HealthKit
import Combine

class WorkoutDataService: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    @Published var latestWorkoutData: WorkoutDetailedData?
    @Published var isLoadingDetailedData: Bool = false
    @Published var syncStatus: String? = nil
    
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
    
    // MARK: - Latest Workout Data
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
            
            // 2. 경로 데이터 가져오기
            self?.healthKitManager.fetchRouteLocations(for: workout) { points in
                guard !points.isEmpty else {
                    DispatchQueue.main.async { self?.syncStatus = "경로 데이터가 없습니다." }
                    return
                }
                
                // 3. JSON 변환
                let routeArray = points.map { point in
                    [
                        "latitude": point.latitude,
                        "longitude": point.longitude,
                        "timestamp": ISO8601DateFormatter().string(from: point.timestamp),
                        "cumulativeDistance": point.cumulativeDistance
                    ]
                }
                
                let payload: [String: Any] = [
                    "workoutId": workout.uuid.uuidString,
                    "route": routeArray
                ]
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
                    DispatchQueue.main.async { self?.syncStatus = "JSON 변환 실패" }
                    return
                }
                
                // 4. API POST
                self?.postRouteData(jsonData: jsonData)
            }
        }
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