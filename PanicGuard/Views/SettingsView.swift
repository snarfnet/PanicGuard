import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var newContactName = ""
    @State private var newContactPhone = ""

    var body: some View {
        ZStack {
            PGTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(PGTheme.pink)
                        Text(L.settings_title)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(PGTheme.ink)
                    }
                    .padding(.top, 16)

                    // Emergency Contacts
                    settingsSection(title: L.settings_contacts, icon: "person.2.fill") {
                        ForEach(em.contacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(PGTheme.ink)
                                    Text(contact.phone)
                                        .font(.system(size: 12))
                                        .foregroundColor(PGTheme.steel)
                                }
                                Spacer()
                                Button {
                                    em.contacts.removeAll { $0.id == contact.id }
                                    em.saveContacts()
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(PGTheme.danger)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Add contact
                        HStack(spacing: 8) {
                            TextField(L.settings_name, text: $newContactName)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)

                            TextField(L.settings_phone, text: $newContactPhone)
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
                                    .foregroundColor(PGTheme.mint)
                            }
                        }
                    }

                    // Shake Detection
                    settingsSection(title: L.settings_shake, icon: "iphone.radiowaves.left.and.right") {
                        Toggle(isOn: $em.shakeToActivate) {
                            Text(L.settings_shake_toggle)
                                .font(.system(size: 14))
                                .foregroundColor(PGTheme.ink)
                        }
                        .tint(PGTheme.pink)
                        .onChange(of: em.shakeToActivate) { _, val in
                            em.saveSettings()
                            if val {
                                em.startShakeDetection()
                            } else {
                                em.stopShakeDetection()
                            }
                        }

                        Text(L.settings_shake_desc)
                            .font(.system(size: 11))
                            .foregroundColor(PGTheme.steel)
                    }

                    // Safety Tips
                    settingsSection(title: L.settings_tips, icon: "lightbulb.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            tipRow("1", L.tip_1)
                            tipRow("2", L.tip_2)
                            tipRow("3", L.tip_3)
                            tipRow("4", L.tip_4)
                            tipRow("5", L.tip_5)
                        }
                    }

                    // Disclaimer
                    Text(L.disclaimer)
                        .font(.system(size: 10))
                        .foregroundColor(PGTheme.steel.opacity(0.72))
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
                    .foregroundColor(PGTheme.pink)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(PGTheme.ink)
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 5)
        }
    }

    private func tipRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(PGTheme.pink)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(PGTheme.ink.opacity(0.72))
        }
    }
}
