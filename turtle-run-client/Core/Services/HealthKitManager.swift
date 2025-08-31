import Foundation
import HealthKit
import CoreLocation
import UIKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // Observer query 관리를 위한 프로퍼티
    private var workoutObserverQuery: HKObserverQuery?
    private var workoutObserverCallback: (() -> Void)?
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// HealthKit 권한 요청
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
    
    // MARK: - Observer Pattern for Workout Changes
    
    /// 새로운 워크아웃 데이터 추가를 감지하는 Observer 시작
    func startWorkoutObserver(callback: @escaping () -> Void) {
        print("🎯 HealthKit Observer 설정 시작...")
        
        // 기존 observer가 있다면 정지
        if workoutObserverQuery != nil {
            stopWorkoutObserver()
        }
        
        // 콜백 등록
        self.workoutObserverCallback = callback
        
        // 콜백 등록 확인
        guard workoutObserverCallback != nil else {
            print("❌ 콜백 함수 등록 실패!")
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        workoutObserverQuery = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            let appState = UIApplication.shared.applicationState
            let stateString = appState == .background ? "백그라운드" : (appState == .active ? "포그라운드" : "비활성")
            print("🔔 HealthKit Observer 트리거됨!")
            print("   - 시간: \(self?.formatKoreanTime(Date()) ?? "알 수 없음")")
            print("   - 앱 상태: \(stateString)")
            
            if let error = error {
                print("❌ HealthKit Observer 오류: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // 메인 쓰레드에서 콜백 실행
            DispatchQueue.main.async {
                if let callback = self?.workoutObserverCallback {
                    callback()
                } else {
                    print("❌ 콜백 함수가 nil입니다! WorkoutDataService 연결 문제")
                }
            }
            
            // HealthKit에 처리 완료를 알림
            completionHandler()
        }
        
        // Observer 시작
        if let observerQuery = workoutObserverQuery {
            healthStore.execute(observerQuery)
            print("✅ HealthKit Observer 등록 완료!")
        } else {
            print("❌ Observer Query 생성 실패!")
            return
        }
        
        // 백그라운드 딜리버리 활성화
        enableBackgroundDelivery()
    }
    
    /// 워크아웃 Observer 중지
    func stopWorkoutObserver() {
        if let observerQuery = workoutObserverQuery {
            healthStore.stop(observerQuery)
            print("🛑 HealthKit Observer 중지됨")
        }
        workoutObserverQuery = nil
        workoutObserverCallback = nil
        
        // 백그라운드 딜리버리 비활성화
        disableBackgroundDelivery()
    }
    
    /// 최근 러닝 워크아웃 가져오기
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
    
    // 특정 기간의 러닝 워크아웃 가져오기 (3개월치)
    func fetchRunningWorkoutsForPeriod(monthsBack: Int = 3, completion: @escaping ([HKWorkout]) -> Void) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -monthsBack, to: endDate) ?? endDate
        
        print("📅 Fetching workouts from \(startDate) to \(endDate)")
        
        // 러닝 워크아웃 + 날짜 범위 조건
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, datePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // limit을 HKObjectQueryNoLimit으로 설정하여 모든 데이터 가져오기
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: combinedPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("❌ Error fetching workouts: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let workouts = samples as? [HKWorkout] ?? []
            print("✅ Found \(workouts.count) workouts in the last \(monthsBack) months")
            
            DispatchQueue.main.async {
                completion(workouts)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// 워크아웃 내 심박수 샘플 가져오기
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
                    // 위치 포인트 생성
                    var points: [RunningLocationPoint] = []
                    for loc in allLocations {
                        points.append(RunningLocationPoint(
                            latitude: loc.coordinate.latitude,
                            longitude: loc.coordinate.longitude,
                            timestamp: loc.timestamp,
                            cumulativeDistance: 0
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
}

// MARK: - Private Implementation
private extension HealthKitManager {
    
    /// 백그라운드에서도 HealthKit 데이터 변경사항을 감지할 수 있도록 설정
    func enableBackgroundDelivery() {
        let workoutType = HKObjectType.workoutType()
        
        print("🌙 백그라운드 딜리버리 활성화 시도...")
        
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 백그라운드 딜리버리 활성화 실패: \(error.localizedDescription)")
                } else if success {
                    print("✅ 백그라운드 딜리버리 활성화 성공")
                } else {
                    print("⚠️ 백그라운드 딜리버리 활성화 실패 (이유 불명)")
                }
            }
        }
    }
    
    /// 백그라운드 딜리버리 비활성화
    func disableBackgroundDelivery() {
        let workoutType = HKObjectType.workoutType()
        
        healthStore.disableBackgroundDelivery(for: workoutType) { success, error in
            if let error = error {
                print("❌ 백그라운드 딜리버리 비활성화 실패: \(error.localizedDescription)")
            } else if success {
                print("✅ 백그라운드 딜리버리 비활성화 성공")
            }
        }
    }
    
    /// 한국 시간으로 포맷팅
    func formatKoreanTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date) + " (KST)"
    }
    
    /// 스텝 데이터 가져오기
    func fetchSteps(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
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
    
    /// 칼로리 데이터 가져오기
    func fetchCalories(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
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
    
    /// 속도 데이터 가져오기 (러닝 속도 + 걷기 속도)
    func fetchSpeed(for workout: HKWorkout, completion: @escaping ([HKQuantitySample]) -> Void) {
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