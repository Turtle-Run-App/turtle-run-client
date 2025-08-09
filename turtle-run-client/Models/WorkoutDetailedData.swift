import Foundation
import HealthKit

struct WorkoutDetailedData {
    let workout: HKWorkout
    var heartRates: [HKQuantitySample] = []
    var routePoints: [RunningLocationPoint] = []
    var steps: [HKQuantitySample] = []
    var calories: [HKQuantitySample] = []
    var speed: [HKQuantitySample] = []
    
    // 기본 워크아웃 정보
    var duration: TimeInterval {
        return workout.duration
    }
    
    var totalDistance: Double {
        return workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    var totalEnergyBurned: Double {
        return workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
    }
    
    var startDate: Date {
        return workout.startDate
    }
    
    var endDate: Date {
        return workout.endDate
    }
    
    // 평균 심박수
    var averageHeartRate: Double {
        guard !heartRates.isEmpty else { return 0 }
        let total = heartRates.reduce(0) { $0 + $1.quantity.doubleValue(for: .count().unitDivided(by: .minute())) }
        return total / Double(heartRates.count)
    }
    
    // 최대 심박수
    var maxHeartRate: Double {
        guard !heartRates.isEmpty else { return 0 }
        return heartRates.map { $0.quantity.doubleValue(for: .count().unitDivided(by: .minute())) }.max() ?? 0
    }
    
    // 최소 심박수
    var minHeartRate: Double {
        guard !heartRates.isEmpty else { return 0 }
        return heartRates.map { $0.quantity.doubleValue(for: .count().unitDivided(by: .minute())) }.min() ?? 0
    }
    
    // 총 스텝 수
    var totalSteps: Int {
        return steps.reduce(0) { $0 + Int($1.quantity.doubleValue(for: .count())) }
    }
    
    // 평균 속도 (m/s)
    var averageSpeed: Double {
        guard !speed.isEmpty else { return 0 }
        let total = speed.reduce(0) { $0 + $1.quantity.doubleValue(for: .meter().unitDivided(by: .second())) }
        return total / Double(speed.count)
    }
    
    // 페이스 (분/km) - 워크아웃 데이터로 계산
    var averagePace: Double {
        guard totalDistance > 0 && duration > 0 else { return 0 }
        // 총 시간(분) / 총 거리(km) = 분/km
        let durationInMinutes = duration / 60.0
        let distanceInKm = totalDistance / 1000.0
        return durationInMinutes / distanceInKm
    }
    
    // 포맷된 시간 문자열
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // 포맷된 거리 문자열
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.2f km", totalDistance / 1000)
        } else {
            return String(format: "%.0f m", totalDistance)
        }
    }
    
    // 포맷된 페이스 문자열
    var formattedPace: String {
        let pace = averagePace
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"/km", minutes, seconds)
    }
} 