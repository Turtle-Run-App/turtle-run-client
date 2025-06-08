import SwiftUI

struct SplashScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            TurtleRunLogo()
                .scaleEffect(1)
                .opacity(1)
                .animation(.easeOut(duration: 0.8), value: true)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.turtleRunTheme.accentColor))
                .scaleEffect(1.2)
        }
    }
}

#Preview {
    SplashScreen()
}
