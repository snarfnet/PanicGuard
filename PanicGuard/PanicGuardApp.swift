import SwiftUI
import AppTrackingTransparency

@main
struct PanicGuardApp: App {
    @StateObject private var emergencyManager = EmergencyManager()
    @StateObject private var adMobManager = AdMobManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(emergencyManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    adMobManager.configure()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && !attRequested {
                        attRequested = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            ATTrackingManager.requestTrackingAuthorization { _ in }
                        }
                    }
                }
        }
    }
}
