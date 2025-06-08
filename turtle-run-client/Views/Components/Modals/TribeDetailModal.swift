import SwiftUI

struct TribeDetailModal: View {
    let tribe: Tribe
    let isPresented: Binding<Bool>
    let onSelect: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented.wrappedValue = false
                }
            
            // Modal content
            VStack(spacing: 0) {
                // Header
                header
                
                // Buffs section
                buffsSection
                
                // Select button
                selectButton
                
                // Notice
                notice
            }
            .background(Color.turtleRunTheme.mainColor)
            .cornerRadius(20)
            .padding(.horizontal, 30)
            .scaleEffect(isPresented.wrappedValue ? 1 : 0.8)
            .opacity(isPresented.wrappedValue ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented.wrappedValue)
        }
    }
    
    private var header: some View {
        HStack(alignment: .center, spacing: 15) {
            // Tribe icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [tribe.color, tribe.color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Text(tribe.icon)
                    .font(.system(size: 30))
            }
            
            // Tribe info
            VStack(alignment: .leading, spacing: 4) {
                Text(tribe.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.turtleRunTheme.textColor)
                
                Text(tribe.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
            }
            
            Spacer()
            
            // Close button
            Button(action: { isPresented.wrappedValue = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var buffsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🎯 종족 버프")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.turtleRunTheme.accentColor)
            
            VStack(spacing: 8) {
                ForEach(tribe.buffs.indices, id: \.self) { index in
                    let buff = tribe.buffs[index]
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(buff.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.turtleRunTheme.textColor)
                            
                            Spacer()
                            
                            Text(buff.value)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.turtleRunTheme.accentColor)
                        }
                        
                        Text(buff.description)
                            .font(.system(size: 13))
                            .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        Rectangle()
                            .fill(Color.turtleRunTheme.accentColor)
                            .frame(width: 3)
                            .cornerRadius(1.5),
                        alignment: .leading
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var selectButton: some View {
        Button(action: onSelect) {
            Text("이 종족 선택하기")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.turtleRunTheme.accentColor)
                .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private var notice: some View {
        Text("⚠️ 종족 변경은 30일마다 1회만 가능해요")
            .font(.system(size: 12))
            .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
    }
}

#Preview {
    TribeDetailModal(
        tribe: Tribe.allTribes[0],
        isPresented: .constant(true)
    ) {
        print("Selected tribe")
    }
} 
