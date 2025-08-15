import SwiftUI
import MapKit

struct ShellMap: View {
    @StateObject private var locationManager: LocationManager = {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return PreviewLocationManager()
        } else {
            return LocationManager.shared
        }
    }()
    @State private var shells: [ShellGridCell] = []
    @State private var showingLocationAlert = false
    @State private var lastRegion: MKCoordinateRegion?
    @State private var shouldCenterOnUser = false
    @State private var hasReceivedInitialLocation = false
    @State private var hasDummyDataGenerated = false // 더미 데이터 생성 여부 플래그
    
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
                if let location = newLocation, !hasReceivedInitialLocation {
                    hasReceivedInitialLocation = true
                    shouldCenterOnUser = true
                    
                    // 실제 사용자 위치 기준으로 Shell 재생성
                    let userRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
                    )
                    generateShellsForRegion(userRegion)
                    lastRegion = userRegion
                    
                    print("📍 사용자 위치 받음: \(location.coordinate.latitude), \(location.coordinate.longitude)")
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
        
        // 개발/테스트 모드에서 더미 Shell 생성 (실제 위치를 받은 후 1회만)
        // 또는 위치 권한이 거부된 상태에서 현재 지도 중심이 서울 시청이 아닌 경우
        let isNotSeoulCityHall = abs(region.center.latitude - 37.5665) > 0.001 || 
                                abs(region.center.longitude - 126.978) > 0.001
        
        if !hasDummyDataGenerated && (hasReceivedInitialLocation || isNotSeoulCityHall) {
            mergedShells = addDummyShells(to: mergedShells, region: region)
            hasDummyDataGenerated = true
            print("🐢 더미 Shell 데이터 생성됨 - 지도 중심: \(region.center.latitude), \(region.center.longitude)")
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
    

    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - 현재 위치 기준 더미 Shell 생성 (개발/테스트용)
    private func addDummyShells(to shells: [ShellGridCell], region: MKCoordinateRegion) -> [ShellGridCell] {
        var shellDict: [String: ShellGridCell] = [:]
        
        // 기존 Shell들을 딕셔너리로 변환
        for shell in shells {
            let key = "\(shell.q),\(shell.r)"
            shellDict[key] = shell
        }
        
        // 현재 지도 중심을 기준으로 상대적 좌표 (0, 0) 사용
        let centerQ = 0
        let centerR = 0
        
        // 현재 지도 중심 기준으로 동적 Shell 패턴 생성
        let dummyShellData = generateDummyShellPattern(
            centerQ: centerQ, 
            centerR: centerR,
            mapCenter: region.center // 실제 지도 중심 좌표 전달
        )
        
        // 더미 Shell 적용 (현재 지도 중심 기준으로 좌표 변환)
        let mapCenterHex = HexagonGridUtil.coordinateToHex(coordinate: region.center)
        print("🗺️ 지도 중심 육각 좌표: q=\(mapCenterHex.q), r=\(mapCenterHex.r)")
        print("🎯 생성할 더미 Shell 개수: \(dummyShellData.count)")
        
        var appliedShellCount = 0
        for (relativeQ, relativeR, tribe, density) in dummyShellData {
            // 상대 좌표를 현재 지도 중심 기준 절대 좌표로 변환
            let absoluteQ = mapCenterHex.q + relativeQ
            let absoluteR = mapCenterHex.r + relativeR
            let key = "\(absoluteQ),\(absoluteR)"
            
            if var shell = shellDict[key] {
                shell.occupiedBy = tribe
                shell.density = density
                shellDict[key] = shell
                appliedShellCount += 1
            }
        }
        
        print("✅ 실제 적용된 Shell 개수: \(appliedShellCount)")
        let shellCount = Array(shellDict.values).filter { $0.isShell }.count
        print("🐢 최종 Shell 개수: \(shellCount)")
        
        return Array(shellDict.values)
    }
    
    // 현재 위치 기준으로 다양한 Shell 패턴 생성
    private func generateDummyShellPattern(
        centerQ: Int, 
        centerR: Int, 
        mapCenter: CLLocationCoordinate2D
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        var shellData: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        print("🎨 더미 패턴 생성 시작 - 중심: (\(centerQ), \(centerR))")
        
        // 패턴 1: 붉은귀거북 - 동쪽 러닝 코스 (현재 위치에서 동쪽으로)
        let redTurtlePattern = generateRunningCoursePattern(
            centerQ: centerQ, 
            centerR: centerR,
            direction: .east,
            tribe: .redTurtle,
            length: 12
        )
        shellData.append(contentsOf: redTurtlePattern)
        print("🔴 붉은귀거북 패턴: \(redTurtlePattern.count)개")
        
        // 패턴 2: 사막거북 - 서쪽 러닝 코스 (현재 위치에서 서쪽으로)
        let yellowTurtlePattern = generateRunningCoursePattern(
            centerQ: centerQ,
            centerR: centerR,
            direction: .west,
            tribe: .yellowTurtle,
            length: 12
                )
        shellData.append(contentsOf: yellowTurtlePattern)
        print("🟡 사막거북 패턴: \(yellowTurtlePattern.count)개")
        
        // 패턴 3: 그리스거북 - 남쪽 러닝 코스 (현재 위치에서 남쪽으로)
        let blueTurtlePattern = generateRunningCoursePattern(
            centerQ: centerQ,
            centerR: centerR,
            direction: .south,
            tribe: .blueTurtle,
            length: 12
        )
        shellData.append(contentsOf: blueTurtlePattern)
        print("🔵 그리스거북 패턴: \(blueTurtlePattern.count)개")
        
        // 패턴 4: 현재 위치 주변 랜덤 Shell들
         let randomPattern = generateRandomShellsAroundCenter(
             centerQ: centerQ,
             centerR: centerR,
             radius: 15,
             count: 20
         )
         shellData.append(contentsOf: randomPattern)
         print("🎲 랜덤 패턴: \(randomPattern.count)개")
        
        print("📊 총 더미 패턴: \(shellData.count)개")
        return shellData
    }
    
    // 면적을 가진 러닝 코스 덩어리 패턴 생성 (여러 사람의 경로가 겹친 효과)
    private func generateRunningCoursePattern(
        centerQ: Int,
        centerR: Int,
        direction: HexDirection,
        tribe: TribeType,
        length: Int
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var pattern: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        let (baseQ, baseR) = direction.delta
        
        // 메인 코스 중심선 생성 (약간의 곡선 효과)
        var mainPath: [(q: Int, r: Int)] = []
        for i in 1...length {
            // 기본 방향에 약간의 곡선 변화 추가
            let curveOffset = sin(Double(i) * 0.3) * 0.8 // 부드러운 곡선
            let perpQ = direction == .east || direction == .west ? 0 : 1
            let perpR = direction == .east || direction == .west ? 1 : 0
            
            let q = centerQ + (baseQ * i) + Int(curveOffset * Double(perpQ))
            let r = centerR + (baseR * i) + Int(curveOffset * Double(perpR))
            
            mainPath.append((q: q, r: r))
        }
        
        // 메인 패스 주변에 면적을 가진 덩어리 생성
        for (index, (centerQ, centerR)) in mainPath.enumerated() {
            let progress = Double(index) / Double(mainPath.count - 1)
            
            // 거리에 따른 기본 밀도 계산
            let baseDensity = calculateBaseDensity(for: index, totalLength: length)
            
            // 코스 폭 계산 (시작점이 넓고 점점 좁아짐)
            let width = max(2, Int(4 * (1.0 - progress * 0.5)))
            
            // 중심점 주변에 덩어리 생성
            let clusterCells = generateRunningCluster(
                centerQ: centerQ,
                centerR: centerR,
                width: width,
                baseDensity: baseDensity,
                tribe: tribe
            )
            
            pattern.append(contentsOf: clusterCells)
        }
        
        // 추가 분기 경로 생성 (일부 러너들이 다른 경로로 뛴 효과)
        let branchPaths = generateBranchPaths(
            mainPath: mainPath,
            direction: direction,
            tribe: tribe
        )
        pattern.append(contentsOf: branchPaths)
        
        return pattern
    }
    
    // 러닝 코스 한 지점 주변의 덩어리 생성
    private func generateRunningCluster(
        centerQ: Int,
        centerR: Int,
        width: Int,
        baseDensity: ShellDensity,
        tribe: TribeType
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var cluster: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        
        // 중심점 주변 원형으로 Shell 배치
        for deltaQ in -width...width {
            for deltaR in -width...width {
                // 육각형 그리드에서의 거리 계산
                let distance = max(abs(deltaQ), abs(deltaR), abs(deltaQ + deltaR))
                
                if distance <= width {
                    let q = centerQ + deltaQ
                    let r = centerR + deltaR
                    
                    // 중심에서 멀어질수록 밀도 감소 + 랜덤 요소
                    let densityReduction = distance
                    let randomFactor = Double.random(in: 0.7...1.3)
                    
                    let adjustedDensity = adjustDensity(
                        baseDensity,
                        reduction: densityReduction,
                        randomFactor: randomFactor
                    )
                    
                    // 일정 확률로 Shell 생성 (가장자리는 낮은 확률)
                    let probability = 1.0 - (Double(distance) / Double(width + 1)) * 0.6
                    if Double.random(in: 0...1) < probability {
                        cluster.append((q: q, r: r, tribe: tribe, density: adjustedDensity))
                    }
                }
            }
        }
        
        return cluster
    }
    
    // 분기 경로 생성 (일부 러너들의 다른 루트)
    private func generateBranchPaths(
        mainPath: [(q: Int, r: Int)],
        direction: HexDirection,
        tribe: TribeType
    ) -> [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] {
        
        var branches: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = []
        
        // 메인 패스 중간 지점들에서 분기 생성
        let branchPoints = stride(from: 2, to: mainPath.count - 2, by: 4)
        
        for branchIndex in branchPoints {
            let (startQ, startR) = mainPath[branchIndex]
            
            // 분기 방향 (메인 방향에 수직)
            let branchDirections = getPerpendicularDirections(to: direction)
            
            for branchDir in branchDirections {
                let (branchQ, branchR) = branchDir.delta
                let branchLength = Int.random(in: 2...4)
                
                for i in 1...branchLength {
                    let q = startQ + (branchQ * i)
                    let r = startR + (branchR * i)
                    
                    // 분기 밀도 상향 조정
                    let density: ShellDensity = i == 1 ? .level4 : .level3
                    
                    // 50% 확률로 생성 (모든 분기가 다 생기면 너무 복잡함)
                    if Double.random(in: 0...1) < 0.5 {
                        branches.append((q: q, r: r, tribe: tribe, density: density))
                    }
                }
            }
        }
        
        return branches
    }
    
    // 거리에 따른 기본 밀도 계산 (전체적으로 높은 밀도 유지)
    private func calculateBaseDensity(for index: Int, totalLength: Int) -> ShellDensity {
        let progress = Double(index) / Double(totalLength - 1)
        
        if progress < 0.3 {
            return .level5  // 시작 지점 - 매우 높음
        } else if progress < 0.6 {
            return .level4  // 초중반 - 높음
        } else if progress < 0.8 {
            return .level4  // 중후반 - 높음 (level3 → level4로 상향)
        } else {
            return .level3  // 후반 - 보통 (level2 → level3으로 상향)
        }
    }
    
    // 밀도 조정 (거리와 랜덤 팩터 반영, 덜 급격한 감소)
    private func adjustDensity(
        _ baseDensity: ShellDensity,
        reduction: Int,
        randomFactor: Double
    ) -> ShellDensity {
        let baseValue = baseDensity.rawValue
        
        // 거리에 따른 감소를 덜 급격하게 조정
        let gentleReduction = max(0, reduction - 1) // 첫 번째 거리는 감소 없음
        let reductionFactor = min(1.0, Double(gentleReduction) * 0.3) // 30%씩만 감소
        
        let adjustedValue = max(2, Int(Double(baseValue) * (1.0 - reductionFactor) * randomFactor))
        
        return ShellDensity(rawValue: min(5, adjustedValue)) ?? .level2
    }
    
    // 주어진 방향에 수직인 방향들 반환
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
    
    // 현재 위치 주변 랜덤 Shell 생성
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
            // 랜덤 위치 생성 (원형 분포)
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
}

// MARK: - Preview용 LocationManager
class PreviewLocationManager: LocationManager {
    private let seoulCityHall = CLLocation(latitude: 37.5665, longitude: 126.9780)
    
    override init() {
        super.init()
        
        // 즉시 서울 시청 위치로 설정
        self.currentLocation = seoulCityHall
        self.authorizationStatus = .authorizedWhenInUse
        self.region = MKCoordinateRegion(
            center: seoulCityHall.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        )
        
        print("🎭 PreviewLocationManager 초기화됨 - 서울 시청: \(seoulCityHall.coordinate.latitude), \(seoulCityHall.coordinate.longitude)")
    }
    
    // Preview에서는 실제 위치 서비스 시작하지 않고 항상 서울 시청 반환
    override func requestLocationPermission() {
        print("🎭 Preview에서 위치 권한 요청 - 이미 허용됨")
        
        // 권한 허용된 것처럼 처리하고 서울 시청 위치 제공
        DispatchQueue.main.async {
            self.currentLocation = self.seoulCityHall
            self.authorizationStatus = .authorizedWhenInUse
        }
    }
    
    // 현재 위치 속성이 요청될 때마다 항상 서울 시청 반환 보장
    override var currentLocation: CLLocation? {
        get {
            return seoulCityHall
        }
        set {
            // Preview에서는 위치 변경을 무시하고 항상 서울 시청 유지
            super.currentLocation = seoulCityHall
        }
    }
    
    // 위치 업데이트 중단 (Preview에서는 아무것도 하지 않음)
    override func stopLocationUpdates() {
        print("🎭 Preview에서 위치 업데이트 중단")
    }
}

#Preview {
    ShellMap()
        .background(Color.turtleRunTheme.backgroundColor)
} 


