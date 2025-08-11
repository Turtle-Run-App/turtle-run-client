import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutDataService: WorkoutDataService
    
    var body: some View {
        MainShellDashboardScreen()
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutDataService())
}
