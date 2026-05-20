import SwiftUI

struct ContentView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                PanicView()
                    .tabItem {
                        Image(systemName: "exclamationmark.shield.fill")
                        Text(String(localized: "tab_panic"))
                    }
                    .tag(0)

                FakeCallView()
                    .tabItem {
                        Image(systemName: "phone.arrow.down.left.fill")
                        Text(String(localized: "tab_fakecall"))
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text(String(localized: "tab_settings"))
                    }
                    .tag(2)
            }
            .tint(.red)

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
