import SwiftUI

struct ShellMap: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var gridOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 지도 배경 그라데이션
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.1),
                        Color(red: 0.16, green: 0.23, blue: 0.16),
                        Color(red: 0.1, green: 0.16, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 애니메이션 그리드 패턴
                animatedGridPattern(in: geometry.size)
                // 내 위치 표시
                myLocationIndicator()
                // 내 위치 버튼
                myLocationButton()
            }
        }
        .clipped()
        .onAppear {
            startAnimations()
        }
    }
    
    // 애니메이션 그리드 패턴
    private func animatedGridPattern(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<Int(size.width/30) + 2, id: \.self) { i in
                ForEach(0..<Int(size.height/30) + 2, id: \.self) { j in
                    Circle()
                        .fill(Color.turtleRunTheme.accentColor.opacity(0.03))
                        .frame(width: 2, height: 2)
                        .position(
                            x: CGFloat(i) * 30 + gridOffset,
                            y: CGFloat(j) * 30 + gridOffset
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                gridOffset = 30
            }
        }
    }
    

    
    // 내 위치 표시 (중앙)
    private func myLocationIndicator() -> some View {
        Circle()
            .fill(Color.turtleRunTheme.accentColor)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .overlay(
                Circle()
                    .stroke(Color.turtleRunTheme.accentColor.opacity(0.3), lineWidth: 4)
                    .scaleEffect(pulseScale)
            )
            .shadow(color: Color.turtleRunTheme.accentColor.opacity(0.5), radius: 8, x: 0, y: 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseScale = 2.0
                }
            }
    }
    
    // 내 위치 버튼 (우하단)
    private func myLocationButton() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // 내 위치로 이동하는 액션 (현재는 시각적 효과만)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pulseScale = 3.0
                    }
                    withAnimation(.easeInOut(duration: 0.2).delay(0.2)) {
                        pulseScale = 1.0
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.turtleRunTheme.mainColor.opacity(0.9))
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 50, height: 50)
                        
                        Text("📍")
                            .font(.system(size: 20))
                    }
                }
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                .padding(.bottom, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            gridOffset = 2
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 2.0
        }
    }
}

#Preview {
    ShellMap()
        .background(Color.black)
} 
