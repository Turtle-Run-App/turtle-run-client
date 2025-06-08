import SwiftUI

struct SpHistoryList: View {
    let historyItems: [SPHistoryItem]
    
    struct SPHistoryItem {
        let date: String
        let change: Int
        
        var isPositive: Bool {
            return change >= 0
        }
        
        var changeText: String {
            return change >= 0 ? "+\(change) SP" : "\(change) SP"
        }
        
        var changeColor: Color {
            return change >= 0 ? .green : .red
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack(spacing: 8) {
                Text("📊")
                    .font(.system(size: 16))
                
                Text("최근 SP 변화")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
            }
            
            // 히스토리 리스트
            VStack(spacing: 0) {
                ForEach(Array(historyItems.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item.date)
                            .font(.system(size: 14))
                            .foregroundColor(.turtleRunTheme.textSecondaryColor)
                        
                        Spacer()
                        
                        Text(item.changeText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(item.changeColor)
                    }
                    .padding(.vertical, 12)
                    
                    if index < historyItems.count - 1 {
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

#Preview {
    SpHistoryList(
        historyItems: [
            SpHistoryList.SPHistoryItem(date: "2024.12.29", change: 89),
            SpHistoryList.SPHistoryItem(date: "2024.12.28", change: 45),
            SpHistoryList.SPHistoryItem(date: "2024.12.27", change: 67),
            SpHistoryList.SPHistoryItem(date: "2024.12.26", change: 52),
            SpHistoryList.SPHistoryItem(date: "2024.12.25", change: -12)
        ]
    )
    .padding(20)
    .background(Color.turtleRunTheme.backgroundColor)
} 
