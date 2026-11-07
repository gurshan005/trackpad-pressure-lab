import SwiftUI

@main
struct TremorCheckMVPApp: App {
    @StateObject private var vm = AssessmentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .frame(minWidth: 560, minHeight: 520)
        }
    }
}
