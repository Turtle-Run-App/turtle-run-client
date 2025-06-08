import SwiftUI
import PhotosUI

struct SignupScreen: View {
    @State private var selectedImage: UIImage?
    @State private var nickname = ""
    @State private var selectedGender: Gender = .none
    @State private var birthdate = Date()
    @State private var height = ""
    @State private var weight = ""
    
    enum Gender {
        case male, female, none
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.turtleRunTheme.backgroundColor
                .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("프로필 설정")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.turtleRunTheme.textColor)
                        
                        Text("러닝을 시작하기 전, 프로필을 설정해주세요")
                            .font(.system(size: 16))
                            .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
                    }
                    .padding(.top, 20)
                    
                    // Profile Image
                    ProfileImageUploader(selectedImage: $selectedImage)
                        .padding(.vertical, 20)
                    
                    // Form
                    VStack(alignment: .leading, spacing: 24) {
                        // Nickname
                        VStack(alignment: .leading, spacing: 8) {
                            Text("닉네임")
                                .foregroundColor(Color.turtleRunTheme.textColor)
                                .font(.system(size: 16))
                            
                            TextInputField(text: $nickname, placeholder: "닉네임을 입력해주세요")
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 8) {
                            Text("성별")
                                .foregroundColor(Color.turtleRunTheme.textColor)
                                .font(.system(size: 16))
                            
                            HStack(spacing: 20) {
                                RadioButton(
                                    title: "남성",
                                    isSelected: selectedGender == .male
                                ) {
                                    selectedGender = .male
                                }
                                
                                RadioButton(
                                    title: "여성",
                                    isSelected: selectedGender == .female
                                ) {
                                    selectedGender = .female
                                }
                            }
                        }
                        
                        // Birthdate
                        VStack(alignment: .leading, spacing: 8) {
                            Text("생년월일")
                                .foregroundColor(Color.turtleRunTheme.textColor)
                                .font(.system(size: 16))
                            
                            DatePicker("", selection: $birthdate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(Color.turtleRunTheme.accentColor)
                                .colorScheme(.dark)
                        }
                        
                        // Height
                        VStack(alignment: .leading, spacing: 8) {
                            Text("키 (cm)")
                                .foregroundColor(Color.turtleRunTheme.textColor)
                                .font(.system(size: 16))
                            
                            TextInputField(text: $height, placeholder: "선택사항")
                                .keyboardType(.numberPad)
                        }
                        
                        // Weight
                        VStack(alignment: .leading, spacing: 8) {
                            Text("몸무게 (kg)")
                                .foregroundColor(Color.turtleRunTheme.textColor)
                                .font(.system(size: 16))
                            
                            TextInputField(text: $weight, placeholder: "선택사항")
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Submit Button
                    Button(action: handleSubmit) {
                        Text("다음")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.turtleRunTheme.textColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.turtleRunTheme.accentColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleSubmit() {
        // TODO: Implement profile setup submission
        print("Profile setup submitted")
    }
}

#Preview {
    SignupScreen()
}
