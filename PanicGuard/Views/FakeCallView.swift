import SwiftUI

struct FakeCallView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var callerName = ""
    @State private var delaySeconds = 30

    var body: some View {
        ZStack {
            PGTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "phone.arrow.down.left.fill")
                        .font(.title2)
                        .foregroundColor(PGTheme.pink)
                    Text(L.fakecall_title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(PGTheme.ink)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Text(L.fakecall_desc)
                    .font(.system(size: 13))
                    .foregroundColor(PGTheme.steel)
                    .padding(.horizontal)

                // Caller name
                VStack(alignment: .leading, spacing: 6) {
                    Text(L.fakecall_name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(PGTheme.ink.opacity(0.72))

                    TextField(L.fakecall_name_placeholder, text: $callerName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: callerName) { _, val in
                            em.fakeCallProfile.callerName = val
                            em.saveSettings()
                        }
                }
                .padding(.horizontal)

                // Delay
                VStack(alignment: .leading, spacing: 6) {
                    Text(L.fakecall_delay)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(PGTheme.ink.opacity(0.72))

                    HStack(spacing: 12) {
                        ForEach([10, 30, 60, 120], id: \.self) { seconds in
                            Button {
                                delaySeconds = seconds
                                em.fakeCallProfile.delaySeconds = seconds
                                em.saveSettings()
                            } label: {
                                Text(seconds < 60 ? "\(seconds)s" : "\(seconds/60)m")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(delaySeconds == seconds ? .white : PGTheme.pink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(delaySeconds == seconds ? PGTheme.pink : Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(delaySeconds == seconds ? PGTheme.pink : PGTheme.pink.opacity(0.18), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Schedule button
                if em.isFakeCallScheduled {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(PGTheme.pink)
                        Text(L.fakecall_scheduled)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(PGTheme.pink)

                        Button {
                            em.cancelFakeCall()
                        } label: {
                            Text(L.fakecall_cancel)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(PGTheme.danger)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(PGTheme.panelHot)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    Button {
                        em.scheduleFakeCall()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 20))
                            Text(L.fakecall_start)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [PGTheme.pink, PGTheme.danger], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .shadow(color: PGTheme.pink.opacity(0.28), radius: 10)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Test button
                Button {
                    em.fakeCallActive = true
                } label: {
                    Text(L.fakecall_test)
                        .font(.system(size: 12))
                        .foregroundColor(PGTheme.steel)
                }
                .padding(.bottom, 8)

                BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
                    .frame(height: 50)
            }
        }
        .onAppear {
            callerName = em.fakeCallProfile.callerName
            delaySeconds = em.fakeCallProfile.delaySeconds
        }
    }
}

// MARK: - Fake Call Screen
struct FakeCallScreenView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var ringPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Full screen gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.15), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Caller avatar
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringPulse)

                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Caller name
                Text(em.fakeCallProfile.callerName)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)

                Text(L.fakecall_incoming)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                // Answer / Decline
                HStack(spacing: 80) {
                    // Decline
                    Button {
                        em.endFakeCall()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(135))
                            }
                            Text(L.fakecall_decline)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Answer
                    Button {
                        em.endFakeCall()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            Text(L.fakecall_answer)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                ringPulse = 1.15
            }
            // Vibrate
            for i in 0..<6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5) {
                    if em.fakeCallActive {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                    }
                }
            }
        }
    }
}
