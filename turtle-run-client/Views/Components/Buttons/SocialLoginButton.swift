import SwiftUI

struct SocialLoginButton: View {
    let title: String
    let action: () -> Void
    
    private let accentColor = Color(red: 0.29, green: 0.62, blue: 0.5)
    private let textColor = Color.white
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor, lineWidth: 1)
                        .fill(Color.clear)
                )
        }
        .buttonStyle(SocialButtonStyle())
    }
}

struct SocialButtonStyle: ButtonStyle {
    let accentColor = Color(red: 0.29, green: 0.62, blue: 0.5)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 12) {
        SocialLoginButton(title: "Apple로 로그인") { }
        SocialLoginButton(title: "Google로 로그인") { }
    }
    .padding()
    .background(Color.black)
} 