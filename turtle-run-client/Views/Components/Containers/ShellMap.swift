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
    
    @StateObject private var shellMapService = ShellMapService.shared
    @State private var shells: [ShellGridCell] = []
    @State private var showingLocationAlert = false
    @State private var lastRegion: MKCoordinateRegion?
    @State private var shouldCenterOnUser = false
    @State private var hasReceivedInitialLocation = false
    @State private var isLoadingShells = false
    
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
                loadInitialShells()
            }
            .onReceive(locationManager.$currentLocation) { newLocation in
                handleLocationUpdate(newLocation)
            }
            
            // 위치 권한이 없을 때 표시할 오버레이
            if locationManager.authorizationStatus == .denied || 
               locationManager.authorizationStatus == .restricted {
                locationPermissionOverlay
            }
            
            // 내 위치 버튼
            myLocationButton
            
            // 로딩 인디케이터
            if isLoadingShells {
                loadingOverlay
            }
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
                
                Button(action: centerOnUserLocation) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.turtleRunTheme.accentColor)
                        .frame(width: 50, height: 50)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - 로딩 오버레이
    private var loadingOverlay: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.turtleRunTheme.accentColor)
            
            Text("Shell 데이터 로딩 중...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .padding(20)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
    
    // MARK: - Event Handlers
    private func handleLocationUpdate(_ newLocation: CLLocation?) {
        guard let location = newLocation, !hasReceivedInitialLocation else { return }
        
        hasReceivedInitialLocation = true
        shouldCenterOnUser = true
        
        let userRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        )
        
        loadShellsForRegion(userRegion)
        lastRegion = userRegion
        
        print("📍 사용자 위치 받음: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    private func handleRegionChange(_ region: MKCoordinateRegion) {
        guard shouldLoadShellsForRegion(region) else { return }
        
        loadShellsForRegion(region)
        lastRegion = region
    }
    
    private func shouldLoadShellsForRegion(_ region: MKCoordinateRegion) -> Bool {
        guard let lastRegion = lastRegion else { return true }
        
        let centerDistance = CLLocation(
            latitude: lastRegion.center.latitude,
            longitude: lastRegion.center.longitude
        ).distance(from: CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        ))
        
        // 500m 이상 이동했을 때만 새로 로드
        return centerDistance > 500
    }
    
    private func loadShellsForRegion(_ region: MKCoordinateRegion) {
        Task {
            await MainActor.run {
                isLoadingShells = true
            }
            
            let newShells = await shellMapService.fetchShellData(for: region)
            
            await MainActor.run {
                shells = newShells
                isLoadingShells = false
                print("🐢 Shell 데이터 업데이트됨: \(shells.filter { $0.isShell }.count)개")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func requestLocationPermissionIfNeeded() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
        }
    }
    
    private func loadInitialShells() {
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.978),
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        )
        
        loadShellsForRegion(defaultRegion)
        lastRegion = defaultRegion
    }
    
    private func centerOnUserLocation() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            showingLocationAlert = true
            return
        }
        
        shouldCenterOnUser = true
        
        if let location = locationManager.currentLocation {
            let userRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
            )
            loadShellsForRegion(userRegion)
        }
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Preview용 LocationManager
class PreviewLocationManager: LocationManager {
    private let seoulCityHall = CLLocation(latitude: 37.5665, longitude: 126.9780)
    
    override init() {
        super.init()
        
        self.currentLocation = seoulCityHall
        self.authorizationStatus = .authorizedWhenInUse
        self.region = MKCoordinateRegion(
            center: seoulCityHall.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        )
        
        print("🎭 PreviewLocationManager 초기화됨 - 서울 시청: \(seoulCityHall.coordinate.latitude), \(seoulCityHall.coordinate.longitude)")
    }
    
    override func requestLocationPermission() {
        print("🎭 Preview에서 위치 권한 요청 - 이미 허용됨")
        
        DispatchQueue.main.async {
            self.currentLocation = self.seoulCityHall
            self.authorizationStatus = .authorizedWhenInUse
        }
    }
    
    override var currentLocation: CLLocation? {
        get {
            return seoulCityHall
        }
        set {
            super.currentLocation = seoulCityHall
        }
    }
    
    override func stopLocationUpdates() {
        print("🎭 Preview에서 위치 업데이트 중단")
    }
}

#Preview {
    ShellMap()
        .background(Color.turtleRunTheme.backgroundColor)
} 


