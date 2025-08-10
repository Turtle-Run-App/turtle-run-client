import SwiftUI
import MapKit

struct ShellMap: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var shells: [ShellGridCell] = []
    @State private var showingLocationAlert = false
    @State private var lastRegion: MKCoordinateRegion?
    @State private var shouldCenterOnUser = false
    @State private var hasReceivedInitialLocation = false
    
    var body: some View {
            ZStack {
            // 실제 지도와 Shell Grid
            ShellMapView(
                locationManager: locationManager,
                gridCells: $shells,
                onRegionChanged: handleRegionChange,
                shouldCenterOnUser: $shouldCenterOnUser
            )
            .onAppear {
                requestLocationPermissionIfNeeded()
                generateInitialShells()
            }
            .onReceive(locationManager.$currentLocation) { newLocation in
                // 처음으로 위치를 받았을 때 해당 위치로 이동하고 Shell 재생성
                if let _ = newLocation, !hasReceivedInitialLocation {
                    hasReceivedInitialLocation = true
                    shouldCenterOnUser = true
                    generateInitialShells() // 새로운 위치 기준으로 Shell 재생성
                }
            }
            
            // 위치 권한이 없을 때 표시할 오버레이
            if locationManager.authorizationStatus == .denied || 
               locationManager.authorizationStatus == .restricted {
                locationPermissionOverlay
            }
            
            // 내 위치 버튼
            myLocationButton
        }
        .alert("위치 권한 필요", isPresented: $showingLocationAlert) {
            Button("설정으로 이동") {
                openAppSettings()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("Shell 지도를 사용하려면 위치 권한이 필요합니다.")
        }
    }
    
    // MARK: - 위치 권한 오버레이
    private var locationPermissionOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 20) {
                Image(systemName: "location.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.turtleRunTheme.accentColor)
                
                Text("위치 권한이 필요합니다")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Shell 지도를 사용하려면\n위치 권한을 허용해주세요")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("설정으로 이동") {
                    openAppSettings()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.turtleRunTheme.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - 내 위치 버튼
    private var myLocationButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    centerOnUserLocation()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.turtleRunTheme.mainColor.opacity(0.9))
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.turtleRunTheme.accentColor)
                    }
                }
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                .padding(.bottom, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func requestLocationPermissionIfNeeded() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
        } else if locationManager.authorizationStatus == .denied || 
                  locationManager.authorizationStatus == .restricted {
            showingLocationAlert = true
        }
    }
    
    private func generateInitialShells() {
        // 사용자 위치가 사용 가능하면 해당 위치를, 없으면 서울 시청을 기본으로 설정
        let initialCenter: CLLocationCoordinate2D
        
        if let userLocation = locationManager.currentLocation {
            initialCenter = userLocation.coordinate
        } else {
            // 위치 권한이 없거나 위치를 아직 받지 못한 경우 서울 시청을 기본값으로 사용
            initialCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
            print("⚠️ 기본 위치 사용 (서울 시청): \(initialCenter.latitude), \(initialCenter.longitude)")
        }
        
        let initialRegion = MKCoordinateRegion(
            center: initialCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009) // 약 1km 줌 레벨
        )
        
        // 초기 Shell 생성 (1.5배 확장 영역)
        generateShellsForRegion(initialRegion)
        lastRegion = initialRegion
    }
    
    private func centerOnUserLocation() {
        guard locationManager.currentLocation != nil else {
            requestLocationPermissionIfNeeded()
            return
        }
        
        // 지도 이동을 위한 플래그 설정
        shouldCenterOnUser = true
    }
    
    // MARK: - Shell Generation Methods
    private func handleRegionChange(_ newRegion: MKCoordinateRegion) {
        // 이전 지역과 비교하여 재생성이 필요한지 확인
        if let lastRegion = lastRegion,
           !HexagonGridUtil.shouldRegenerateShells(currentRegion: newRegion, lastRegion: lastRegion) {
            return // 재생성 불필요
        }
        
        generateShellsForRegion(newRegion)
        lastRegion = newRegion
    }
    
    private func generateShellsForRegion(_ region: MKCoordinateRegion) {
        // 지도 가시 영역의 1.5배 범위로 Shell 생성
        var newShells = HexagonGridUtil.generateGridCellsForMapRegion(region: region, expansionFactor: 1.5)
        
        // 기존 Shell과 병합 (중복 제거)
        let existingShells = shells
        var mergedShells = mergeShells(existing: existingShells, new: newShells)
        
        // 테스트용 Shell 생성 (최초 생성 시에만, 고정된 패턴)
        if shells.isEmpty {
            mergedShells = addTestShells(to: mergedShells, region: region)
        }
        
        // 거리 기반으로 Shell 정리 (가장 먼 Shell부터 제거)
        let prunedShells = HexagonGridUtil.pruneDistantGridCells(
            gridCells: mergedShells,
            mapCenter: region.center,
            maxCount: 800, // 최대 800개 Shell
            prioritizeShells: true // 점유된 Shell 우선 보존
        )
        
        shells = prunedShells
    }
    
    // 기존 Shell과 새로운 Shell 병합 (중복 제거, 점유 상태 보존)
    private func mergeShells(existing: [ShellGridCell], new: [ShellGridCell]) -> [ShellGridCell] {
        var existingDict: [String: ShellGridCell] = [:]
        
        // 기존 Shell을 딕셔너리로 변환 (q,r 좌표를 키로 사용)
        for shell in existing {
            let key = "\(shell.q),\(shell.r)"
            existingDict[key] = shell
        }
        
        // 새로운 Shell 추가 (중복되지 않는 것만, 기존 점유 상태 보존)
        for shell in new {
            let key = "\(shell.q),\(shell.r)"
            if existingDict[key] == nil {
                existingDict[key] = shell
            }
        }
        
        return Array(existingDict.values)
    }
    
    // 러닝 코스처럼 이어진 테스트 Shell 생성 (절대 좌표 기준, 고정된 패턴)
    private func addTestShells(to shells: [ShellGridCell], region: MKCoordinateRegion) -> [ShellGridCell] {
        var shellDict: [String: ShellGridCell] = [:]
        
        // 기존 Shell들을 딕셔너리로 변환
        for shell in shells {
            let key = "\(shell.q),\(shell.r)"
            shellDict[key] = shell
        }
        
        // 절대 좌표계 기준으로 고정된 러닝 코스 패턴 생성
        let runningRoutes = generateRunningRoutePatterns()
        
        for route in runningRoutes {
            for (index, hexCoord) in route.path.enumerated() {
                let key = "\(hexCoord.q),\(hexCoord.r)"
                
                // 해당 좌표의 Shell이 존재하는 경우에만 점유 설정
                if var shell = shellDict[key] {
                    shell.occupiedBy = route.tribe
                    shell.density = generateRealisticDensity(routeIndex: index, totalLength: route.path.count)
                    shellDict[key] = shell
                }
            }
        }
        
        return Array(shellDict.values)
    }
    
    // 러닝 코스 패턴 생성 (자연스럽고 밀집된 형태)
    private func generateRunningRoutePatterns() -> [RunningRoute] {
        var routes: [RunningRoute] = []
        
        // 붉은귀거북 - 한강 공원 러닝 코스 (곡선형 자연스러운 경로)
        let redMainRoute = RunningRoute(
            tribe: .redTurtle,
            path: generateNaturalPath(
                start: (2, 3),
                waypoints: [(8, 5), (15, 2), (22, 6), (25, 12), (20, 18), (12, 20), (5, 16)],
                densify: true
            )
        )
        routes.append(redMainRoute)
        
        // 붉은귀거북 - 추가 지선 코스들 (메인 코스와 연결)
        let redBranches = [
            RunningRoute(tribe: .redTurtle, path: generateNaturalPath(
                start: (15, 2), waypoints: [(18, -3), (22, -8), (25, -12)], densify: true
            )),
            RunningRoute(tribe: .redTurtle, path: generateNaturalPath(
                start: (12, 20), waypoints: [(8, 25), (3, 28), (-2, 30)], densify: true
            ))
        ]
        routes.append(contentsOf: redBranches)
        
        // 사막거북 - 남산 둘레길 러닝 코스 (원형 + 지선)
        let yellowMainRoute = RunningRoute(
            tribe: .yellowTurtle,
            path: generateNaturalPath(
                start: (-3, -2),
                waypoints: [(-8, -5), (-15, -8), (-22, -6), (-25, -2), (-22, 4), (-15, 8), (-8, 6), (-3, 2)],
                densify: true
            )
        )
        routes.append(yellowMainRoute)
        
        // 사막거북 - 지선 코스들
        let yellowBranches = [
            RunningRoute(tribe: .yellowTurtle, path: generateNaturalPath(
                start: (-15, -8), waypoints: [(-18, -15), (-20, -22), (-18, -28)], densify: true
            )),
            RunningRoute(tribe: .yellowTurtle, path: generateNaturalPath(
                start: (-8, 6), waypoints: [(-12, 12), (-18, 18), (-25, 22)], densify: true
            ))
        ]
        routes.append(contentsOf: yellowBranches)
        
        // 그리스거북 - 올림픽 공원 러닝 코스 (복잡한 네트워크)
        let blueMainRoute = RunningRoute(
            tribe: .blueTurtle,
            path: generateNaturalPath(
                start: (5, -8),
                waypoints: [(12, -12), (20, -15), (28, -12), (32, -5), (28, 2), (20, 5), (12, 2), (8, -3)],
                densify: true
            )
        )
        routes.append(blueMainRoute)
        
        // 그리스거북 - 교차 코스들
        let blueBranches = [
            RunningRoute(tribe: .blueTurtle, path: generateNaturalPath(
                start: (20, -15), waypoints: [(25, -25), (30, -35), (32, -42)], densify: true
            )),
            RunningRoute(tribe: .blueTurtle, path: generateNaturalPath(
                start: (28, 2), waypoints: [(35, 8), (42, 12), (48, 15)], densify: true
            )),
            RunningRoute(tribe: .blueTurtle, path: generateNaturalPath(
                start: (12, 2), waypoints: [(8, 8), (5, 15), (8, 22), (15, 25)], densify: true
            ))
        ]
        routes.append(contentsOf: blueBranches)
        
        return routes
    }
    
    // 자연스러운 경로 생성 (waypoint 기반, 밀집되고 곡선적)
    private func generateNaturalPath(
        start: (q: Int, r: Int), 
        waypoints: [(q: Int, r: Int)], 
        densify: Bool = true
    ) -> [HexCoordinate] {
        var path: [HexCoordinate] = []
        var currentPoint = start
        
        // 시작점 추가
        path.append(HexCoordinate(q: currentPoint.q, r: currentPoint.r))
        
        // 각 waypoint까지의 경로 생성
        for waypoint in waypoints {
            let segmentPath = generateHexPathBetween(
                from: currentPoint, 
                to: waypoint, 
                densify: densify
            )
            
            // 첫 번째 점은 중복이므로 제외
            path.append(contentsOf: segmentPath.dropFirst())
            currentPoint = waypoint
        }
        
        return path
    }
    
    // 두 점 사이의 육각형 그리드 경로 생성 (밀집되고 자연스러운)
    private func generateHexPathBetween(
        from start: (q: Int, r: Int), 
        to end: (q: Int, r: Int), 
        densify: Bool = true
    ) -> [HexCoordinate] {
        var path: [HexCoordinate] = []
        
        let deltaQ = end.q - start.q
        let deltaR = end.r - start.r
        let distance = max(abs(deltaQ), abs(deltaR), abs(deltaQ + deltaR))
        
        if distance == 0 {
            return [HexCoordinate(q: start.q, r: start.r)]
        }
        
        // 기본 경로 생성 (육각형 그리드의 직선 경로)
        for i in 0...distance {
            let t = Double(i) / Double(distance)
            let q = start.q + Int(round(Double(deltaQ) * t))
            let r = start.r + Int(round(Double(deltaR) * t))
            path.append(HexCoordinate(q: q, r: r))
        }
        
        // 밀집화: 경로 주변에 추가 Shell 생성
        if densify {
            var densifiedPath = path
            let hexDirections = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
            
            for coordinate in path {
                // 50% 확률로 인접한 Shell 추가 (무작위성 추가)
                if Int.random(in: 0...100) < 50 {
                    let randomDirection = hexDirections.randomElement()!
                    let adjacentQ = coordinate.q + randomDirection.0
                    let adjacentR = coordinate.r + randomDirection.1
                    densifiedPath.append(HexCoordinate(q: adjacentQ, r: adjacentR))
                }
                
                // 30% 확률로 대각선 방향 Shell 추가
                if Int.random(in: 0...100) < 30 {
                    let diagonalDirection = hexDirections.randomElement()!
                    let diagonalQ = coordinate.q + diagonalDirection.0 * 2
                    let diagonalR = coordinate.r + diagonalDirection.1 * 2
                    densifiedPath.append(HexCoordinate(q: diagonalQ, r: diagonalR))
                }
            }
            
            return densifiedPath
        }
        
        return path
    }
    
    // 육각형 그리드의 6방향 (인접한 셀들)
    private let hexDirections = [
        (1, 0),   // 동쪽
        (1, -1),  // 북동쪽
        (0, -1),  // 북서쪽
        (-1, 0),  // 서쪽
        (-1, 1),  // 남서쪽
        (0, 1)    // 남동쪽
    ]
    
    // 현실적인 Density 생성 (러닝 코스의 특성을 반영)
    private func generateRealisticDensity(routeIndex: Int, totalLength: Int) -> ShellDensity {
        let routeProgress = Double(routeIndex) / Double(totalLength)
        
        // 러닝 코스의 시작/끝 지점은 높은 density (집합 지점)
        if routeProgress < 0.1 || routeProgress > 0.9 {
            return weightedRandomDensity(weights: [0.1, 0.1, 0.2, 0.3, 0.3]) // 높은 density 선호
        }
        // 중간 지점은 다양한 density
        else if routeProgress > 0.3 && routeProgress < 0.7 {
            return weightedRandomDensity(weights: [0.15, 0.25, 0.35, 0.20, 0.05]) // 중간 density 선호
        }
        // 전환 구간은 낮은 density
        else {
            return weightedRandomDensity(weights: [0.3, 0.3, 0.25, 0.10, 0.05]) // 낮은 density 선호
        }
    }
    
    // 가중치 기반 랜덤 Density 선택
    private func weightedRandomDensity(weights: [Double]) -> ShellDensity {
        let random = Double.random(in: 0...1)
        var cumulativeWeight = 0.0
        
        for (index, weight) in weights.enumerated() {
            cumulativeWeight += weight
            if random <= cumulativeWeight {
                return ShellDensity.allCases[index]
            }
        }
        
        return .level3 // 기본값
    }
    
    // 러닝 코스 데이터 구조
    private struct RunningRoute {
        let tribe: TribeType
        let path: [HexCoordinate]
    }
    
    private struct HexCoordinate {
        let q: Int
        let r: Int
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    ShellMap()
        .background(Color.turtleRunTheme.backgroundColor)
} 
