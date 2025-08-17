import SwiftUI

struct MessageContainer: View {
    let title: String
    let message: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.turtleRunTheme.accentColor)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(height: 80)
        .opacity(isActive ? 1 : 0)
        .offset(y: isActive ? 0 : 20)
        .animation(.easeInOut(duration: 0.5), value: isActive)
    }
}

#Preview {
    MessageContainer(
        title: "러닝 데이터 분석 중...",
        message: "당신의 러닝 기록을 분석하고 있어요",
        isActive: true
    )
    .background(Color.black)
} 
