import SwiftUI
import MapKit

struct RouteMapView: View {
    let routePoints: [RunningLocationPoint]
    @State private var region: MKCoordinateRegion = {
        let center = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        return MKCoordinateRegion(center: center, span: span)
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("운동 경로")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            if routePoints.isEmpty {
                VStack {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("GPS 경로 데이터가 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                mapView
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            updateMapRegion()
        }
        .onChange(of: routePoints) { _ in
            updateMapRegion()
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: routePoints) { point in
            MapAnnotation(coordinate: coordinate(for: point)) {
                routeAnnotation(for: point)
            }
        }
        .frame(height: 200)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func coordinate(for point: RunningLocationPoint) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
    }
    
    private func routeAnnotation(for point: RunningLocationPoint) -> some View {
        if point == routePoints.first {
            // 시작점
            return AnyView(
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            )
        } else if point == routePoints.last {
            // 종료점
            return AnyView(
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            )
        } else {
            // 중간점
            return AnyView(
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
            )
        }
    }
    
    private func updateMapRegion() {
        guard !routePoints.isEmpty else { return }
        
        let coordinates = routePoints.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.2 // 20% 여백
        let spanLon = (maxLon - minLon) * 1.2
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(spanLat, 0.001), longitudeDelta: max(spanLon, 0.001))
        )
    }
}

#Preview {
    RouteMapView(routePoints: [])
        .padding()
} 