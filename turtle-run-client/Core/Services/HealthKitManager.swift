import Foundation
import HealthKit
import CoreLocation

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    // HealthKit 권한 요청
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let typesToRead: Set = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        healthStore.requestAuthorization(toShare: [], read: typesToRead, completion: completion)
    }
    
    // 최근 러닝 워크아웃 가져오기
    func fetchRecentRunningWorkouts(limit: Int = 10, completion: @escaping ([HKWorkout]) -> Void) {
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            let workouts = samples as? [HKWorkout] ?? []
            DispatchQueue.main.async {
                completion(workouts)
            }
        }
        healthStore.execute(query)
    }
    
    // 워크아웃 내 심박수 샘플 가져오기
    func fetchHeartRates(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            let heartRates = samples as? [HKQuantitySample] ?? []
            DispatchQueue.main.async {
                completion(heartRates)
            }
        }
        healthStore.execute(query)
    }
    
    // 워크아웃 경로(HKWorkoutRoute)에서 위치 정보와 누적 거리 추출
    func fetchRouteLocations(for workout: HKWorkout, completion: @escaping ([RunningLocationPoint]) -> Void) {
        let routeType = HKSeriesType.workoutRoute()
        let routePredicate = HKQuery.predicateForObjects(from: workout)
        let routeQuery = HKSampleQuery(sampleType: routeType, predicate: routePredicate, limit: 1, sortDescriptors: nil) { [weak self] _, routeSamples, _ in
            guard let route = (routeSamples as? [HKWorkoutRoute])?.first else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            var allLocations: [CLLocation] = []
            let locationsQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let locations = locations {
                    allLocations.append(contentsOf: locations)
                }
                if done {
                    // 누적 거리 계산
                    var points: [RunningLocationPoint] = []
                    var totalDistance: Double = 0
                    for (i, loc) in allLocations.enumerated() {
                        if i > 0 {
                            totalDistance += loc.distance(from: allLocations[i-1])
                        }
                        points.append(RunningLocationPoint(
                            latitude: loc.coordinate.latitude,
                            longitude: loc.coordinate.longitude,
                            timestamp: loc.timestamp,
                            cumulativeDistance: totalDistance
                        ))
                    }
                    DispatchQueue.main.async {
                        completion(points)
                    }
                }
            }
            self?.healthStore.execute(locationsQuery)
        }
        healthStore.execute(routeQuery)
    }
} 