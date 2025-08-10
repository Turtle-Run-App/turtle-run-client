import SwiftUI

struct ProfileMenuScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showComingSoonModal = false
    @State private var showSPRankingScreen = false
    @State private var showRunningStatsScreen = false
    @State private var showShellStuatsScreen = false
    @State private var animatedSPValue = 0

    // 프로필 데이터 (추후 ViewModel로 분리 가능)
    private let userName = "터틀러너"
    private let activeDays = 32
    private let species = ProfileHeaderCard.TurtleSpecies.greek
    private let targetSPValue = 2847

    var body: some View {
        ZStack {



            VStack(spacing: 0) {
                // 상단 네비게이션 바
                TopBar(
                    title: "내 프로필",
                    leftButton: .back {
                        dismiss()
                    },
                    rightButton: .logo
                )
                .zIndex(100)

                // 스크롤 가능한 콘텐츠
                ScrollView {
                    VStack(spacing: 20) {
                        // 프로필 헤더
                        ProfileHeaderCard(
                            userName: userName,
                            activeDays: activeDays,
                            species: species
                        )

                        // 메뉴 그리드
                        menuGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }

            // 준비중 알림 모달
            if showComingSoonModal {
                NotificationModal(
                    isPresented: $showComingSoonModal,
                    icon: "🚧",
                    title: "서비스 준비 중",
                    message: "업적 시스템은 현재 개발 중입니다.\n곧 멋진 배지들을 만나보실 수 있어요!",
                    buttonText: "확인"
                )
                .zIndex(200)
            }
        }
        .background(Color.turtleRunTheme.backgroundColor)
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            startSPAnimation()
        }
        .fullScreenCover(isPresented: $showSPRankingScreen) {
            SpInfoScreen()
        }
        .fullScreenCover(isPresented: $showRunningStatsScreen) {
            RunningStatsScreen()
        }
        .fullScreenCover(isPresented: $showShellStuatsScreen) {
            PersonalShellStatusScreen()
        }
    }

    private var menuGrid: some View {
        VStack(spacing: 16) {
            // 첫 번째 행
            HStack(spacing: 16) {
                // SP & 랭킹
                ProfileMenuCard(
                    icon: "🏆",
                    title: "SP & 랭킹",
                    subtitle: "",
                    specialStyle: .spInfo(
                        spValue: animatedSPValue.formatted(),
                        rank: "전체 #142위",
                        rankBadge: "주니어"
                    ),
                    action: {
                        showSPRankingScreen = true
                    }
                )

                // 러닝 통계
                ProfileMenuCard(
                    icon: "📊",
                    title: "러닝 통계",
                    subtitle: "총 거리, 시간\n평균 페이스",
                    action: {
                        showRunningStatsScreen = true
                    }
                )
            }

            // 두 번째 행
            HStack(spacing: 16) {
                // Shell 현황
                ProfileMenuCard(
                    icon: "🗺️",
                    title: "Shell 현황",
                    subtitle: "점령한 영토\n총 면적 정보",
                    action: {
                        showShellStuatsScreen = true
                    }
                )

                // 업적 & 배지 (비활성화)
                ProfileMenuCard(
                    icon: "🏅",
                    title: "업적 & 배지",
                    subtitle: "획득한 업적\n진행 중인 도전",
                    isDisabled: true,
                    isComingSoon: true,
                    specialStyle: .achievements,
                    action: {}
                )
            }

            // 전체 너비 카드들
            VStack(spacing: 16) {
                // 기본 정보
                ProfileMenuCard(
                    icon: "👤",
                    title: "기본 정보",
                    subtitle: "프로필 설정 • 가입 정보 • 계정 관리",
                    isFullWidth: true,
                    action: {
                        print("Navigate to 기본 정보")
                        // TODO: 기본 정보 페이지로 이동
                    }
                )

                // 종족 관리
                ProfileMenuCard(
                    icon: "🐢",
                    title: "종족 관리",
                    subtitle: "종족 변경 • 버프 현황 • 특성 정보",
                    isFullWidth: true,
                    action: {
                        print("Navigate to 종족 관리")
                        // TODO: 종족 관리 페이지로 이동
                    }
                )
            }
        }
    }

    private func startSPAnimation() {
        let increment = targetSPValue / 30
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if animatedSPValue >= targetSPValue {
                animatedSPValue = targetSPValue
                timer.invalidate()
            } else {
                animatedSPValue += increment
            }
        }
        timer.fire()
    }
}

#Preview {
    ProfileMenuScreen()
} 
