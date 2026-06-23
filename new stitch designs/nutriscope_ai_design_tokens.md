# Nutriscope AI: Design Tokens for SwiftUI Implementation

This document provides the core design tokens required to implement the "Next-Gen" Nutriscope AI interface in SwiftUI. Use these values to create your `Theme` or `Style` constants.

---

## 🎨 Color Palette
The app uses a warm, premium palette with high-contrast surfaces and energetic accents.

### Surface & Backgrounds
| Token | Hex Value | SwiftUI Usage |
| :--- | :--- | :--- |
| `surface-main` | `#fcf9f8` | Primary background for most screens. |
| `surface-bright` | `#fdf8f8` | Elevated card backgrounds. |
| `surface-container` | `#ffffff` | High-contrast backgrounds for modals or overlays. |
| `surface-dim` | `#ddd9d8` | Subtle borders or divider lines. |

### Brand & Accents
| Token | Hex Value | SwiftUI Usage |
| :--- | :--- | :--- |
| `primary` | `#a93702` | Primary CTA backgrounds, active states. |
| `coach-orange` | `#f26b38` | Protein highlights, trend lines, and Coach brand elements. |
| `secondary-container` | `#f7f2f2` | Inactive pill backgrounds, subtle secondary buttons. |
| `on-surface` | `#1c1b1b` | Primary text, titles, and icons. |
| `on-surface-variant`| `#4e4442` | Secondary text, captions, and supporting labels. |

---

## ✍️ Typography
Font Family: **Hanken Grotesk** (Standard iOS San Francisco can be used as a system fallback).

| Token | Size / Weight | SwiftUI Font Style |
| :--- | :--- | :--- |
| `display-lg` | 40pt / Black | `.system(size: 40, weight: .black)` |
| `headline-lg` | 32pt / Bold | `.system(size: 32, weight: .bold)` |
| `title-md` | 20pt / Semibold | `.system(size: 20, weight: .semibold)` |
| `body-lg` | 17pt / Regular | `.body` |
| `label-caps` | 12pt / Bold / Uppercase | `.system(size: 12, weight: .bold)` with `.uppercase` |
| `caption` | 12pt / Regular | `.caption` |

---

## 📐 Spacing & Layout
Standardized spacing increments based on a 4pt/8pt grid.

| Token | Value | Usage |
| :--- | :--- | :--- |
| `margin-main` | 20pt | Standard horizontal padding for screens. |
| `stack-lg` | 32pt | Vertical spacing between major sections. |
| `stack-md` | 16pt | Vertical spacing between items in a list. |
| `radius-lg` | 24pt | Corner radius for primary cards and modals. |
| `radius-full` | 999pt | Fully rounded buttons and macro pills. |

---

## ✨ Visual Effects
| Token | Value | Usage |
| :--- | :--- | :--- |
| `glass-bg` | White @ 80% opacity | Used with `.background(.ultraThinMaterial)` |
| `soft-shadow` | `(x: 0, y: 4, radius: 20, color: #f26b38 @ 8%)` | Standard card shadow for elevation. |
| `luminous-glow`| Radial Gradient (#f26b38 to Clear) | Subtle background accents behind Coach icons. |

---

## 🛠 SwiftUI Implementation Example
```swift
extension Color {
    static let nsPrimary = Color(hex: "#a93702")
    static let nsSurface = Color(hex: "#fcf9f8")
    static let nsCoachOrange = Color(hex: "#f26b38")
    static let nsTextMain = Color(hex: "#1c1b1b")
}

extension View {
    func nsCardStyle() -> some View {
        self.padding()
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
```