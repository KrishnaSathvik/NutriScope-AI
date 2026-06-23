import SwiftUI

enum AppTypography {
    static let family = "Hanken Grotesk"
    static let labelCapsFamily = "Inter"

    static func custom(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .semibold:
            .custom(family, size: size).weight(.bold)
        case .heavy, .black:
            .custom(family, size: size).weight(.heavy)
        default:
            .custom(family, size: size)
        }
    }

    static let largeTitle = custom(size: 34, weight: .heavy)
    static let displayLG = custom(size: 40, weight: .heavy)
    static let displayLGMobile = custom(size: 36, weight: .heavy)
    static let headlineLG = custom(size: 32, weight: .bold)
    static let title = custom(size: 28, weight: .bold)
    static let title2 = custom(size: 22, weight: .bold)
    static let title3 = custom(size: 20, weight: .semibold)
    static let headline = custom(size: 17, weight: .semibold)
    static let body = custom(size: 17)
    static let bodyLG = custom(size: 17)
    static let bodySM = custom(size: 15)
    static let headlineXL = custom(size: 34, weight: .heavy)
    static let callout = custom(size: 16)
    static let subheadline = custom(size: 15)
    static let footnote = custom(size: 13)
    static let caption = custom(size: 12)
    static let caption2 = custom(size: 11)
    static let labelCaps = Font.custom(labelCapsFamily, size: 12).weight(.semibold)
}

struct LabelCapsText: View {
    var text: String
    var color: Color = AppTheme.textSecondary

    var body: some View {
        Text(text.uppercased())
            .font(AppTypography.labelCaps)
            .tracking(0.6)
            .foregroundStyle(color)
    }
}

struct KineticFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(AppTypography.body)
    }
}

extension View {
    func kineticFont() -> some View {
        modifier(KineticFontModifier())
    }
}
