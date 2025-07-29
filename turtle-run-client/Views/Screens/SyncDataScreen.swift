import SwiftUI
import HealthKit

struct SyncDataScreen: View {
    @StateObject private var viewModel = RunningViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                if !viewModel.isAuthorized {
                    Button("HealthKit 권한 요청") {
                        viewModel.requestHealthKitAuthorization()
                    }
                } else {
                    Button("동기화") {
                        viewModel.syncLatestWorkoutRoute()
                    }
                    if let status = viewModel.syncStatus {
                        Text(status)
                            .foregroundColor(status.contains("성공") ? .green : .red)
                    }
                }
            }
            .padding()
            .navigationTitle("데이터 동기화")
        }
    }
}

// Preview에서만 사용할 MockViewModel
final class PreviewSyncViewModel: RunningViewModel {
    override init() { super.init() }
    override func requestHealthKitAuthorization() {}
    override func syncLatestWorkoutRoute() {}
}

struct SyncDataScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SyncDataScreenPreview(state: .권한없음)
            SyncDataScreenPreview(state: .에러)
            SyncDataScreenPreview(state: .성공)
            SyncDataScreenPreview(state: .실패)
        }
    }
}

private enum PreviewState { case 권한없음, 에러, 성공, 실패 }

private struct SyncDataScreenPreview: View {
    let state: PreviewState
    var body: some View {
        let vm = PreviewSyncViewModel()
        switch state {
        case .권한없음:
            vm.isAuthorized = false
        case .에러:
            vm.isAuthorized = false
            vm.errorMessage = "HealthKit 권한 요청 중 에러가 발생했습니다."
        case .성공:
            vm.isAuthorized = true
            vm.syncStatus = "동기화 성공"
        case .실패:
            vm.isAuthorized = true
            vm.syncStatus = "동기화 실패: 네트워크 오류"
        }
        return SyncDataScreenForPreview(viewModel: vm)
            .previewDisplayName("\(state)")
    }
}

// Preview 전용 내부 뷰
private struct SyncDataScreenForPreview: View {
    @StateObject var viewModel: PreviewSyncViewModel
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                if !viewModel.isAuthorized {
                    Button("HealthKit 권한 요청") {}
                } else {
                    Button("동기화") {}
                    if let status = viewModel.syncStatus {
                        Text(status)
                            .foregroundColor(status.contains("성공") ? .green : .red)
                    }
                }
            }
            .padding()
            .navigationTitle("데이터 동기화")
        }
    }
} 