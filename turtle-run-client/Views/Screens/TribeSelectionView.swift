import SwiftUI

struct TribeSelectionView: View {
    @State private var selectedTribe: Tribe?
    @State private var showingDetail = false
    @State private var detailTribe: Tribe?
    
    private let tribes = Tribe.allTribes
    private let recommendedTribe = Tribe.allTribes.first { $0.isRecommended }
    
    var body: some View {
        ZStack {
            // Background
            Color.turtleRunTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                Spacer()
                tribesContainer
                Spacer()
            }
            
            // Detail Modal
            if let detailTribe = detailTribe {
                TribeDetailModal(
                    tribe: detailTribe,
                    isPresented: $showingDetail
                ) {
                    selectTribe(detailTribe)
                }
            }
        }
        .onChange(of: showingDetail) { _, newValue in
            if !newValue {
                detailTribe = nil
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 20) {
            Text("종족을 선택하세요")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.turtleRunTheme.textColor)
            
            Text("러닝 스타일에 맞는 종족을 선택하면 더 많은 버프를 받을 수 있어요")
                .font(.system(size: 17))
                .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            
            if let recommendedTribe = recommendedTribe {
                Text("\(recommendedTribe.name)을 추천드려요!")
                    .font(.system(size: 14))
                    .foregroundColor(Color.turtleRunTheme.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
    
    private var tribesContainer: some View {
        GeometryReader { geometry in
            let containerWidth = min(geometry.size.width - 40, 280)
            let containerHeight: CGFloat = 250
            
            ZStack {
                // Triangle layout positions
                ForEach(tribes, id: \.id) { tribe in
                    let index = tribes.firstIndex(where: { $0.id == tribe.id }) ?? 0
                    let position = trianglePosition(for: index, in: CGSize(width: containerWidth, height: containerHeight))
                    
                    VStack(spacing: 8) {
                        TribeSymbol(
                            tribe: tribe,
                            isSelected: selectedTribe?.id == tribe.id
                        ) {
                            showTribeDetail(tribe)
                        }
                        
                        Text(tribe.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.turtleRunTheme.textColor)
                    }
                    .position(position)
                }
            }
            .frame(width: containerWidth, height: containerHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: 300)
        .padding(.horizontal, 20)
    }
    
    private func trianglePosition(for index: Int, in size: CGSize) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius: CGFloat = 80
        
        switch index {
        case 0: // Red turtle - top
            return CGPoint(x: centerX, y: centerY - radius)
        case 1: // Yellow turtle - bottom left
            return CGPoint(x: centerX - radius * cos(.pi / 6), y: centerY + radius * sin(.pi / 6))
        case 2: // Blue turtle - bottom right
            return CGPoint(x: centerX + radius * cos(.pi / 6), y: centerY + radius * sin(.pi / 6))
        default:
            return CGPoint(x: centerX, y: centerY)
        }
    }
    
    private func showTribeDetail(_ tribe: Tribe) {
        detailTribe = tribe
        showingDetail = true
    }
    
    private func selectTribe(_ tribe: Tribe) {
        selectedTribe = tribe
        showingDetail = false
        
        // TODO: Navigate to next screen or save selection
        print("Selected tribe: \(tribe.name)")
    }
}

#Preview {
    TribeSelectionView()
} 
