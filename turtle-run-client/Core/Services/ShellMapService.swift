import Foundation
import MapKit
import CoreLocation

// MARK: - Shell API Request/Response Models
struct ShellRegionRequest {
    let centerQ: Int
    let centerR: Int
    let radius: Int
    let expansionFactor: Double
}

struct ShellRegionResponse {
    let shells: [ShellData]
    let region: RegionInfo
}

struct ShellData {
    let q: Int
    let r: Int
    let occupiedBy: String?
    let density: Int?
    let lastUpdated: Date
    
    func toShellGridCell() -> ShellGridCell {
        var cell = ShellGridCell(q: q, r: r)
        if let tribeString = occupiedBy {
            cell.occupiedBy = TribeType(rawValue: tribeString)
        }
        if let densityValue = density {
            cell.density = ShellDensity(rawValue: densityValue)
        }
        return cell
    }
}

struct RegionInfo {
    let centerQ: Int
    let centerR: Int
    let radius: Int
}

// MARK: - ShellMapService
@MainActor
class ShellMapService: ObservableObject {
    static let shared = ShellMapService()
    
    private var cachedShells: [String: ShellData] = [:]
    private var lastRequestTime: Date?
    private let debounceDelay: TimeInterval = 0.5
    private var pendingTask: Task<Void, Never>?
    
    private init() {}
    
    func fetchShellData(
        for region: MKCoordinateRegion,
        expansionFactor: Double = 1.5
    ) async -> [ShellGridCell] {
        
        // Debounce 처리
        pendingTask?.cancel()
        
        return await withTaskGroup(of: [ShellGridCell].self) { group in
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(self.debounceDelay * 1_000_000_000))
                return await self.performShellDataFetch(region: region, expansionFactor: expansionFactor)
            }
            
            for await result in group {
                return result
            }
            
            return []
        }
    }
    
    private func performShellDataFetch(
        region: MKCoordinateRegion,
        expansionFactor: Double
    ) async -> [ShellGridCell] {
        
        let mapCenterHex = HexagonGridUtil.coordinateToHex(coordinate: region.center)
        let radius = calculateRadius(for: region, expansionFactor: expansionFactor)
        
        let request = ShellRegionRequest(
            centerQ: mapCenterHex.q,
            centerR: mapCenterHex.r,
            radius: radius,
            expansionFactor: expansionFactor
        )
        
        // 실제 서버 호출 대신 더미 데이터 생성
        let response = await generateDummyShellResponse(for: request, region: region)
        
        // 캐시 업데이트
        updateCache(with: response.shells)
        
        // ShellGridCell로 변환하여 반환
        return convertToShellGridCells(response.shells, region: region, expansionFactor: expansionFactor)
    }
    
    private func calculateRadius(for region: MKCoordinateRegion, expansionFactor: Double) -> Int {
        let latDeltaMeters = region.span.latitudeDelta * 111320.0
        let lngDeltaMeters = region.span.longitudeDelta * 111320.0 * cos(region.center.latitude * .pi / 180.0)
        
        let expandedLatDelta = latDeltaMeters * expansionFactor
        let expandedLngDelta = lngDeltaMeters * expansionFactor
        
        let maxDelta = max(expandedLatDelta, expandedLngDelta)
        return Int(maxDelta / (HexagonGridUtil.sideLength * 2)) + 5
    }
    
    private func convertToShellGridCells(
        _ shellData: [ShellData],
        region: MKCoordinateRegion,
        expansionFactor: Double
    ) -> [ShellGridCell] {
        
        // 먼저 기본 그리드 셀들을 생성
        var baseGridCells = HexagonGridUtil.generateGridCellsForMapRegion(
            region: region,
            expansionFactor: expansionFactor
        )
        
        // Shell 데이터를 딕셔너리로 변환
        var shellDict: [String: ShellData] = [:]
        for shell in shellData {
            let key = "\(shell.q),\(shell.r)"
            shellDict[key] = shell
        }
        
        // 기본 그리드 셀들에 Shell 정보 적용
        for i in 0..<baseGridCells.count {
            let cell = baseGridCells[i]
            let key = "\(cell.q),\(cell.r)"
            
            if let shellData = shellDict[key] {
                baseGridCells[i] = shellData.toShellGridCell()
            }
        }
        
        // 거리 기반으로 정리
        let prunedShells = HexagonGridUtil.pruneDistantGridCells(
            gridCells: baseGridCells,
            mapCenter: region.center,
            maxCount: 800,
            prioritizeShells: true
        )
        
        return prunedShells
    }
    
    private func updateCache(with shells: [ShellData]) {
        for shell in shells {
            let key = "\(shell.q),\(shell.r)"
            cachedShells[key] = shell
        }
        lastRequestTime = Date()
    }
}

// MARK: - Dummy Data Generation (현재 더미 데이터 로직 이관)
extension ShellMapService {
    private func generateDummyShellResponse(
        for request: ShellRegionRequest,
        region: MKCoordinateRegion
    ) async -> ShellRegionResponse {
        
        print("🔄 Shell 데이터 요청 - 중심: q=\(request.centerQ), r=\(request.centerR), 반지름: \(request.radius)")
        
        let dummyShellData = generateDummyShellPattern(
            centerQ: request.centerQ,
            centerR: request.centerR,
            mapCenter: region.center
        )
        
        let shells = dummyShellData.map { (q, r, tribe, density) in
            ShellData(
                q: q,
                r: r,
                occupiedBy: tribe.rawValue,
                density: density.rawValue,
                lastUpdated: Date()
            )
        }
        
        let regionInfo = RegionInfo(
            centerQ: request.centerQ,
            centerR: request.centerR,
            radius: request.radius
        )
        
        print("✅ 더미 Shell 데이터 생성됨: \(shells.count)개")
        
        return ShellRegionResponse(shells: shells, region: regionInfo)
    }
    
    private func generateDummyShellPattern(
        centerQ: Int,
        centerR: Int,
        mapCenter: CLLocationCoordinate2D
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var shellData: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        print("🎨 더미 패턴 생성 시작 - 중심: (\(centerQ), \(centerR))")
        
        // 패턴 1: 붉은귀거북 - 동쪽 러닝 코스
        let redTurtlePattern = generateRunningCoursePattern(
            centerQ: centerQ,
            centerR: centerR,
            direction: .east,
            tribe: .redTurtle,
            length: 12
        )
        shellData.append(contentsOf: redTurtlePattern)
        
        // 패턴 2: 사막거북 - 서쪽 러닝 코스
        let yellowTurtlePattern = generateRunningCoursePattern(
            centerQ: centerQ,
            centerR: centerR,
            direction: .west,
            tribe: .yellowTurtle,
            length: 12
        )
        shellData.append(contentsOf: yellowTurtlePattern)
        
        // 패턴 3: 그리스거북 - 남쪽 러닝 코스
        let blueTurtlePattern = generateRunningCoursePattern(
            centerQ: centerQ,
            centerR: centerR,
            direction: .south,
            tribe: .blueTurtle,
            length: 12
        )
        shellData.append(contentsOf: blueTurtlePattern)
        
        // 패턴 4: 랜덤 Shell들
        let randomPattern = generateRandomShellsAroundCenter(
            centerQ: centerQ,
            centerR: centerR,
            radius: 15,
            count: 20
        )
        shellData.append(contentsOf: randomPattern)
        
        print("📊 총 더미 패턴: \(shellData.count)개")
        return shellData
    }
    
    private func generateRunningCoursePattern(
        centerQ: Int,
        centerR: Int,
        direction: HexDirection,
        tribe: TribeType,
        length: Int
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var pattern: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        let (baseQ, baseR) = direction.delta
        
        var mainPath: [(q: Int, r: Int)] = []
        for i in 1...length {
            let curveOffset = sin(Double(i) * 0.3) * 0.8
            let perpQ = direction == .east || direction == .west ? 0 : 1
            let perpR = direction == .east || direction == .west ? 1 : 0
            
            let q = centerQ + (baseQ * i) + Int(curveOffset * Double(perpQ))
            let r = centerR + (baseR * i) + Int(curveOffset * Double(perpR))
            
            mainPath.append((q: q, r: r))
        }
        
        for (index, (centerQ, centerR)) in mainPath.enumerated() {
            let progress = Double(index) / Double(mainPath.count - 1)
            let baseDensity = calculateBaseDensity(for: index, totalLength: length)
            let width = max(2, Int(4 * (1.0 - progress * 0.5)))
            
            let clusterCells = generateRunningCluster(
                centerQ: centerQ,
                centerR: centerR,
                width: width,
                baseDensity: baseDensity,
                tribe: tribe
            )
            
            pattern.append(contentsOf: clusterCells)
        }
        
        let branchPaths = generateBranchPaths(
            mainPath: mainPath,
            direction: direction,
            tribe: tribe
        )
        pattern.append(contentsOf: branchPaths)
        
        return pattern
    }
    
    private func generateRunningCluster(
        centerQ: Int,
        centerR: Int,
        width: Int,
        baseDensity: ShellDensity,
        tribe: TribeType
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var cluster: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        
        for deltaQ in -width...width {
            for deltaR in -width...width {
                let distance = max(abs(deltaQ), abs(deltaR), abs(deltaQ + deltaR))
                
                if distance <= width {
                    let q = centerQ + deltaQ
                    let r = centerR + deltaR
                    
                    let densityReduction = distance
                    let randomFactor = Double.random(in: 0.7...1.3)
                    
                    let adjustedDensity = adjustDensity(
                        baseDensity,
                        reduction: densityReduction,
                        randomFactor: randomFactor
                    )
                    
                    let probability = 1.0 - (Double(distance) / Double(width + 1)) * 0.6
                    if Double.random(in: 0...1) < probability {
                        cluster.append((q: q, r: r, tribe: tribe, density: adjustedDensity))
                    }
                }
            }
        }
        
        return cluster
    }
    
    private func generateBranchPaths(
        mainPath: [(q: Int, r: Int)],
        direction: HexDirection,
        tribe: TribeType
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var branches: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        let branchPoints = stride(from: 2, to: mainPath.count - 2, by: 4)
        
        for branchIndex in branchPoints {
            let (startQ, startR) = mainPath[branchIndex]
            let branchDirections = getPerpendicularDirections(to: direction)
            
            for branchDir in branchDirections {
                let (branchQ, branchR) = branchDir.delta
                let branchLength = Int.random(in: 2...4)
                
                for i in 1...branchLength {
                    let q = startQ + (branchQ * i)
                    let r = startR + (branchR * i)
                    let density: ShellDensity = i == 1 ? .level4 : .level3
                    
                    if Double.random(in: 0...1) < 0.5 {
                        branches.append((q: q, r: r, tribe: tribe, density: density))
                    }
                }
            }
        }
        
        return branches
    }
    
    private func generateRandomShellsAroundCenter(
        centerQ: Int,
        centerR: Int,
        radius: Int,
        count: Int
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var randomShells: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        let tribes = TribeType.allCases
        let densities = ShellDensity.allCases
        
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * Double.pi))
            let distance = Int.random(in: 5...radius)
            
            let q = centerQ + Int(Double(distance) * cos(angle))
            let r = centerR + Int(Double(distance) * sin(angle))
            
            let tribe = tribes.randomElement() ?? .redTurtle
            let density = densities.randomElement() ?? .level3
            
            randomShells.append((q: q, r: r, tribe: tribe, density: density))
        }
        
        return randomShells
    }
    
    private func calculateBaseDensity(for index: Int, totalLength: Int) -> ShellDensity {
        let progress = Double(index) / Double(totalLength - 1)
        
        if progress < 0.3 {
            return .level5
        } else if progress < 0.6 {
            return .level4
        } else if progress < 0.8 {
            return .level4
        } else {
            return .level3
        }
    }
    
    private func adjustDensity(
        _ baseDensity: ShellDensity,
        reduction: Int,
        randomFactor: Double
    ) -> ShellDensity {
        let baseValue = baseDensity.rawValue
        let gentleReduction = max(0, reduction - 1)
        let reductionFactor = min(1.0, Double(gentleReduction) * 0.3)
        let adjustedValue = max(2, Int(Double(baseValue) * (1.0 - reductionFactor) * randomFactor))
        
        return ShellDensity(rawValue: min(5, adjustedValue)) ?? .level2
    }
    
    private func getPerpendicularDirections(to direction: HexDirection) -> [HexDirection] {
        switch direction {
        case .east, .west:
            return [.northeast, .northwest]
        case .north, .south:
            return [.east, .west]
        case .northeast, .northwest:
            return [.north, .south]
        }
    }
}
