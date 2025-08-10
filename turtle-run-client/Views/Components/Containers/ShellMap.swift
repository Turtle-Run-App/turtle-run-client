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
        
        // Preview 모드에서만 테스트 Shell 생성
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" && shells.isEmpty {
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
    

    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Preview용 테스트 Shell 생성 (Preview에서만 실행)
    private func addTestShells(to shells: [ShellGridCell], region: MKCoordinateRegion) -> [ShellGridCell] {
        var shellDict: [String: ShellGridCell] = [:]
        
        // 기존 Shell들을 딕셔너리로 변환
        for shell in shells {
            let key = "\(shell.q),\(shell.r)"
            shellDict[key] = shell
        }
        
        // 고정된 테스트 Shell 좌표들 (서울 시청 기준)
        let testShellData: [(q: Int, r: Int, tribe: TribeType, density: ShellDensity)] = [
            // 붉은귀거북 - 동쪽 러닝 코스
            (2, 3, .redTurtle, .level5), (3, 3, .redTurtle, .level4), (4, 2, .redTurtle, .level3),
            (5, 2, .redTurtle, .level4), (6, 1, .redTurtle, .level5), (7, 1, .redTurtle, .level3),
            (8, 0, .redTurtle, .level2), (9, 0, .redTurtle, .level4), (10, -1, .redTurtle, .level3),
            (11, -1, .redTurtle, .level5), (12, -2, .redTurtle, .level2), (13, -2, .redTurtle, .level4),
            
            // 사막거북 - 서쪽 러닝 코스
            (-2, -3, .yellowTurtle, .level4), (-3, -2, .yellowTurtle, .level5), (-4, -2, .yellowTurtle, .level3),
            (-5, -1, .yellowTurtle, .level4), (-6, -1, .yellowTurtle, .level2), (-7, 0, .yellowTurtle, .level5),
            (-8, 0, .yellowTurtle, .level3), (-9, 1, .yellowTurtle, .level4), (-10, 1, .yellowTurtle, .level2),
            (-11, 2, .yellowTurtle, .level5), (-12, 2, .yellowTurtle, .level3), (-13, 3, .yellowTurtle, .level4),
            
            // 그리스거북 - 남쪽 러닝 코스
            (1, -5, .blueTurtle, .level3), (0, -4, .blueTurtle, .level5), (-1, -4, .blueTurtle, .level2),
            (-2, -3, .blueTurtle, .level4), (-3, -3, .blueTurtle, .level3), (-4, -2, .blueTurtle, .level5),
            (-5, -2, .blueTurtle, .level2), (-6, -1, .blueTurtle, .level4), (-7, -1, .blueTurtle, .level3),
            (-8, 0, .blueTurtle, .level5), (-9, 0, .blueTurtle, .level2), (-10, 1, .blueTurtle, .level4),
            
            // 추가 산발적 Shell들
            (15, 5, .redTurtle, .level1), (-15, -5, .yellowTurtle, .level1), (5, -15, .blueTurtle, .level1),
            (8, 8, .redTurtle, .level2), (-8, 8, .yellowTurtle, .level2), (0, -8, .blueTurtle, .level2),
            (12, -8, .redTurtle, .level3), (-12, 8, .yellowTurtle, .level3), (3, 12, .blueTurtle, .level3)
        ]
        
        // 테스트 Shell 적용
        for (q, r, tribe, density) in testShellData {
            let key = "\(q),\(r)"
            if var shell = shellDict[key] {
                shell.occupiedBy = tribe
                shell.density = density
                shellDict[key] = shell
            }
        }
        
        return Array(shellDict.values)
    }
}

// MARK: - Preview용 LocationManager
class PreviewLocationManager: LocationManager {
    override init() {
        // Preview에서는 항상 서울 시청 위치로 고정 (super.init() 전에 설정)
        super.init()
        
        // 즉시 설정 (DispatchQueue 없이)
        self.currentLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        self.authorizationStatus = .authorizedWhenInUse
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        )
        
        print("🎭 PreviewLocationManager 초기화됨 - 서울 시청: \(self.currentLocation?.coordinate.latitude ?? 0), \(self.currentLocation?.coordinate.longitude ?? 0)")
    }
    
    // Preview에서는 실제 위치 서비스 시작하지 않음
    override func requestLocationPermission() {
        print("🎭 Preview에서 위치 권한 요청 - 이미 허용됨")
    }
}

#Preview {
    ShellMap()
        .background(Color.turtleRunTheme.backgroundColor)
} 


