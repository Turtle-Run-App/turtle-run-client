import Foundation
import HealthKit
import Combine

class RunningViewModel: ObservableObject {
    @Published var workouts: [HKWorkout] = []
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    @Published var routePoints: [RunningLocationPoint] = []
    @Published var syncStatus: String? = nil
    
    func requestHealthKitAuthorization() {
        HealthKitManager.shared.requestAuthorization { [weak self] success, error in
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
    
    func loadRecentRunningWorkouts() {
        HealthKitManager.shared.fetchRecentRunningWorkouts { [weak self] workouts in
            self?.workouts = workouts
        }
    }
    
    func loadRoute(for workout: HKWorkout) {
        HealthKitManager.shared.fetchRouteLocations(for: workout) { [weak self] points in
            self?.routePoints = points
        }
    }
    
    // 동기화: 최근 워크아웃의 경로 데이터를 127.0.0.1/syncdata로 POST
    func syncLatestWorkoutRoute() {
        // 1. 최근 워크아웃 가져오기
        HealthKitManager.shared.fetchRecentRunningWorkouts(limit: 1) { [weak self] workouts in
            guard let workout = workouts.first else {
                DispatchQueue.main.async { self?.syncStatus = "러닝 기록이 없습니다." }
                return
            }
            // 2. 경로 데이터 가져오기
            HealthKitManager.shared.fetchRouteLocations(for: workout) { points in
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
                var request = URLRequest(url: URL(string: "http://127.0.0.1/syncdata")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
    }
} 