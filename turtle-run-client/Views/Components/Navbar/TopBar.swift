import SwiftUI

struct TopBar: View {
    let title: String
    let leftButton: TopBarButton?
    let rightButton: TopBarButton?
    
    enum TopBarButton {
        case back(() -> Void)
        case logo
        case profile(() -> Void)
    }
    
    init(title: String, leftButton: TopBarButton? = nil, rightButton: TopBarButton? = nil) {
        self.title = title
        self.leftButton = leftButton
        self.rightButton = rightButton
    }
    
    var body: some View {
        VStack  {
            Spacer()
            HStack {
                // 왼쪽 버튼
                if let leftButton = leftButton {
                    leftButtonView(leftButton)
                } else {
                    Spacer()
                        .frame(width: 30)
                }
                
                Spacer()
                
                // 제목
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
                
                // 오른쪽 버튼
                if let rightButton = rightButton {
                    rightButtonView(rightButton)
                } else {
                    Spacer()
                        .frame(width: 30)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
        }
        .frame(height: 100)
        .background(
            Color.turtleRunTheme.mainColor.opacity(0.95)
            .background(.ultraThinMaterial)
        )
    }
    
    @ViewBuilder
    private func leftButtonView(_ button: TopBarButton) -> some View {
        switch button {
        case .back(let action):
            Button(action: action) {
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color.white.opacity(0.1))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "chevron.left")
                            .foregroundColor(.turtleRunTheme.textColor)
                            .font(.system(size: 16))
                    )
            }
        case .logo:
            logoView()
        case .profile(let action):
            Button(action: action) {
                profileView()
            }
        }
    }
    
    @ViewBuilder
    private func rightButtonView(_ button: TopBarButton) -> some View {
        switch button {
        case .back(let action):
            Button(action: action) {
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color.white.opacity(0.1))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "chevron.left")
                            .foregroundColor(.turtleRunTheme.textColor)
                            .font(.system(size: 16))
                    )
            }
        case .logo:
            logoView()
        case .profile(let action):
            Button(action: action) {
                profileView()
            }
        }
    }
    
    private func logoView() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .frame(width: 30, height: 30)
            .foregroundColor(.turtleRunTheme.accentColor)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.turtleRunTheme.backgroundColor)
                    .clipShape(HexagonShape())
            )
    }
    
    private func profileView() -> some View {
        Circle()
            .frame(width: 30, height: 30)
            .foregroundColor(.turtleRunTheme.accentColor)
    }
}

#Preview {
    VStack(spacing: 20) {
        TopBar(
            title: "Shell 현황",
            leftButton: .back {},
            rightButton: .logo
        )
        
        TopBar(
            title: "TurtleRun",
            leftButton: .logo,
            rightButton: .profile {}
        )
        
        TopBar(title: "제목만")
    }
    .background(Color.black)
} 
