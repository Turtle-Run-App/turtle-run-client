import SwiftUI

struct DataSyncInfoCard: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    let progress: Double
    let buttonTitle: String?
    let onButtonTap: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        description: String,
        status: String,
        progress: Double = 0,
        buttonTitle: String? = nil,
        onButtonTap: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.status = status
        self.progress = progress
        self.buttonTitle = buttonTitle
        self.onButtonTap = onButtonTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack(spacing: 15) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.turtleRunTheme.accentColor)
                        .frame(width: 40, height: 40)
                    
                    Text(icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.turtleRunTheme.textColor)
            }
            
            // Description
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
                .lineSpacing(4)
            
            // Button (if provided)
            if let buttonTitle = buttonTitle {
                Button(action: { onButtonTap?() }) {
                    HStack {
                        Text(buttonTitle)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.turtleRunTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            
            // Status
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
            
            // Progress Bar
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.turtleRunTheme.mainColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.turtleRunTheme.accentColor, lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        DataSyncInfoCard(
            icon: "⌚",
            title: "애플워치 연동",
            description: "애플워치의 피트니스 데이터를 연동하여 러닝 활동을 자동으로 기록합니다.",
            status: "연동 중...",
            progress: 1.0
        )
        
        DataSyncInfoCard(
            icon: "📊",
            title: "러닝 데이터 동기화",
            description: "기존 러닝 세션 데이터를 동기화하여 Shell을 생성합니다. 최대 30일치의 데이터를 가져올 수 있습니다.",
            status: "동기화 대기 중",
            progress: 0,
            buttonTitle: "데이터 동기화하기"
        ) {
            print("Sync tapped")
        }
    }
    .padding()
    .background(Color.black)
} 
