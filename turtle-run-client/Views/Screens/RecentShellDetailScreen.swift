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
                    // Shell 시각화 카드
                    shellVisualizationCard
                    
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
            .navigationTitle("🐢 Shell 동기화 완료!")
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
    
    // MARK: - Shell Visualization Card
    private var shellVisualizationCard: some View {
        VStack(spacing: 20) {
            // Shell 클러스터 시각화
            shellClusterVisualization
            
            // Shell 정보
            VStack(spacing: 12) {
                Text("새로운 Shell이 생성되었습니다!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Text("러닝 거리: \(workoutData.formattedDistance)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.turtleRunTheme.accentColor)
                
                // 날짜 정보
                Text(formatDate(workoutData.startDate))
                    .font(.system(size: 14))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.turtleRunTheme.accentColor.opacity(0.15))
                    )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    .turtleRunTheme.accentColor.opacity(0.1),
                    .turtleRunTheme.secondaryColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.turtleRunTheme.accentColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
    }
    
    // MARK: - Shell Cluster Visualization
    private var shellClusterVisualization: some View {
        VStack(spacing: 16) {
            Text("생성된 Shell")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.turtleRunTheme.textColor)
            
            // Shell 그리드 패턴 (정육각형들)
            shellGridPattern
        }
    }
    
    // MARK: - Shell Grid Pattern
    private var shellGridPattern: some View {
        let shellCount = calculateShellCount()
        
        return VStack(spacing: 12) {
            // 육각형 그리드에 가상 러닝 경로 표시
            shellGridVisualization(shellCount: shellCount)
            
            // Shell 개수와 종족 정보 표시
            VStack(spacing: 4) {
                Text("\(shellCount)개의 Shell")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Text("부족: 그리스거북")
                    .font(.system(size: 12))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
            }
        }
    }
    
        // MARK: - Shell Grid Visualization
    private func shellGridVisualization(shellCount: Int) -> some View {
        let hexSize: CGFloat = 16  // 크기 증가
        let runningPathIndices = getRunningPathIndices(shellCount: shellCount)
        let gridCells = generateGridCells()
        
        return ZStack {
            // HexagonGridUtil 방식을 사용한 정확한 육각형 그리드
            ForEach(Array(gridCells.enumerated()), id: \.offset) { index, cell in
                let position = hexToPixelPosition(q: cell.q, r: cell.r, hexSize: hexSize)
                
                HexagonShape()
                    .fill(runningPathIndices.contains(index) ? 
                          getShellColor(for: index) : 
                          Color.clear)
                    .frame(width: hexSize * 2, height: hexSize * 2)
                    .rotationEffect(.degrees(30)) // flat-top 방향으로 회전
                    .position(x: position.x, y: position.y)
            }
        }
        .frame(width: 280, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.turtleRunTheme.secondaryColor.opacity(0.3))
        )
    }
    
    // MARK: - Generate Grid Cells
    private func generateGridCells() -> [(q: Int, r: Int)] {
        var cells: [(q: Int, r: Int)] = []
        
        // Shell 크기가 커진 만큼 그리드 개수 감소
        let qRange = -4...4   // 가로 범위 (9개)
        let rRange = -1...1   // 세로 범위 (3개)
        
        for r in rRange {
            for q in qRange {
                cells.append((q: q, r: r))
            }
        }
        
        return cells
    }
    
    // MARK: - Get Shell Color with Density
    private func getShellColor(for index: Int) -> Color {
        let density = getShellDensity(for: index)
        return Color.turtleRunTheme.blueTurtle.opacity(density.alphaValue)
    }
    
    // MARK: - Get Shell Density
    private func getShellDensity(for index: Int) -> ShellDensity {
        // 인덱스와 워크아웃 데이터를 기반으로 다양한 density 생성
        let distance = workoutData.totalDistance / 1000.0
        let seed = Int(workoutData.startDate.timeIntervalSince1970) + index
        
        // 기본 밀도 계산 (거리 기반)
        let baseDensity = min(5, max(1, Int(distance / 2.0) + 1))
        
        // 인덱스 기반 변화 (-2 ~ +2)
        let variation = (seed % 5) - 2
        let finalDensity = max(1, min(5, baseDensity + variation))
        
        return ShellDensity(rawValue: finalDensity) ?? .level3
    }
    
    // MARK: - Hex to Pixel Position (컨테이너에 맞게 정렬)
    private func hexToPixelPosition(q: Int, r: Int, hexSize: CGFloat) -> CGPoint {
        // 컨테이너에 맞게 정렬된 육각형 그리드 좌표 변환
        // flat-top 육각형 방향 사용 (컨테이너와 평행하게)
        let x = hexSize * (sqrt(3.0) * CGFloat(q) + sqrt(3.0)/2.0 * CGFloat(r))
        let y = hexSize * (3.0/2.0 * CGFloat(r))
        
        // 컨테이너 중앙으로 이동
        let centerX: CGFloat = 140
        let centerY: CGFloat = 60
        
        return CGPoint(x: centerX + x, y: centerY + y)
    }
    
    // MARK: - Get Running Path Indices
    private func getRunningPathIndices(shellCount: Int) -> Set<Int> {
        var pathIndices: Set<Int> = []
        let gridCells = generateGridCells()
        
        // 왼쪽에서 시작해서 오른쪽으로 진행하는 러닝 경로
        let qRange = -4...4
        let rRange = -1...1
        
        // 중간 행에서 시작
        let startR = 0
        var currentQ = -3  // 왼쪽에서 시작
        var currentR = startR
        
        let maxShells = min(shellCount, 12) // 작아진 그리드에 맞게 조정
        
        for i in 0..<maxShells {
            // 현재 위치의 인덱스 찾기
            if let cellIndex = gridCells.firstIndex(where: { $0.q == currentQ && $0.r == currentR }) {
                pathIndices.insert(cellIndex)
            }
            
            // 다음 위치 결정 (주로 오른쪽으로, 가끔 위아래로)
            if i % 4 == 3 && currentR > rRange.lowerBound { // 가끔 위로
                currentR -= 1
            } else if i % 3 == 2 && currentR < rRange.upperBound { // 가끔 아래로
                currentR += 1
            } else if currentQ < qRange.upperBound { // 주로 오른쪽으로
                currentQ += 1
            } else {
                break // 오른쪽 끝에 도달
            }
        }
        
        return pathIndices
    }
    
    // MARK: - Hexagon Shell Shape
    private func hexagonShell(tribe: TribeType, density: ShellDensity, size: CGFloat) -> some View {
        HexagonShape()
            .fill(tribe.colorWithDensity(density))
            .overlay(
                HexagonShape()
                    .stroke(tribe.color, lineWidth: 1.5)
            )
            .frame(width: size, height: size)
            .shadow(color: tribe.color.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Methods
    private func calculateShellCount() -> Int {
        // 거리 기반으로 Shell 개수 계산 (1km당 약 3-5개)
        let distance = workoutData.totalDistance / 1000.0 // km로 변환
        return max(1, min(12, Int(distance * 4))) // 최소 1개, 최대 12개
    }
    

    
    private func getDensityForShell(index: Int) -> ShellDensity {
        // 거리와 인덱스 기반으로 밀도 계산
        let distance = workoutData.totalDistance / 1000.0
        let baseDensity = min(5, max(1, Int(distance / 2.0) + 1)) // 거리 기반 기본 밀도
        let variation = (index % 3) - 1 // -1, 0, 1 변화
        let finalDensity = max(1, min(5, baseDensity + variation))
        
        return ShellDensity(rawValue: finalDensity) ?? .level3
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
    
    var sampleData = WorkoutDetailedData(workout: sampleWorkout)
    
    // 가상의 심박수 데이터 생성
    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
    let startDate = sampleWorkout.startDate
    var heartRateSamples: [HKQuantitySample] = []
    
    // 49분 동안 5분마다 심박수 데이터 생성 (총 10개)
    for i in 0..<10 {
        let timeOffset = TimeInterval(i * 5 * 60) // 5분 간격
        let sampleDate = startDate.addingTimeInterval(timeOffset)
        
        // 심박수 변화 (140-180 bpm 범위에서 변화)
        let baseHeartRate = 155.0
        let variation = sin(Double(i) * 0.5) * 15.0 + Double.random(in: -10...10)
        let heartRate = max(130, min(185, baseHeartRate + variation))
        
        let quantity = HKQuantity(unit: heartRateUnit, doubleValue: heartRate)
        let sample = HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            quantity: quantity,
            start: sampleDate,
            end: sampleDate.addingTimeInterval(60) // 1분 duration
        )
        heartRateSamples.append(sample)
    }
    
    sampleData.heartRates = heartRateSamples
    
    // 가상의 스텝 데이터 추가
    let stepsUnit = HKUnit.count()
    let totalSteps = 12500
    let stepsQuantity = HKQuantity(unit: stepsUnit, doubleValue: Double(totalSteps))
    let stepsample = HKQuantitySample(
        type: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        quantity: stepsQuantity,
        start: startDate,
        end: sampleWorkout.endDate
    )
    sampleData.steps = [stepsample]
    
    return RecentShellDetailScreen(workoutData: sampleData)
        .background(Color.turtleRunTheme.backgroundColor)
}
