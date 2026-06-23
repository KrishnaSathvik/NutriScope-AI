import SwiftUI

// Kinetic Harvest design system — Nutriscope AI
enum AppTheme {
    static let background = Color(hex: 0xFBF9F4)
    static let surface = Color.white
    static let surfaceMuted = Color(hex: 0xF0EEE9)
    static let surfaceContainerHighest = Color(hex: 0xE4E2DD)

    static let coachOrange = Color(hex: 0xF26B38)
    static let primary = Color(hex: 0xA93702)
    static let primaryContainer = Color(hex: 0xF26B38)
    static let proteinTeal = Color(hex: 0x2D6A4F)
    static let warmSun = Color(hex: 0xFFD54F)
    static let inkBlack = Color(hex: 0x1C1C1E)

    static let textPrimary = Color(hex: 0x1B1C19)
    static let textSecondary = Color(hex: 0x58423A)
    static let textTertiary = Color(hex: 0x8C7168)
    static let mutedText = textSecondary
    static let outline = Color(hex: 0x8C7168)
    static let outlineVariant = Color(hex: 0xE0C0B5)

    // Legacy aliases — existing views keep compiling during redesign
    static let emerald = coachOrange
    static let emeraldSoft = coachOrange.opacity(0.12)
    static let emeraldDark = primary
    static let energy = warmSun
    static let energySoft = warmSun.opacity(0.2)
    static let protein = proteinTeal
    static let proteinSoft = proteinTeal.opacity(0.12)
    static let calories = coachOrange
    static let carbs = proteinTeal
    static let fat = warmSun
    static let accent = coachOrange
    static let accentDark = primary
    static let accentSoft = emeraldSoft
    static let cardBackground = surface
    static let coachBubble = surfaceMuted
    static let border = Color.black.opacity(0.06)
    static let stroke = border
    static let cardShadow = coachOrange.opacity(0.08)

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 20
    static let marginMain: CGFloat = 20

    static func greeting(for date: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
}

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

struct AppBackground: View {
    var body: some View {
        AppTheme.background.ignoresSafeArea()
    }
}

struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.surfaceContainerHighest, lineWidth: 1)
            )
            .shadow(color: AppTheme.cardShadow, radius: 12, y: 4)
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { SurfaceCard { content } }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: 12, y: 4)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true
    var pill: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, pill ? 18 : 16)
            .background(
                RoundedRectangle(cornerRadius: pill ? 999 : AppTheme.cornerRadius, style: .continuous)
                    .fill(enabled ? AppTheme.coachOrange : AppTheme.textTertiary.opacity(0.4))
            )
            .shadow(color: enabled ? AppTheme.coachOrange.opacity(0.25) : .clear, radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.coachOrange, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.outlineVariant, lineWidth: 1)
            )
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
    }
}

/// Scroll view that fills available space and scrolls when content overflows.
/// Use instead of `ScrollView` inside `VStack` / onboarding chrome layouts.
struct BoundedScrollView<Content: View>: View {
    var showsIndicators: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: showsIndicators) {
                content()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }

    /// Prefer `BoundedScrollView` for new code. Kept for legacy call sites.
    func boundedScrollFrame() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
