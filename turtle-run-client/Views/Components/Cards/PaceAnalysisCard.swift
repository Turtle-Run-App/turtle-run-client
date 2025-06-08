import SwiftUI

struct PaceAnalysisCard: View {
    let paceData = [
        PaceData(distance: "1km 평균", pace: "6:24"),
        PaceData(distance: "5km 평균", pace: "6:32"),
        PaceData(distance: "10km 평균", pace: "6:48"),
        PaceData(distance: "하프마라톤", pace: "7:15")
    ]
    
    struct PaceData {
        let distance: String
        let pace: String
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack(spacing: 12) {
                Text("⚡")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(Color.turtleRunTheme.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("페이스 분석")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
            }
            
            // 페이스 리스트
            VStack(spacing: 0) {
                ForEach(Array(paceData.enumerated()), id: \.offset) { index, pace in
                    PaceItemView(pace: pace)
                    
                    if index < paceData.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color.turtleRunTheme.mainColor.background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

struct PaceItemView: View {
    let pace: PaceAnalysisCard.PaceData
    
    var body: some View {
        HStack {
            Text(pace.distance)
                .font(.system(size: 14))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
            
            Spacer()
            
            Text(pace.pace)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.turtleRunTheme.accentColor)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    PaceAnalysisCard()
        .padding(20)
        .background(Color.turtleRunTheme.backgroundColor)
} 
