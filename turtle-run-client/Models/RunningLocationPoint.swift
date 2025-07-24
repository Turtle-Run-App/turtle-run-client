import Foundation

struct RunningLocationPoint: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let cumulativeDistance: Double // meter
} 