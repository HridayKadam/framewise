import SwiftUI

enum DSColor {
    static let background = Color("Background")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let accent = Color.accentColor
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let overlayHighContrast = Color.white.opacity(0.95)
}

enum DSSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum DSTypography {
    static let title = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headline = Font.system(.title2, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
}

extension Animation {
    static var scorePulse: Animation { .easeInOut(duration: 0.8).repeatForever(autoreverses: true) }
    static var overlayFade: Animation { .easeInOut(duration: 0.25) }
    static var quick: Animation { .easeInOut(duration: 0.15) }
}
