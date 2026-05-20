import SwiftUI
import GoogleMobileAds

class AdMobManager: ObservableObject {
    static let shared = AdMobManager()

    let bannerAdUnitID = "ca-app-pub-9404799280370656/2671534010"

    func configure() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootVC
        }
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
