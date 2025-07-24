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
                        "timestamp": ISO8601DateFormatter().string(from: point.timestamp)
                    ]
                }
                let payload: [String: Any] = [
                    "workoutId": workout.uuid.uuidString,
                    "startTime": ISO8601DateFormatter().string(from: workout.startDate),
                    "endTime": ISO8601DateFormatter().string(from: workout.endDate),
                    "workoutType": "running",
                    "distance": workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                    "duration": Int(workout.duration),
                    "calories": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    "avgHeartRate": 0, // 필요시 계산 추가
                    "route": routeArray
                ]
                guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
                    DispatchQueue.main.async { self?.syncStatus = "JSON 변환 실패" }
                    return
                }
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("실제 동기화 전송 데이터:\n\(jsonString)")
                }
                var request = URLRequest(url: URL(string: "http://127.0.0.1/api/v1/healthkit/sync")!)
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
    
    // 더미 러닝 데이터 동기화
    func syncDummyWorkoutData() {
        let dummy: [String: Any] = [
            "workoutId": UUID().uuidString,
            "startTime": "2024-01-01T10:00:00Z",
            "endTime": "2024-01-01T10:30:00Z",
            "workoutType": "running",
            "distance": 5000.0,
            "duration": 1800,
            "calories": 300,
            "avgHeartRate": 145,
            "route": [
                ["latitude": 37.5665, "longitude": 126.9780, "timestamp": "2024-01-01T10:00:00Z"],
                ["latitude": 37.5666, "longitude": 126.9781, "timestamp": "2024-01-01T10:00:30Z"]
            ]
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dummy) else {
            self.syncStatus = "더미 데이터 JSON 변환 실패"
            return
        }
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("더미 동기화 전송 데이터:\n\(jsonString)")
        }
        var request = URLRequest(url: URL(string: "http://127.0.0.1/api/v1/healthkit/sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = "더미 동기화 실패: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    self?.syncStatus = "더미 동기화 실패: 서버 응답 \(httpResponse.statusCode)"
                } else {
                    self?.syncStatus = "더미 동기화 성공"
                }
            }
        }
        task.resume()
    }
} 