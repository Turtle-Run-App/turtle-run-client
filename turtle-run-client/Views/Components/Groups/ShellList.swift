import SwiftUI

struct ShellList: View {
    let shells = [
        ShellInfo(icon: "🌳", name: "한강공원 Shell #3", location: "반포대교 ~ 동작대교", size: "0.52", date: "3일 전"),
        ShellInfo(icon: "🏢", name: "올림픽공원 Shell #1", location: "몽촌토성역 일대", size: "0.38", date: "1주 전"),
        ShellInfo(icon: "🌉", name: "청계천 Shell #2", location: "광화문 ~ 을지로", size: "0.29", date: "2주 전"),
        ShellInfo(icon: "🏞️", name: "남산공원 Shell #1", location: "N서울타워 일대", size: "0.41", date: "3주 전")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.turtleRunTheme.accentColor.opacity(0.2))
                    .overlay(
                        Text("🏃‍♂️")
                            .font(.system(size: 20))
                    )
                
                Text("최근 점령한 Shell")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Shell 목록
            VStack(spacing: 0) {
                ForEach(shells.indices, id: \.self) { index in
                    ShellItem(shell: shells[index])
                    
                    if index < shells.count - 1 {
                        Divider()
                            .background(Color.turtleRunTheme.textColor.opacity(0.1))
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color.turtleRunTheme.mainColor
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

struct ShellInfo {
    let icon: String
    let name: String
    let location: String
    let size: String
    let date: String
}

struct ShellItem: View {
    let shell: ShellInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 32, height: 32)
                .foregroundColor(.turtleRunTheme.accentColor.opacity(0.2))
                .overlay(
                    Text(shell.icon)
                        .font(.system(size: 16))
                )
            
            // Shell 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(shell.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.turtleRunTheme.textColor)
                
                Text(shell.location)
                    .font(.system(size: 12))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
            }
            
            Spacer()
            
            // 크기 및 날짜
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(shell.size) km²")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.turtleRunTheme.accentColor)
                
                Text(shell.date)
                    .font(.system(size: 11))
                    .foregroundColor(.turtleRunTheme.textSecondaryColor)
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    ShellList()
        .background(Color.turtleRunTheme.backgroundColor)
        .padding()
}
