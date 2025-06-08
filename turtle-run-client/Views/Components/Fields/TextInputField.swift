import SwiftUI

struct TextInputField: View {
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    
    // Color palette
    private let mainColor = Color(red: 0.1, green: 0.23, blue: 0.18)      // #1a3a2f
    private let accentColor = Color(red: 0.29, green: 0.62, blue: 0.5)     // #4a9d7f
    private let textColor = Color.white
    private let placeholderColor = Color(red: 0.7, green: 0.7, blue: 0.7)  // #b3b3b3
    
    init(text: Binding<String>, placeholder: String, isSecure: Bool = false) {
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(placeholderColor)
                    }
            } else {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(placeholderColor)
                    }
            }
        }
        .font(.system(size: 16))
        .foregroundColor(textColor)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(mainColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor, lineWidth: 1)
                )
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
}

// View extension to support placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TextInputField(text: .constant(""), placeholder: "이메일")
        TextInputField(text: .constant(""), placeholder: "비밀번호", isSecure: true)
        TextInputField(text: .constant("test@example.com"), placeholder: "이메일")
    }
    .padding()
    .background(Color.black)
} 
