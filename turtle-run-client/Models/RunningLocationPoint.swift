import Foundation

struct RunningLocationPoint: Identifiable, Equatable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let cumulativeDistance: Double // meter
    
    static func == (lhs: RunningLocationPoint, rhs: RunningLocationPoint) -> Bool {
        return lhs.id == rhs.id
    }
} 