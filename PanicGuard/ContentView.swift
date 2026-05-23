import SwiftUI

struct ContentView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var selectedTab: Int

    init() {
        if let tabArg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--tab=") }),
           let num = Int(tabArg.replacingOccurrences(of: "--tab=", with: "")) {
            _selectedTab = State(initialValue: num)
        } else {
            _selectedTab = State(initialValue: 0)
        }
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                PanicView()
                    .tabItem {
                        Image(systemName: "hand.raised.fill")
                        Text(L.tab_panic)
                    }
                    .tag(0)

                FakeCallView()
                    .tabItem {
                        Image(systemName: "phone.arrow.down.left.fill")
                        Text(L.tab_fakecall)
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text(L.tab_settings)
                    }
                    .tag(2)
            }
            .tint(PGTheme.danger)

            // Fake call overlay
            if em.fakeCallActive {
                FakeCallScreenView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onAppear {
            em.requestLocationPermission()
            if em.shakeToActivate {
                em.startShakeDetection()
            }
        }
    }
}
