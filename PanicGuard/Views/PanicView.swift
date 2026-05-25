import SwiftUI
import UIKit

struct PanicView: View {
    @EnvironmentObject var em: EmergencyManager
    @State private var pulseScale: CGFloat = 1
    @State private var showSOSCopied = false

    var body: some View {
        ZStack {
            PGTheme.background.ignoresSafeArea()

            if em.isAlertActive {
                alertScreen
            } else {
                homeScreen
            }
        }
    }

    private var homeScreen: some View {
        VStack(spacing: 0) {
            topBar(title: "ストーカー撃退", icon: "gearshape.fill")
                .padding(.horizontal, 18)
                .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroPanel
                    actionGrid
                    emergencyRow
                    BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
                        .frame(height: 50)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
    }

    private var alertScreen: some View {
        VStack(spacing: 0) {
            topBar(title: "SOSアラーム", icon: "xmark")
                .padding(.horizontal, 18)
                .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ZStack {
                        mangaBurst(color: PGTheme.danger.opacity(0.22))

                        VStack(spacing: 14) {
                            Text("助けて！")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(PGTheme.danger)

                            Text("SOSアラーム作動中")
                                .font(.system(size: 21, weight: .black))
                                .foregroundColor(PGTheme.ink)

                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    em.deactivateAlert()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [PGTheme.pink, PGTheme.danger],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 150, height: 150)
                                        .shadow(color: PGTheme.danger.opacity(0.32), radius: 18, y: 10)

                                    Circle()
                                        .stroke(Color.white.opacity(0.75), lineWidth: 7)
                                        .frame(width: 164, height: 164)

                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 62, weight: .black))
                                        .foregroundColor(.white)
                                        .scaleEffect(pulseScale)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L.btn_stop)

                            Text("タップで停止")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(PGTheme.ink.opacity(0.72))
                        }
                        .padding(.vertical, 36)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)

                    effectCard
                    quickActions

                    BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
                        .frame(height: 50)
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }

    private func topBar(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)

            Spacer()

            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button {
                if em.isAlertActive {
                    em.deactivateAlert()
                }
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(
            LinearGradient(
                colors: [Color(red: 1, green: 0.42, blue: 0.62), PGTheme.danger],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: PGTheme.pink.opacity(0.26), radius: 12, y: 8)
    }

    private var heroPanel: some View {
        ZStack(alignment: .leading) {
            Image("HeroComic")
                .resizable()
                .scaledToFill()
                .frame(height: 174)
                .frame(maxWidth: .infinity)
                .clipped()

            speechBubble
                .padding(.leading, 16)
                .padding(.top, 18)
                .frame(maxWidth: 160, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PGTheme.pink.opacity(0.35), lineWidth: 1))
    }

    private var speechBubble: some View {
        Text("あなたを\n守るために\nいつでも\nサポート！")
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(Color.white)
            .clipShape(SpeechBubbleShape())
            .overlay(SpeechBubbleShape().stroke(.black, lineWidth: 3))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                    em.activateAlert()
                }
            } label: {
                actionTile(icon: "bell.fill", title: "SOSアラーム", color: PGTheme.danger, bg: Color(red: 1, green: 0.90, blue: 0.94))
            }
            .buttonStyle(.plain)

            Button {
                em.isRecording ? em.stopRecording() : em.startRecording()
            } label: {
                actionTile(icon: em.isRecording ? "stop.fill" : "mic.fill", title: em.isRecording ? "録音停止" : "録音・証拠を残す", color: PGTheme.amber, bg: Color(red: 1, green: 0.96, blue: 0.86))
            }
            .buttonStyle(.plain)

            Button {
                sendSOS()
            } label: {
                actionTile(icon: showSOSCopied ? "checkmark.circle.fill" : "location.fill", title: showSOSCopied ? "コピー済み" : "現在地を送信", color: PGTheme.mint, bg: Color(red: 0.89, green: 0.98, blue: 0.97))
            }
            .buttonStyle(.plain)

            Button {
                if em.fakeCallProfile.delaySeconds == 0 {
                    em.fakeCallProfile.delaySeconds = 30
                }
                em.scheduleFakeCall()
            } label: {
                actionTile(icon: "phone.arrow.down.left.fill", title: "偽着信で離脱", color: PGTheme.lavender, bg: Color(red: 0.94, green: 0.93, blue: 1.0))
            }
            .buttonStyle(.plain)
        }
    }

    private func actionTile(icon: String, title: String, color: Color, bg: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .black))
                .foregroundColor(color)
                .frame(height: 48)
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(color)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 126)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
        .shadow(color: color.opacity(0.12), radius: 10, y: 5)
    }

    private var emergencyRow: some View {
        Button {
            em.activateAlert()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 1, green: 0.89, blue: 0.93))
                        .frame(width: 52, height: 52)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 25, weight: .black))
                        .foregroundColor(PGTheme.danger)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("緊急時はすぐにSOS！")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(PGTheme.ink)
                    Text("大きな音と通知で助けを呼びます")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(PGTheme.steel)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(PGTheme.steel.opacity(0.6))
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var effectCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("アラームの効果")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(PGTheme.danger)

            effectRow("大音量のサイレンを鳴らします")
            effectRow("周囲に危険を知らせます")
            effectRow("登録した連絡先にSOSを送れます")
            effectRow("証拠用の録音を残します")
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 8)
        .padding(.horizontal, 18)
    }

    private func effectRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(PGTheme.pink)
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(PGTheme.ink.opacity(0.82))
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button { sendSOS() } label: {
                compactButton(icon: "message.fill", title: showSOSCopied ? "SOSコピー済み" : "SOS送信", color: PGTheme.mint)
            }
            .buttonStyle(.plain)

            Button {
                em.isRecording ? em.stopRecording() : em.startRecording()
            } label: {
                compactButton(icon: em.isRecording ? "stop.fill" : "record.circle", title: em.isRecording ? "録音停止" : "証拠録音", color: PGTheme.amber)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
    }

    private func compactButton(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .black))
            Text(title)
                .font(.system(size: 14, weight: .black))
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.35), lineWidth: 1))
    }

    private func mangaBurst(color: Color) -> some View {
        ZStack {
            ForEach(0..<28, id: \.self) { i in
                Rectangle()
                    .fill(color)
                    .frame(width: 2, height: 220)
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(i) * 360 / 28))
            }
        }
        .frame(height: 330)
        .clipped()
    }

    private func sendSOS() {
        em.requestCurrentLocation { _ in
            DispatchQueue.main.async {
                if let url = em.getEmergencySMSURL() {
                    UIApplication.shared.open(url)
                } else {
                    UIPasteboard.general.string = em.getEmergencyMessage()
                    showSOSCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSOSCopied = false }
                }
            }
        }
    }
}

struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 18, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: rect.maxX - 12, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.midY - 18))
        path.addLine(to: CGPoint(x: rect.maxX - 18, y: rect.midY - 4))
        path.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.maxY - 16))
        path.addLine(to: CGPoint(x: rect.midX + 18, y: rect.maxY - 8))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY + 8))
        path.addLine(to: CGPoint(x: rect.midX - 16, y: rect.maxY - 8))
        path.addLine(to: CGPoint(x: rect.minX + 12, y: rect.maxY - 4))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.midY + 10))
        path.addLine(to: CGPoint(x: rect.minX + 14, y: rect.midY - 8))
        path.closeSubpath()
        return path
    }
}
