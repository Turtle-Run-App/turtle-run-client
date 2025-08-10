import SwiftUI
import MapKit

struct ShellMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var gridCells: [ShellGridCell]
    let onRegionChanged: (MKCoordinateRegion) -> Void
    @Binding var shouldCenterOnUser: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // 3D view 기능 비활성화 및 compass 상시 노출
        mapView.isPitchEnabled = false          // 3D 틸트(피치) 비활성화
        mapView.showsCompass = true             // compass 상시 노출
        mapView.isRotateEnabled = true          // 회전은 허용 (compass 기능을 위해)
        
        // 지도 줌 레벨 제한 설정 (최대 줌아웃 3km 제한)
        let cameraZoomRange = MKMapView.CameraZoomRange(
            minCenterCoordinateDistance: 800,   // 최소 거리 (최대 줌인) - 20m Grid 가시성
            maxCenterCoordinateDistance: 3000   // 최대 거리 (최대 줌아웃) - 3km 제한
        )
        mapView.setCameraZoomRange(cameraZoomRange, animated: false)
        
        // 초기 지도 위치 설정 (1km 줌 레벨)
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        )
        mapView.setRegion(initialRegion, animated: false)
        
        // 지도 스타일 설정
        mapView.preferredConfiguration = MKStandardMapConfiguration()
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 사용자 위치로 이동이 요청된 경우
        if shouldCenterOnUser, let location = locationManager.currentLocation {
            let userRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009) // 1km 줌 레벨
            )
            mapView.setRegion(userRegion, animated: true)
            
            // 플래그 리셋
            DispatchQueue.main.async {
                self.shouldCenterOnUser = false
            }
        }
        
        // 기존 Grid Cell 오버레이 제거
        let existingOverlays = mapView.overlays.filter { $0 is ShellGridPolygon }
        mapView.removeOverlays(existingOverlays)
        
        // 새로운 Grid Cell 오버레이 추가
        let gridOverlays = gridCells.map { gridCell in
            ShellGridPolygon(gridCell: gridCell)
        }
        mapView.addOverlays(gridOverlays)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ShellMapView
        private var regionChangeTimer: Timer?
        
        init(_ parent: ShellMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let gridPolygon = overlay as? ShellGridPolygon {
                let renderer = MKPolygonRenderer(polygon: gridPolygon.polygon)
                
                // Grid Cell의 점유 상태에 따라 렌더링 설정
                if let tribe = gridPolygon.gridCell.occupiedBy,
                   let density = gridPolygon.gridCell.density {
                    // Shell인 경우 (점유된 Grid Cell) - Density에 따른 색상 강도 적용
                    let densityColor = tribe.colorWithDensity(density)
                    renderer.fillColor = UIColor(densityColor)
                    renderer.strokeColor = UIColor(tribe.color) // 테두리는 기본 색상
                    renderer.lineWidth = 2.5
                } else {
                    // 일반 Grid Cell인 경우 - 테두리만 표시
                    renderer.fillColor = UIColor.clear
                    renderer.strokeColor = UIColor.systemGray.withAlphaComponent(0.2)
                    renderer.lineWidth = 0.8
                }
                
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // 지도 이동이 시작될 때 기존 타이머 취소
            regionChangeTimer?.invalidate()
            regionChangeTimer = nil
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 기존 타이머 취소
            regionChangeTimer?.invalidate()
            
            // debounce: 0.5초 후에 Shell 업데이트 실행
            regionChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    // 콜백으로 지도 영역 변경 알림
                    self.parent.onRegionChanged(mapView.region)
                }
            }
        }
    }
}

// MARK: - Shell Grid Polygon Overlay
class ShellGridPolygon: NSObject, MKOverlay {
    let gridCell: ShellGridCell
    let polygon: MKPolygon
    
    init(gridCell: ShellGridCell) {
        self.gridCell = gridCell
        
        let vertices = gridCell.hexagonVertices
        let coordinates = vertices.map { $0 }
        self.polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        
        super.init()
    }
    
    var coordinate: CLLocationCoordinate2D {
        return gridCell.coordinate
    }
    
    var boundingMapRect: MKMapRect {
        return polygon.boundingMapRect
    }
}
