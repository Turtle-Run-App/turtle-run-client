import SwiftUI
import MapKit

struct ShellMap: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var gridCells: [ShellGridCell] = []
    @State private var showingLocationAlert = false
    @State private var lastRegion: MKCoordinateRegion?
    @State private var shouldCenterOnUser = false
    
    var body: some View {
        ZStack {
            // 실제 지도와 Shell Grid
            ShellMapView(
                locationManager: locationManager,
                gridCells: $gridCells,
                onRegionChanged: handleRegionChange,
                shouldCenterOnUser: $shouldCenterOnUser
            )
            .onAppear {
                requestLocationPermissionIfNeeded()
                generateInitialGridCells()
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
    
    private func generateInitialGridCells() {
        // 초기 지역 설정 (서울 중심으로) - 기본 1km 줌 레벨
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009) // 약 1km 줌 레벨
        )
        
        // 초기 Grid Cell 생성 (1.5배 확장 영역)
        generateGridCellsForRegion(initialRegion)
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
    
    // MARK: - Grid Cell Generation Methods
    private func handleRegionChange(_ newRegion: MKCoordinateRegion) {
        // 이전 지역과 비교하여 재생성이 필요한지 확인
        if let lastRegion = lastRegion,
           !HexagonGridUtil.shouldRegenerateShells(currentRegion: newRegion, lastRegion: lastRegion) {
            return // 재생성 불필요
        }
        
        generateGridCellsForRegion(newRegion)
        lastRegion = newRegion
    }
    
    private func generateGridCellsForRegion(_ region: MKCoordinateRegion) {
        // 지도 가시 영역의 1.5배 범위로 Grid Cell 생성
        var newGridCells = HexagonGridUtil.generateGridCellsForMapRegion(region: region, expansionFactor: 1.5)
        
        // 기존 Grid Cell과 병합 (중복 제거)
        let existingCells = gridCells
        var mergedCells = mergeGridCells(existing: existingCells, new: newGridCells)
        
        // 테스트용으로 몇 개 Grid Cell을 Shell로 설정 (처음 생성 시에만)
        if gridCells.isEmpty && mergedCells.count > 10 {
            mergedCells = addTestShells(to: mergedCells)
        }
        
        // 거리 기반으로 Grid Cell 정리 (가장 먼 Grid부터 제거)
        let prunedCells = HexagonGridUtil.pruneDistantGridCells(
            gridCells: mergedCells,
            mapCenter: region.center,
            maxCount: 800, // 최대 800개 Grid Cell
            prioritizeShells: true // Shell 우선 보존
        )
        
        gridCells = prunedCells
        let shellCount = gridCells.filter { $0.isShell }.count
        print("최종 Grid Cell 개수: \(gridCells.count), Shell 개수: \(shellCount)")
    }
    
    // 기존 Grid Cell과 새로운 Grid Cell 병합 (중복 제거)
    private func mergeGridCells(existing: [ShellGridCell], new: [ShellGridCell]) -> [ShellGridCell] {
        var existingDict: [String: ShellGridCell] = [:]
        
        // 기존 Grid Cell을 딕셔너리로 변환 (q,r 좌표를 키로 사용)
        for cell in existing {
            let key = "\(cell.q),\(cell.r)"
            existingDict[key] = cell
        }
        
        // 새로운 Grid Cell 추가 (중복되지 않는 것만)
        for cell in new {
            let key = "\(cell.q),\(cell.r)"
            if existingDict[key] == nil {
                existingDict[key] = cell
            }
        }
        
        return Array(existingDict.values)
    }
    
    // 테스트용 Shell 추가
    private func addTestShells(to gridCells: [ShellGridCell]) -> [ShellGridCell] {
        var mutableCells = gridCells
        
        if mutableCells.indices.contains(5) {
            mutableCells[5].occupiedBy = .redTurtle
            mutableCells[5].occupiedAt = Date()
        }
        
        if mutableCells.indices.contains(8) {
            mutableCells[8].occupiedBy = .blueTurtle
            mutableCells[8].occupiedAt = Date().addingTimeInterval(-3600)
        }
        
        if mutableCells.indices.contains(12) {
            mutableCells[12].occupiedBy = .yellowTurtle
            mutableCells[12].occupiedAt = Date().addingTimeInterval(-7200)
        }
        
        // 추가 테스트 Shell들 (점유된 Grid Cell들)
        let testCellIndices = [15, 20, 25, 30, 35, 40, 45]
        let testTribes: [TribeType] = [.redTurtle, .blueTurtle, .yellowTurtle]
        
        for (index, cellIndex) in testCellIndices.enumerated() {
            if mutableCells.indices.contains(cellIndex) {
                mutableCells[cellIndex].occupiedBy = testTribes[index % testTribes.count]
                mutableCells[cellIndex].occupiedAt = Date().addingTimeInterval(-Double(index * 1800)) // 30분씩 차이
            }
        }
        
        return mutableCells
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
