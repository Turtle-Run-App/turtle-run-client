import SwiftUI

struct RadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .stroke(Color.turtleRunTheme.accentColor, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.turtleRunTheme.accentColor : Color.clear)
                            .frame(width: 12, height: 12)
                    )
                
                Text(title)
                    .foregroundColor(Color.turtleRunTheme.textColor)
                    .font(.system(size: 16))
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        RadioButton(title: "남성", isSelected: true) { }
        RadioButton(title: "여성", isSelected: false) { }
    }
    .padding()
    .background(Color.black)
} 
