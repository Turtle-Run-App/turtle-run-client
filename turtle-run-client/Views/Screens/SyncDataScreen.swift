import SwiftUI
import HealthKit

struct SyncDataScreen: View {
    @StateObject private var workoutDataService = WorkoutDataService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let error = workoutDataService.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                if !workoutDataService.isAuthorized {
                    Button("HealthKit 권한 요청") {
                        workoutDataService.requestHealthKitAuthorization()
                    }
                } else {
                    Button("동기화") {
                        workoutDataService.syncLatestWorkoutRoute()
                    }
                    if let status = workoutDataService.syncStatus {
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

// Preview에서만 사용할 MockService
final class PreviewSyncService: WorkoutDataService {
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
        let service = PreviewSyncService()
        switch state {
        case .권한없음:
            service.isAuthorized = false
        case .에러:
            service.isAuthorized = false
            service.errorMessage = "HealthKit 권한 요청 중 에러가 발생했습니다."
        case .성공:
            service.isAuthorized = true
            service.syncStatus = "동기화 성공"
        case .실패:
            service.isAuthorized = true
            service.syncStatus = "동기화 실패: 네트워크 오류"
        }
        return SyncDataScreenForPreview(workoutDataService: service)
            .previewDisplayName("\(state)")
    }
}

// Preview 전용 내부 뷰
private struct SyncDataScreenForPreview: View {
    @StateObject var workoutDataService: PreviewSyncService
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let error = workoutDataService.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                if !workoutDataService.isAuthorized {
                    Button("HealthKit 권한 요청") {}
                } else {
                    Button("동기화") {}
                    if let status = workoutDataService.syncStatus {
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