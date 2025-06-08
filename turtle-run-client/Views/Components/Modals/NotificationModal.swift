import SwiftUI

struct NotificationModal: View {
    @Binding var isPresented: Bool
    let icon: String
    let title: String
    let message: String
    let buttonText: String
    
    var body: some View {
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // 모달 컨텐츠
            VStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 48))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text(buttonText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.turtleRunTheme.textColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.turtleRunTheme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(30)
            .background(
                Color.turtleRunTheme.mainColor.opacity(0.3)
                    .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 10)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
        }
        .opacity(isPresented ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

#Preview {
    @State var isPresented = true
    
    return NotificationModal(
        isPresented: $isPresented,
        icon: "🚧",
        title: "서비스 준비 중",
        message: "업적 시스템은 현재 개발 중입니다.\n곧 멋진 배지들을 만나보실 수 있어요!",
        buttonText: "확인"
    )
    .background(Color.turtleRunTheme.backgroundColor)
} 
