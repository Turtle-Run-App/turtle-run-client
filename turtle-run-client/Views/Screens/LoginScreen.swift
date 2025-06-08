import SwiftUI

struct LoginScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            Color.turtleRunTheme.backgroundColor
                .ignoresSafeArea()
            
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else {
                LoginScreen()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Show splash for 2 seconds then fade to login
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func LoginScreen() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo
            TurtleRunLogo(size: 96)
            
            // Login Form
            VStack(spacing: 16) {
                TextInputField(text: $email, placeholder: "이메일")
                TextInputField(text: $password, placeholder: "비밀번호", isSecure: true)
                
                Button(action: handleLogin) {
                    Text("로그인")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.turtleRunTheme.textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.turtleRunTheme.accentColor)
                        .cornerRadius(8)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 40)
            
            // Social Login
            VStack(spacing: 12) {
                SocialLoginButton(title: "Apple로 로그인", action: handleAppleLogin)
                SocialLoginButton(title: "Google로 로그인", action: handleGoogleLogin)
            }
            .padding(.horizontal, 40)
            
            // Additional Options
            HStack(spacing: 32) {
                Button("비밀번호 찾기", action: handleForgotPassword)
                    .foregroundColor(Color.turtleRunTheme.accentColor)
                    .font(.system(size: 14))
                    .buttonStyle(TextButtonStyle())
                
                Button("회원가입", action: handleSignUp)
                    .foregroundColor(Color.turtleRunTheme.accentColor)
                    .font(.system(size: 14))
                    .buttonStyle(TextButtonStyle())
            }
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    private func handleLogin() {
        print("Login tapped with email: \(email)")
        // Implement login logic
    }
    
    private func handleAppleLogin() {
        print("Apple login tapped")
        // Implement Apple login
    }
    
    private func handleGoogleLogin() {
        print("Google login tapped")
        // Implement Google login
    }
    
    private func handleForgotPassword() {
        print("Forgot password tapped")
        // Navigate to forgot password screen
    }
    
    private func handleSignUp() {
        print("Sign up tapped")
        // Navigate to sign up screen
    }
}

#Preview {
    LoginScreen()
} 
