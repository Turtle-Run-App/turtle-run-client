import SwiftUI

struct PersonalRecordsCard: View {
    let records = [
        PersonalRecord(label: "최장 거리", value: "15.2 km", date: "2024.12.15"),
        PersonalRecord(label: "최고 페이스", value: "5:42 /km", date: "2024.12.22"),
        PersonalRecord(label: "최장 시간", value: "1:32:45", date: "2024.12.15"),
        PersonalRecord(label: "연속 러닝", value: "7일", date: "현재 진행중")
    ]
    
    struct PersonalRecord {
        let label: String
        let value: String
        let date: String
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack(spacing: 12) {
                Text("🏆")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(Color.turtleRunTheme.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("개인 기록")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
            }
            
            // 기록 리스트
            VStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                    RecordItemView(record: record)
                    
                    if index < records.count - 1 {
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

struct RecordItemView: View {
    let record: PersonalRecordsCard.PersonalRecord
    
    var body: some View {
        HStack {
            Text(record.label)
                .font(.system(size: 14))
                .foregroundColor(.turtleRunTheme.textSecondaryColor)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(record.value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.accentColor)
                
                Text(record.date)
                    .font(.system(size: 12))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    PersonalRecordsCard()
        .padding(20)
        .background(Color.turtleRunTheme.backgroundColor)
} 
