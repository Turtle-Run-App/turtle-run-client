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
            HKSeriesType.workoutRoute(), // GPS 경로 데이터를 위한 권한
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .runningSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
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
        let routeQuery = HKSampleQuery(sampleType: routeType, predicate: routePredicate, limit: 1, sortDescriptors: nil) { [weak self] _, routeSamples, error in
            print("🔍 Route query result: \(routeSamples?.count ?? 0) routes found")
            if let error = error {
                print("❌ Route query error: \(error)")
            }
            
            guard let route = (routeSamples as? [HKWorkoutRoute])?.first else {
                print("⚠️ No route found for workout")
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            print("✅ Route found, fetching locations...")
            var allLocations: [CLLocation] = []
            let locationsQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error = error {
                    print("❌ Location query error: \(error)")
                }
                
                if let locations = locations {
                    print("📍 Found \(locations.count) locations")
                    allLocations.append(contentsOf: locations)
                }
                
                if done {
                    print("✅ Location query completed, total locations: \(allLocations.count)")
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
                    print("🎯 Created \(points.count) route points")
                    DispatchQueue.main.async {
                        completion(points)
                    }
                }
            }
            self?.healthStore.execute(locationsQuery)
        }
        healthStore.execute(routeQuery)
    }
    
    // 워크아웃의 모든 HealthKit 데이터를 가져오는 메서드
    func fetchCompleteWorkoutData(for workout: HKWorkout, completion: @escaping (WorkoutDetailedData) -> Void) {
        var detailedData = WorkoutDetailedData(workout: workout)
        
        let group = DispatchGroup()
        
        // 1. 심박수 데이터 가져오기
        group.enter()
        fetchHeartRates(for: workout) { heartRates in
            detailedData.heartRates = heartRates
            group.leave()
        }
        
        // 2. 경로 데이터 가져오기
        group.enter()
        fetchRouteLocations(for: workout) { routePoints in
            detailedData.routePoints = routePoints
            group.leave()
        }
        
        // 3. 스텝 데이터 가져오기
        group.enter()
        fetchSteps(for: workout) { steps in
            detailedData.steps = steps
            group.leave()
        }
        
        // 4. 칼로리 데이터 가져오기
        group.enter()
        fetchCalories(for: workout) { calories in
            detailedData.calories = calories
            group.leave()
        }
        
        // 5. 속도 데이터 가져오기
        group.enter()
        fetchSpeed(for: workout) { speed in
            detailedData.speed = speed
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(detailedData)
        }
    }
    
    // 스텝 데이터 가져오기
    private func fetchSteps(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            let steps = samples as? [HKQuantitySample] ?? []
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        healthStore.execute(query)
    }
    
    // 칼로리 데이터 가져오기
    private func fetchCalories(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: calorieType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            let calories = samples as? [HKQuantitySample] ?? []
            DispatchQueue.main.async {
                completion(calories)
            }
        }
        healthStore.execute(query)
    }
    
    // 속도 데이터 가져오기 (러닝 속도 + 걷기 속도)
    private func fetchSpeed(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
        var allSpeedSamples: [HKQuantitySample] = []
        let group = DispatchGroup()
        
        // 러닝 속도
        if let runningSpeedType = HKQuantityType.quantityType(forIdentifier: .runningSpeed) {
            group.enter()
            let runningPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            let runningQuery = HKSampleQuery(sampleType: runningSpeedType, predicate: runningPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                if let samples = samples as? [HKQuantitySample] {
                    allSpeedSamples.append(contentsOf: samples)
                }
                group.leave()
            }
            healthStore.execute(runningQuery)
        }
        
        // 걷기 속도
        if let walkingSpeedType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) {
            group.enter()
            let walkingPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            let walkingQuery = HKSampleQuery(sampleType: walkingSpeedType, predicate: walkingPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                if let samples = samples as? [HKQuantitySample] {
                    allSpeedSamples.append(contentsOf: samples)
                }
                group.leave()
            }
            healthStore.execute(walkingQuery)
        }
        
        group.notify(queue: .main) {
            completion(allSpeedSamples)
        }
    }
} 