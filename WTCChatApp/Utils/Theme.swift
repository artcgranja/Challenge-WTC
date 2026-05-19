import SwiftUI

enum Theme {
    // MARK: - Brand Colors

    static let primary = Color(red: 0.29, green: 0.33, blue: 0.85)       // Indigo 600
    static let primaryLight = Color(red: 0.45, green: 0.48, blue: 0.95)  // Indigo 400
    static let primaryDark = Color(red: 0.20, green: 0.22, blue: 0.65)   // Indigo 800
    static let accent = Color(red: 0.06, green: 0.80, blue: 0.72)        // Teal 500
    static let accentLight = Color(red: 0.15, green: 0.90, blue: 0.82)   // Teal 400

    static let campaignOrange = Color(red: 0.96, green: 0.52, blue: 0.13) // Amber 600
    static let campaignRed = Color(red: 0.87, green: 0.27, blue: 0.27)    // Red 500
    static let success = Color(red: 0.13, green: 0.72, blue: 0.42)        // Emerald 500
    static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)        // Amber 500
    static let danger = Color(red: 0.87, green: 0.27, blue: 0.27)         // Red 500

    // MARK: - Surfaces

    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let screenBackground = Color(UIColor.systemGroupedBackground)

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [primary, primaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.18, blue: 0.55),
            Color(red: 0.29, green: 0.33, blue: 0.85),
            Color(red: 0.06, green: 0.80, blue: 0.72)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let campaignGradient = LinearGradient(
        colors: [campaignOrange, campaignRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surfaceGradient = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadows

    static func cardShadow() -> some ViewModifier { CardShadow() }
    static func elevatedShadow() -> some ViewModifier { ElevatedShadow() }

    // MARK: - Spacing

    static let cornerSM: CGFloat = 10
    static let cornerMD: CGFloat = 14
    static let cornerLG: CGFloat = 20
    static let cornerXL: CGFloat = 28

    // MARK: - Icon Sizes

    static let avatarSM: CGFloat = 44
    static let avatarMD: CGFloat = 56
    static let avatarLG: CGFloat = 100
}

// MARK: - Shadow Modifiers

struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct ElevatedShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Glassmorphism

struct GlassBackground: ViewModifier {
    var opacity: Double = 0.15
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(opacity))
    }
}

extension View {
    func glass(opacity: Double = 0.15) -> some View {
        modifier(GlassBackground(opacity: opacity))
    }
}
