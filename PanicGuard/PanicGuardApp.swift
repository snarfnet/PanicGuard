import SwiftUI

@main
struct PanicGuardApp: App {
    @StateObject private var emergencyManager = EmergencyManager()
    @StateObject private var adMobManager = AdMobManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(emergencyManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    adMobManager.configure()
                }
        }
    }
}
