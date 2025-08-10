import SwiftUI
import HealthKit

struct RecentShellDetailScreen: View {
    let workoutData: WorkoutDetailedData
    @Environment(\.dismiss) private var dismiss
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더 카드
                    headerCard
                    
                    // 기본 통계 카드
                    basicStatsCard
                    
                    // 심박수 정보 카드
                    heartRateCard
                    
                    // 페이스 및 속도 카드
                    paceSpeedCard
                    
                    // 루트 맵 카드 (있는 경우)
                    if !workoutData.routePoints.isEmpty {
                        routeMapCard
                    }
                    
                    // 추가 정보 카드
                    additionalInfoCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.turtleRunTheme.backgroundColor)
            .navigationTitle("최근 Shell 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundColor(.turtleRunTheme.accentColor)
                }
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            // 성공 아이콘
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Text("동기화 완료!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.turtleRunTheme.textColor)
            
            Text("새로운 Shell이 성공적으로 추가되었습니다")
                .font(.system(size: 16))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
            
            // 날짜 정보
            Text(formatDate(workoutData.startDate))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.turtleRunTheme.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.turtleRunTheme.accentColor.opacity(0.2))
                )
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .green.opacity(0.1), location: 0),
                    .init(color: .turtleRunTheme.accentColor.opacity(0.1), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
    }
    
    // MARK: - Basic Stats Card
    private var basicStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("러닝 통계")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.turtleRunTheme.textColor)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "figure.run",
                    title: "거리",
                    value: workoutData.formattedDistance,
                    color: .turtleRunTheme.accentColor
                )
                
                StatCard(
                    icon: "clock",
                    title: "시간",
                    value: workoutData.formattedDuration,
                    color: .blue
                )
                
                StatCard(
                    icon: "speedometer",
                    title: "페이스",
                    value: workoutData.formattedPace,
                    color: .orange
                )
                
                StatCard(
                    icon: "flame",
                    title: "칼로리",
                    value: "\(Int(workoutData.totalEnergyBurned)) kcal",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(Color.turtleRunTheme.mainColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Heart Rate Card
    private var heartRateCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("심박수")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.turtleRunTheme.textColor)
                Spacer()
            }
            
            if workoutData.heartRates.isEmpty {
                Text("심박수 데이터가 없습니다")
                    .font(.system(size: 14))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
                    .padding(.vertical, 20)
            } else {
                HStack(spacing: 20) {
                    HeartRateItem(
                        title: "평균",
                        value: "\(Int(workoutData.averageHeartRate))",
                        unit: "bpm",
                        color: .red
                    )
                    
                    HeartRateItem(
                        title: "최대",
                        value: "\(Int(workoutData.maxHeartRate))",
                        unit: "bpm",
                        color: .orange
                    )
                    
                    HeartRateItem(
                        title: "최소",
                        value: "\(Int(workoutData.minHeartRate))",
                        unit: "bpm",
                        color: .blue
                    )
                }
            }
        }
        .padding(20)
        .background(Color.turtleRunTheme.mainColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Pace Speed Card
    private var paceSpeedCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gauge.high")
                    .foregroundColor(.turtleRunTheme.accentColor)
                Text("속도 정보")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.turtleRunTheme.textColor)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(workoutData.formattedPace)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.turtleRunTheme.accentColor)
                    Text("평균 페이스")
                        .font(.system(size: 12))
                        .foregroundColor(.turtleRunTheme.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.turtleRunTheme.textSecondaryColor.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", workoutData.averageSpeed * 3.6))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("평균 속도 (km/h)")
                        .font(.system(size: 12))
                        .foregroundColor(.turtleRunTheme.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(Color.turtleRunTheme.mainColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Route Map Card
    private var routeMapCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.turtleRunTheme.accentColor)
                Text("러닝 경로")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.turtleRunTheme.textColor)
                Spacer()
                Button("전체보기") {
                    showingMap = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.turtleRunTheme.accentColor)
            }
            
            // 간단한 맵 미리보기 (실제로는 MapKit 사용)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.turtleRunTheme.secondaryColor)
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "location.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.turtleRunTheme.accentColor)
                        Text("경로 미리보기")
                            .font(.system(size: 14))
                            .foregroundColor(.turtleRunTheme.textSecondaryColor)
                    }
                )
        }
        .padding(20)
        .background(Color.turtleRunTheme.mainColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Additional Info Card
    private var additionalInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.turtleRunTheme.accentColor)
                Text("추가 정보")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.turtleRunTheme.textColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "figure.walk",
                    title: "총 스텝",
                    value: "\(workoutData.totalSteps) 걸음"
                )
                
                InfoRow(
                    icon: "calendar",
                    title: "시작 시간",
                    value: formatTime(workoutData.startDate)
                )
                
                InfoRow(
                    icon: "clock.badge.checkmark",
                    title: "종료 시간",
                    value: formatTime(workoutData.endDate)
                )
                
                InfoRow(
                    icon: "icloud.and.arrow.up",
                    title: "동기화 상태",
                    value: "완료"
                )
            }
        }
        .padding(20)
        .background(Color.turtleRunTheme.mainColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.turtleRunTheme.textColor)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.turtleRunTheme.secondaryColor.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HeartRateItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.turtleRunTheme.accentColor)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.turtleRunTheme.textColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    // 샘플 데이터 생성
    let sampleWorkout = HKWorkout(
        activityType: .running,
        start: Date().addingTimeInterval(-3600), // 1시간 전
        end: Date().addingTimeInterval(-600),    // 10분 전
        duration: 2940, // 49분
        totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 420),
        totalDistance: HKQuantity(unit: .meter(), doubleValue: 8500),
        metadata: nil
    )
    
    let sampleData = WorkoutDetailedData(workout: sampleWorkout)
    
    RecentShellDetailScreen(workoutData: sampleData)
        .background(Color.turtleRunTheme.backgroundColor)
}
