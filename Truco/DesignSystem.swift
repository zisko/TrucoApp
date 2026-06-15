import SwiftUI
import TrucoKit

// MARK: - Color utilities

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Theme

/// Centralized look-and-feel for the redesigned game. Keeping colors, gradients
/// and reusable component styles in one place keeps the screens cohesive.
enum Theme {
    // Core palette
    static let feltTop = Color(hex: 0x1B6B4C)
    static let feltBottom = Color(hex: 0x0C3A29)
    static let gold = Color(hex: 0xE7C24A)
    static let goldDim = Color(hex: 0xB9952F)
    static let cream = Color(hex: 0xF4ECD6)
    static let danger = Color(hex: 0xD3473C)
    static let positive = Color(hex: 0x3FA66A)

    /// The table background used behind the whole game screen.
    static var tableBackground: some View {
        RadialGradient(
            colors: [feltTop, feltBottom],
            center: .center,
            startRadius: 40,
            endRadius: 600
        )
        .overlay(
            // Subtle vignette for depth.
            RadialGradient(
                colors: [.clear, .black.opacity(0.35)],
                center: .center,
                startRadius: 220,
                endRadius: 640
            )
        )
        .ignoresSafeArea()
    }

    /// Accent color for a given suit, used on labels/badges.
    static func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .oros: return Color(hex: 0xD9A520)
        case .copas: return Color(hex: 0xC2453B)
        case .espadas: return Color(hex: 0x2F6BB0)
        case .bastos: return Color(hex: 0x3C8C4D)
        }
    }
}

// MARK: - Reusable surfaces

/// A frosted panel used for overlays, summaries and the hint bar.
struct GlassPanel: ViewModifier {
    var cornerRadius: CGFloat = 20
    var accent: Color = Theme.gold

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(accent.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 20, accent: Color = Theme.gold) -> some View {
        modifier(GlassPanel(cornerRadius: cornerRadius, accent: accent))
    }
}

// MARK: - Button styles

struct PrimaryActionButtonStyle: ButtonStyle {
    var tint: Color = Theme.gold
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(hex: 0x1A1206))
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [tint, tint.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                )
            )
            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: tint.opacity(0.5), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    var tint: Color = Theme.cream
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().stroke(tint.opacity(0.5), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Player naming

enum PlayerNaming {
    /// Display label for a player, relative to the local player. The engine's
    /// model keeps generic names so multiplayer stays correct; this is a
    /// presentation-only mapping.
    static func displayName(for id: UUID?, localPlayerId: UUID) -> String {
        guard let id else { return "—" }
        return id == localPlayerId ? "You" : "Opponent"
    }
}
