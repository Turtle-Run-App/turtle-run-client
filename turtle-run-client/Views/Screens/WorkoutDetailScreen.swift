import SwiftUI
import HealthKit

struct WorkoutDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var runningViewModel: RunningViewModel
    
    var body: some View {
        ZStack {
            Color.turtleRunTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 네비게이션 바
                TopBar(
                    title: "최근 러닝 상세",
                    leftButton: .back {
                        dismiss()
                    },
                    rightButton: .none
                )
                .zIndex(100)
                
                if runningViewModel.isLoadingDetailedData {
                    VStack {
                        Spacer()
                        LoadingIndicator()
                        Text("데이터를 불러오는 중...")
                            .font(.body)
                            .foregroundColor(.turtleRunTheme.textSecondaryColor)
                            .padding(.top, 16)
                        Spacer()
                    }
                } else if let workoutData = runningViewModel.latestWorkoutData {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 기본 정보 카드
                            basicInfoCard(workoutData)
                            
                            // 심박수 정보 카드
                            if !workoutData.heartRates.isEmpty {
                                heartRateCard(workoutData)
                            }
                            
                            // 경로 지도 카드
                            RouteMapView(routePoints: workoutData.routePoints)
                            
                            // 경로 정보 카드
                            if !workoutData.routePoints.isEmpty {
                                routeTableCard(workoutData)
                            } else {
                                // GPS 데이터가 없는 경우 디버그 정보 표시
                                debugRouteCard(workoutData)
                            }
                            
                            // 기타 데이터 카드
                            otherDataCard(workoutData)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                } else {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 60))
                                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                            
                            Text("러닝 데이터가 없습니다")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.turtleRunTheme.textColor)
                            
                            Text("HealthKit에서 러닝 기록을 찾을 수 없습니다.\n새로운 러닝을 시작해보세요!")
                                .font(.body)
                                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if runningViewModel.latestWorkoutData == nil {
                runningViewModel.loadLatestWorkoutDetailedData()
            }
        }
    }
    
    private func basicInfoCard(_ workoutData: WorkoutDetailedData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundColor(.turtleRunTheme.accentColor)
                Text("기본 정보")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 12) {
                infoRow(title: "운동 시간", value: workoutData.formattedDuration, icon: "clock")
                infoRow(title: "총 거리", value: workoutData.formattedDistance, icon: "location")
                infoRow(title: "평균 페이스", value: workoutData.formattedPace, icon: "speedometer")
                infoRow(title: "소모 칼로리", value: "\(Int(workoutData.totalEnergyBurned)) kcal", icon: "flame")
                infoRow(title: "시작 시간", value: formatDate(workoutData.startDate), icon: "calendar")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func heartRateCard(_ workoutData: WorkoutDetailedData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("심박수 정보")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 12) {
                infoRow(title: "평균 심박수", value: "\(Int(workoutData.averageHeartRate)) bpm", icon: "heart")
                infoRow(title: "최대 심박수", value: "\(Int(workoutData.maxHeartRate)) bpm", icon: "heart.fill")
                infoRow(title: "최소 심박수", value: "\(Int(workoutData.minHeartRate)) bpm", icon: "heart")
                infoRow(title: "심박수 측정 횟수", value: "\(workoutData.heartRates.count)회", icon: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func routeTableCard(_ workoutData: WorkoutDetailedData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("GPS 경로 (10m 구간)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            // 10m 구간별 데이터 생성
            let segments = createDistanceSegments(from: workoutData.routePoints, interval: 10.0)
            
            VStack(spacing: 0) {
                // 테이블 헤더
                HStack {
                    Text("구간")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(width: 60, alignment: .leading)
                    
                    Text("거리")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(width: 60, alignment: .trailing)
                    
                    Text("위도")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("경도")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("시간")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                
                // 테이블 내용
                tableContent(segments: segments)
            }
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func otherDataCard(_ workoutData: WorkoutDetailedData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("기타 데이터")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 12) {
                if workoutData.totalSteps > 0 {
                    infoRow(title: "총 스텝 수", value: "\(workoutData.totalSteps)걸음", icon: "figure.walk")
                }
                
                // 워크아웃 데이터로 계산한 페이스는 항상 표시
                infoRow(title: "평균 페이스", value: workoutData.formattedPace, icon: "speedometer")
                
                if !workoutData.speed.isEmpty {
                    infoRow(title: "평균 속도", value: String(format: "%.2f m/s", workoutData.averageSpeed), icon: "speedometer")
                }
                
                if !workoutData.calories.isEmpty {
                    infoRow(title: "활동 칼로리", value: "\(workoutData.calories.count)개 샘플", icon: "flame.fill")
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func infoRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.turtleRunTheme.accentColor)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.black)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.black)
                .fontWeight(.semibold)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    // 10m 구간별 데이터 구조
    struct DistanceSegment {
        let distance: Double
        let latitude: Double
        let longitude: Double
        let timestamp: Date
    }
    
    // 10m 구간별 데이터 생성 함수
    private func createDistanceSegments(from routePoints: [RunningLocationPoint], interval: Double) -> [DistanceSegment] {
        var segments: [DistanceSegment] = []
        var currentDistance = 0.0
        
        for point in routePoints {
            if point.cumulativeDistance >= currentDistance {
                segments.append(DistanceSegment(
                    distance: currentDistance,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    timestamp: point.timestamp
                ))
                currentDistance += interval
            }
        }
        
        return segments
    }
    
    // 테이블 내용 뷰
    private func tableContent(segments: [DistanceSegment]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    tableRow(index: index, segment: segment)
                }
            }
        }
        .frame(maxHeight: 200)
    }
    
    // 테이블 행 뷰
    private func tableRow(index: Int, segment: DistanceSegment) -> some View {
        HStack {
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.black)
                .frame(width: 60, alignment: .leading)
            
            Text(String(format: "%.0fm", segment.distance))
                .font(.caption)
                .foregroundColor(.black)
                .frame(width: 60, alignment: .trailing)
            
            Text(String(format: "%.4f", segment.latitude))
                .font(.caption)
                .foregroundColor(.black)
                .frame(width: 80, alignment: .trailing)
            
            Text(String(format: "%.4f", segment.longitude))
                .font(.caption)
                .foregroundColor(.black)
                .frame(width: 80, alignment: .trailing)
            
            Text(formatTime(segment.timestamp))
                .font(.caption)
                .foregroundColor(.black)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
    }
    
    // 경로 정보 카드 (GPS 데이터 없을 때)
    private func debugRouteCard(_ workoutData: WorkoutDetailedData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("경로 정보")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 12) {
                infoRow(title: "GPS 포인트 수", value: "\(workoutData.routePoints.count)개", icon: "location.fill")
                
                if let firstPoint = workoutData.routePoints.first {
                    infoRow(title: "시작 위치", value: String(format: "%.4f, %.4f", firstPoint.latitude, firstPoint.longitude), icon: "location")
                } else {
                    infoRow(title: "시작 위치", value: "GPS 데이터 없음", icon: "location")
                }
                
                if let lastPoint = workoutData.routePoints.last {
                    infoRow(title: "종료 위치", value: String(format: "%.4f, %.4f", lastPoint.latitude, lastPoint.longitude), icon: "location.circle")
                } else {
                    infoRow(title: "종료 위치", value: "GPS 데이터 없음", icon: "location.circle")
                }
                
                infoRow(title: "총 거리 (GPS)", value: String(format: "%.2f km", workoutData.routePoints.last?.cumulativeDistance ?? 0 / 1000), icon: "arrow.up.right")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    WorkoutDetailScreen(runningViewModel: RunningViewModel())
} 