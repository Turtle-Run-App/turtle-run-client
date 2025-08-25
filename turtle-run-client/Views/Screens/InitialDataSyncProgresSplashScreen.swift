import SwiftUI

struct InitialDataSyncProgresSplashScreen: View {
    @StateObject private var workoutService = WorkoutDataService()
    @State private var currentMessageIndex = 0
    @State private var isActive = true
    
    let onSyncComplete: () -> Void
    
    // 실제 동기화 상태에 따른 메시지 계산
    private var currentMessage: (title: String, message: String) {
        if workoutService.isThreeMonthSyncInProgress {
            if workoutService.threeMonthSyncProgress < 0.2 {
                return (title: "HealthKit 권한 확인 중...", message: "앱에서 건강 데이터에 접근할 수 있도록 권한을 확인하고 있어요")
            } else if workoutService.threeMonthSyncProgress < 0.4 {
                return (title: "3개월 러닝 기록 찾는 중...", message: "최근 3개월간의 모든 러닝 기록을 찾고 있어요")
            } else if workoutService.threeMonthSyncProgress < 0.8 {
                return (title: "워크아웃 데이터 수집 중...", message: "각 워크아웃의 상세한 데이터를 수집하고 있어요")
            } else {
                return (title: "서버에 동기화 중...", message: "수집한 데이터를 서버에 안전하게 저장하고 있어요")
            }
        } else if workoutService.threeMonthSyncProgress >= 1.0 {
            return (title: "동기화 완료!", message: "모든 러닝 데이터가 성공적으로 동기화되었어요")
        } else {
            return (title: "동기화 준비 중...", message: "3개월간의 러닝 데이터 동기화를 시작합니다")
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.turtleRunTheme.backgroundColor,
                    Color.turtleRunTheme.mainColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 30) {
                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.turtleRunTheme.accentColor)
                        .frame(width: 120, height: 120)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.turtleRunTheme.backgroundColor)
                        .frame(width: 80, height: 80)
                        .clipShape(
                            Polygon(sides: 6)
                                .rotation(.degrees(30))
                        )
                }
                
                // Loading Indicator
                LoadingIndicator()
                
                // Message Container
                MessageContainer(
                    title: currentMessage.title,
                    message: currentMessage.message,
                    isActive: isActive
                )
                
                // Progress Bar
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.turtleRunTheme.accentColor.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.turtleRunTheme.accentColor)
                                .frame(width: geometry.size.width * workoutService.threeMonthSyncProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .frame(width: 200)
            }
        }
        .onAppear {
            startThreeMonthSync()
        }
        .onChange(of: workoutService.threeMonthSyncProgress) { progress in
            if progress >= 1.0 && !workoutService.isThreeMonthSyncInProgress {
                // 동기화 완료 후 2초 대기 후 콜백 호출
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    onSyncComplete()
                }
            }
        }
    }
    
    private func startThreeMonthSync() {
        // 실제 3개월 HealthKit 데이터 동기화 시작
        workoutService.syncThreeMonthWorkoutData()
    }
}

// Hexagon shape for logo
struct Polygon: Shape {
    let sides: Int
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2
        let angle = 2 * .pi / Double(sides)
        
        var path = Path()
        let startPoint = CGPoint(
            x: center.x + radius * cos(0),
            y: center.y + radius * sin(0)
        )
        path.move(to: startPoint)
        
        for side in 1...sides {
            let point = CGPoint(
                x: center.x + radius * cos(Double(side) * angle),
                y: center.y + radius * sin(Double(side) * angle)
            )
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    InitialDataSyncProgresSplashScreen(onSyncComplete: {
        print("Sync completed in preview")
    })
}
