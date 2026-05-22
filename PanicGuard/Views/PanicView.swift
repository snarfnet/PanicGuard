import SwiftUI
import UIKit

struct PanicView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var pulseScale: CGFloat = 1.0
    @State private var buttonRotation: Double = 0

    var body: some View {
        ZStack {
            // Background
            (em.isAlertActive ? Color(red: 0.15, green: 0, blue: 0) : Color(red: 0.05, green: 0.05, blue: 0.08))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerBar
                    .padding(.top, 8)

                Spacer()

                // Status
                if em.isAlertActive {
                    activeStatusView
                } else {
                    inactiveStatusView
                }

                Spacer()

                // PANIC BUTTON
                panicButton
                    .padding(.bottom, 20)

                Spacer()

                // Mode selector
                modeSelector
                    .padding(.bottom, 8)

                // Quick actions
                quickActions
                    .padding(.bottom, 8)

                // Ad banner
                BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
                    .frame(height: 50)
            }

            // Alert flash overlay
            if em.isAlertActive {
                Color.red
                    .opacity(Double.random(in: 0.05...0.15))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .font(.title2)
                .foregroundColor(.red)
            Text("PANIC GUARD")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            if em.isRecording {
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("REC \(formatDuration(em.recordingDuration))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Status Views
    private var activeStatusView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .symbolEffect(.pulse)

            Text(String(localized: "status_active"))
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.red)

            if let loc = em.currentLocation {
                Text("\(loc.coordinate.latitude, specifier: "%.4f"), \(loc.coordinate.longitude, specifier: "%.4f")")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.red.opacity(0.6))
            }
        }
    }

    private var inactiveStatusView: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 36))
                .foregroundColor(.green.opacity(0.6))

            Text(String(localized: "status_ready"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            Text(String(localized: "status_instruction"))
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Panic Button
    private var panicButton: some View {
        ZStack {
            // Pulse rings
            if !em.isAlertActive {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.red.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                        .frame(width: 200 + CGFloat(i) * 40, height: 200 + CGFloat(i) * 40)
                        .scaleEffect(pulseScale)
                }
            }

            // Main button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if em.isAlertActive {
                        em.deactivateAlert()
                    } else {
                        em.activateAlert()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: em.isAlertActive
                                    ? [Color.red, Color(red: 0.5, green: 0, blue: 0)]
                                    : [Color(red: 0.8, green: 0.1, blue: 0.1), Color(red: 0.4, green: 0, blue: 0)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .shadow(color: .red.opacity(0.5), radius: em.isAlertActive ? 30 : 15)

                    VStack(spacing: 4) {
                        Image(systemName: em.isAlertActive ? "hand.raised.slash.fill" : "hand.raised.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)

                        Text(em.isAlertActive ? String(localized: "btn_stop") : String(localized: "btn_panic"))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }

    // MARK: - Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(AlertMode.allCases, id: \.rawValue) { mode in
                Button {
                    em.alertMode = mode
                    em.saveSettings()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 18))
                        Text(mode.label)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(em.alertMode == mode ? .white : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(em.alertMode == mode ? Color.red.opacity(0.3) : Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(em.alertMode == mode ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    @State private var showSOSCopied = false

    // MARK: - Quick Actions
    private var quickActions: some View {
        HStack(spacing: 12) {
            // Emergency SMS
            if em.contacts.isEmpty {
                quickActionButton(icon: "message.fill", label: String(localized: "btn_sos"), color: .gray.opacity(0.3))
            } else {
                Button {
                    if let url = em.getEmergencySMSURL() {
                        UIApplication.shared.open(url)
                    } else {
                        UIPasteboard.general.string = em.getEmergencyMessage()
                        showSOSCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSOSCopied = false }
                    }
                } label: {
                    quickActionButton(
                        icon: showSOSCopied ? "checkmark" : "message.fill",
                        label: showSOSCopied ? String(localized: "btn_sos_copied") : String(localized: "btn_sos"),
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
            }

            // Record
            Button {
                if em.isRecording {
                    em.stopRecording()
                } else {
                    em.startRecording()
                }
            } label: {
                quickActionButton(
                    icon: em.isRecording ? "stop.circle.fill" : "mic.fill",
                    label: em.isRecording ? String(localized: "btn_stop_rec") : String(localized: "btn_record"),
                    color: em.isRecording ? .red : .blue
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private func quickActionButton(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(label)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1))
        .contentShape(Rectangle())
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
