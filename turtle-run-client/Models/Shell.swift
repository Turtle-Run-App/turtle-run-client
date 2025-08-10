import Foundation
import CoreLocation
import SwiftUI
import MapKit

// MARK: - Shell Grid Cell Model
struct ShellGridCell: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let q: Int // 육각형 그리드의 q 좌표
    let r: Int // 육각형 그리드의 r 좌표
    var occupiedBy: TribeType? // Shell로 점유된 경우
    var occupiedAt: Date?
    
    // 20m 단위 정육각형 Grid Cell의 꼭짓점들 계산
    var hexagonVertices: [CLLocationCoordinate2D] {
        return HexagonGridUtil.getHexagonVertices(center: coordinate, sideLength: 20.0)
    }
    
    // 절대 좌표계 기반으로 Grid Cell 생성
    init(q: Int, r: Int) {
        self.q = q
        self.r = r
        self.coordinate = HexagonGridUtil.hexToAbsoluteCoordinate(q: q, r: r)
        self.occupiedBy = nil
        self.occupiedAt = nil
    }
    
    // 이 Grid Cell이 Shell인지 확인 (종족에 의해 점유된 상태)
    var isShell: Bool {
        return occupiedBy != nil
    }
    
    // 특정 중심점으로부터의 거리 계산 (미터 단위)
    func distanceFrom(center: CLLocationCoordinate2D) -> Double {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let cellLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return centerLocation.distance(from: cellLocation)
    }
    
    static func == (lhs: ShellGridCell, rhs: ShellGridCell) -> Bool {
        return lhs.q == rhs.q && lhs.r == rhs.r
    }
}

// MARK: - Tribe Type
enum TribeType: String, CaseIterable {
    case redTurtle = "red"      // 붉은귀거북
    case yellowTurtle = "yellow" // 사막거북
    case blueTurtle = "blue"     // 그리스거북
    
    var color: Color {
        switch self {
        case .redTurtle:
            return .turtleRunTheme.redTurtle
        case .yellowTurtle:
            return .turtleRunTheme.yellowTurtle
        case .blueTurtle:
            return .turtleRunTheme.blueTurtle
        }
    }
    
    var displayName: String {
        switch self {
        case .redTurtle:
            return "붉은귀거북"
        case .yellowTurtle:
            return "사막거북"
        case .blueTurtle:
            return "그리스거북"
        }
    }
}

// MARK: - Hexagon Grid Utilities
struct HexagonGridUtil {
    // 정육각형의 한 변 길이 (미터)
    static let sideLength: Double = 20.0
    
    // 절대 좌표계의 기준점 (서울 시청 좌표를 기준으로 설정)
    static let absoluteOrigin = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    
    // 육각형 그리드에서 절대 실제 좌표로 변환
    static func hexToAbsoluteCoordinate(q: Int, r: Int) -> CLLocationCoordinate2D {
        let size = sideLength
        let x = size * (3.0/2.0 * Double(q))
        let y = size * (sqrt(3.0)/2.0 * Double(q) + sqrt(3.0) * Double(r))
        
        // 미터를 위도/경도로 변환 (절대 기준점 기준)
        let deltaLat = y / 111320.0 // 1도 = 약 111.32km
        let deltaLng = x / (111320.0 * cos(absoluteOrigin.latitude * .pi / 180.0))
        
        return CLLocationCoordinate2D(
            latitude: absoluteOrigin.latitude + deltaLat,
            longitude: absoluteOrigin.longitude + deltaLng
        )
    }
    
    // 실제 좌표에서 육각형 그리드 좌표로 변환 (절대 기준점 기준)
    static func coordinateToHex(coordinate: CLLocationCoordinate2D) -> (q: Int, r: Int) {
        let size = sideLength
        
        // 위도/경도를 미터로 변환 (절대 기준점 기준)
        let deltaLat = coordinate.latitude - absoluteOrigin.latitude
        let deltaLng = coordinate.longitude - absoluteOrigin.longitude
        
        let y = deltaLat * 111320.0
        let x = deltaLng * 111320.0 * cos(absoluteOrigin.latitude * .pi / 180.0)
        
        // 육각형 좌표로 변환
        let q = (2.0/3.0 * x) / size
        let r = (-1.0/3.0 * x + sqrt(3.0)/3.0 * y) / size
        
        return (q: Int(round(q)), r: Int(round(r)))
    }
    
    // 육각형의 꼭짓점들 계산
    static func getHexagonVertices(center: CLLocationCoordinate2D, sideLength: Double) -> [CLLocationCoordinate2D] {
        var vertices: [CLLocationCoordinate2D] = []
        
        for i in 0..<6 {
            let angleDeg = 60.0 * Double(i)
            let angleRad = angleDeg * .pi / 180.0
            
            // 육각형 꼭짓점까지의 거리 (미터)
            let distance = sideLength
            
            let deltaLat = distance * sin(angleRad) / 111320.0
            let deltaLng = distance * cos(angleRad) / (111320.0 * cos(center.latitude * .pi / 180.0))
            
            let vertex = CLLocationCoordinate2D(
                latitude: center.latitude + deltaLat,
                longitude: center.longitude + deltaLng
            )
            vertices.append(vertex)
        }
        
        return vertices
    }
    
    // 특정 중심점 주변의 Shell Grid Cells 생성 (절대 좌표계 기반)
    static func generateGridCellsAroundCenter(
        center: CLLocationCoordinate2D, 
        radius: Int = 6 // 20m Grid에 맞춘 반지름
    ) -> [ShellGridCell] {
        var gridCells: [ShellGridCell] = []
        
        // 중심점을 절대 좌표계의 육각형 그리드 좌표로 변환
        let centerHex = coordinateToHex(coordinate: center)
        
        // 중심 육각형 그리드 좌표 주변의 반지름 내 모든 좌표 생성
        for q in (centerHex.q - radius)...(centerHex.q + radius) {
            let r1 = max(centerHex.r - radius, -q - (centerHex.r + radius))
            let r2 = min(centerHex.r + radius, -q + (centerHex.r + radius))
            
            for r in r1...r2 {
                let gridCell = ShellGridCell(q: q, r: r)
                gridCells.append(gridCell)
            }
        }
        
        return gridCells
    }
    
    // 지도 가시 영역의 1.5배 범위에 해당하는 Shell Grid Cells 생성 (절대 좌표계 기반)
    static func generateGridCellsForMapRegion(
        region: MKCoordinateRegion,
        expansionFactor: Double = 1.5 // 1.5배로 축소
    ) -> [ShellGridCell] {
        let center = region.center
        
        // 가시 영역의 크기를 미터로 변환
        let latDeltaMeters = region.span.latitudeDelta * 111320.0 // 1도 ≈ 111.32km
        let lngDeltaMeters = region.span.longitudeDelta * 111320.0 * cos(center.latitude * .pi / 180.0)
        
        // 확장된 영역 계산
        let expandedLatDelta = latDeltaMeters * expansionFactor
        let expandedLngDelta = lngDeltaMeters * expansionFactor
        
        // 확장된 영역의 경계 좌표
        let northLat = center.latitude + (expandedLatDelta / 2.0) / 111320.0
        let southLat = center.latitude - (expandedLatDelta / 2.0) / 111320.0
        let eastLng = center.longitude + (expandedLngDelta / 2.0) / (111320.0 * cos(center.latitude * .pi / 180.0))
        let westLng = center.longitude - (expandedLngDelta / 2.0) / (111320.0 * cos(center.latitude * .pi / 180.0))
        
        // 경계를 절대 좌표계 기준 육각형 그리드 좌표로 변환
        let northWest = coordinateToHex(coordinate: CLLocationCoordinate2D(latitude: northLat, longitude: westLng))
        let southEast = coordinateToHex(coordinate: CLLocationCoordinate2D(latitude: southLat, longitude: eastLng))
        
        var gridCells: [ShellGridCell] = []
        
        // 경계 내의 모든 육각형 생성 (절대 좌표계 기준)
        let minQ = min(northWest.q, southEast.q) - 1 // 여유분 축소
        let maxQ = max(northWest.q, southEast.q) + 1
        let minR = min(northWest.r, southEast.r) - 1
        let maxR = max(northWest.r, southEast.r) + 1
        
        // Grid Cell 개수 제한 해제 - 모든 영역 내 Grid Cell 생성
        for q in minQ...maxQ {
            for r in minR...maxR {
                // 절대 좌표계 기반으로 Grid Cell 생성
                let gridCell = ShellGridCell(q: q, r: r)
                
                // 생성된 좌표가 확장된 영역 내에 있는지 확인
                if gridCell.coordinate.latitude >= southLat && gridCell.coordinate.latitude <= northLat &&
                   gridCell.coordinate.longitude >= westLng && gridCell.coordinate.longitude <= eastLng {
                    gridCells.append(gridCell)
                }
            }
        }
        
        print("생성된 Grid Cell 개수: \(gridCells.count)")
        return gridCells
    }
    
    // 거리 기반으로 Grid Cell 정리 (가장 먼 Grid부터 제거)
    static func pruneDistantGridCells(
        gridCells: [ShellGridCell],
        mapCenter: CLLocationCoordinate2D,
        maxCount: Int = 800,
        prioritizeShells: Bool = true
    ) -> [ShellGridCell] {
        guard gridCells.count > maxCount else {
            return gridCells
        }
        
        // Shell과 일반 Grid Cell 분리
        let shells = gridCells.filter { $0.isShell }
        let regularCells = gridCells.filter { !$0.isShell }
        
        if prioritizeShells {
            // Shell은 최대한 보존, 일반 Grid Cell만 거리순으로 정리
            let sortedRegularCells = regularCells.sorted { cell1, cell2 in
                cell1.distanceFrom(center: mapCenter) < cell2.distanceFrom(center: mapCenter)
            }
            
            let remainingSlots = maxCount - shells.count
            let prunedRegularCells = remainingSlots > 0 
                ? Array(sortedRegularCells.prefix(remainingSlots))
                : []
            
            let result = shells + prunedRegularCells
            print("Grid 정리 완료: Shell \(shells.count)개, 일반 Grid \(prunedRegularCells.count)개, 총 \(result.count)개")
            return result
            
        } else {
            // 모든 Grid Cell을 거리순으로 정렬하여 정리
            let sortedCells = gridCells.sorted { cell1, cell2 in
                cell1.distanceFrom(center: mapCenter) < cell2.distanceFrom(center: mapCenter)
            }
            
            let result = Array(sortedCells.prefix(maxCount))
            let shellCount = result.filter { $0.isShell }.count
            print("Grid 정리 완료: Shell \(shellCount)개, 총 \(result.count)개")
            return result
        }
    }
    
    // 두 지도 영역이 충분히 다른지 확인 (Shell 재생성 필요 여부 판단)
    static func shouldRegenerateShells(
        currentRegion: MKCoordinateRegion,
        lastRegion: MKCoordinateRegion,
        threshold: Double = 0.3
    ) -> Bool {
        let latDiff = abs(currentRegion.center.latitude - lastRegion.center.latitude)
        let lngDiff = abs(currentRegion.center.longitude - lastRegion.center.longitude)
        let spanLatDiff = abs(currentRegion.span.latitudeDelta - lastRegion.span.latitudeDelta)
        let spanLngDiff = abs(currentRegion.span.longitudeDelta - lastRegion.span.longitudeDelta)
        
        let centerThreshold = min(currentRegion.span.latitudeDelta, currentRegion.span.longitudeDelta) * threshold
        let spanThreshold = min(currentRegion.span.latitudeDelta, currentRegion.span.longitudeDelta) * 0.5
        
        return latDiff > centerThreshold || 
               lngDiff > centerThreshold || 
               spanLatDiff > spanThreshold || 
               spanLngDiff > spanThreshold
    }
}
