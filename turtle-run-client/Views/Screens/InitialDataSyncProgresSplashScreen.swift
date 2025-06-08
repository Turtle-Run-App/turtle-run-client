import SwiftUI

struct InitialDataSyncProgresSplashScreen: View {
    @State private var currentMessageIndex = 0
    @State private var progress: Double = 0
    @State private var isActive = true
    
    private let messages = [
        (title: "러닝 기록 살펴보는 중...", message: "당신이 뛰어온 길을 하나씩 살펴보고 있어요"),
        (title: "Shell 만들기 시작!", message: "당신이 뛰어온 길이 Shell로 변해가요"),
        (title: "당신에게 맞는 종족을 찾는 중...", message: "Shell 특성에 맞는 최적의 종족을 찾고 있어요"),
        (title: "Shell 키우기 준비 중...", message: "앞으로 뛸 때마다 Shell이 조금씩 커질 거예요"),
        (title: "거의 다 왔어요!", message: "곧 TurtleRun의 재미있는 세계로 들어갈 수 있어요")
    ]
    
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
                    title: messages[currentMessageIndex].title,
                    message: messages[currentMessageIndex].message,
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
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .frame(width: 200)
            }
        }
        .onAppear {
            startProgressAnimation()
        }
    }
    
    private func startProgressAnimation() {
        // Progress bar animation
        withAnimation(.linear(duration: 18)) {
            progress = 1.0
        }
        
        // Message updates
        for index in 0..<messages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 3) {
                withAnimation {
                    isActive = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentMessageIndex = index
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
        
        // Navigate to next screen after completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 18) {
            // TODO: Navigate to next screen
            print("Navigation to next screen")
        }
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
    InitialDataSyncProgresSplashScreen()
}
