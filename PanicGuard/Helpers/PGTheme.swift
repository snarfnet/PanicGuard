import SwiftUI

enum PGTheme {
    static let ink = Color(red: 0.09, green: 0.08, blue: 0.09)
    static let danger = Color(red: 1.0, green: 0.23, blue: 0.45)
    static let pink = Color(red: 1.0, green: 0.38, blue: 0.58)
    static let blush = Color(red: 1.0, green: 0.92, blue: 0.95)
    static let amber = Color(red: 1.0, green: 0.62, blue: 0.08)
    static let mint = Color(red: 0.25, green: 0.72, blue: 0.68)
    static let lavender = Color(red: 0.47, green: 0.42, blue: 0.78)
    static let panel = Color.white
    static let panelHot = Color(red: 1.0, green: 0.88, blue: 0.93)
    static let steel = Color(red: 0.55, green: 0.52, blue: 0.56)

    static var background: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 1.0, green: 0.94, blue: 0.97),
                Color(red: 1.0, green: 0.90, blue: 0.94)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
