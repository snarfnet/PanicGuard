import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var newContactName = ""
    @State private var newContactPhone = ""

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(localized: "settings_title"))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 16)

                    // Emergency Contacts
                    settingsSection(title: String(localized: "settings_contacts"), icon: "person.2.fill") {
                        ForEach(em.contacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(contact.phone)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                Button {
                                    em.contacts.removeAll { $0.id == contact.id }
                                    em.saveContacts()
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Add contact
                        HStack(spacing: 8) {
                            TextField(String(localized: "settings_name"), text: $newContactName)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)

                            TextField(String(localized: "settings_phone"), text: $newContactPhone)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                                .frame(maxWidth: .infinity)

                            Button {
                                guard !newContactName.isEmpty, !newContactPhone.isEmpty else { return }
                                em.contacts.append(EmergencyContact(name: newContactName, phone: newContactPhone))
                                em.saveContacts()
                                newContactName = ""
                                newContactPhone = ""
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    // Shake Detection
                    settingsSection(title: String(localized: "settings_shake"), icon: "iphone.radiowaves.left.and.right") {
                        Toggle(isOn: $em.shakeToActivate) {
                            Text(String(localized: "settings_shake_toggle"))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        .tint(.red)
                        .onChange(of: em.shakeToActivate) { _, val in
                            em.saveSettings()
                            if val {
                                em.startShakeDetection()
                            } else {
                                em.stopShakeDetection()
                            }
                        }

                        Text(String(localized: "settings_shake_desc"))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // Safety Tips
                    settingsSection(title: String(localized: "settings_tips"), icon: "lightbulb.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            tipRow("1", String(localized: "tip_1"))
                            tipRow("2", String(localized: "tip_2"))
                            tipRow("3", String(localized: "tip_3"))
                            tipRow("4", String(localized: "tip_4"))
                            tipRow("5", String(localized: "tip_5"))
                        }
                    }

                    // Disclaimer
                    Text(String(localized: "disclaimer"))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.top, 8)

                    // Ad
                    BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
                        .frame(height: 50)
                }
                .padding(.horizontal)
            }
        }
    }

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }

    private func tipRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.red)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
