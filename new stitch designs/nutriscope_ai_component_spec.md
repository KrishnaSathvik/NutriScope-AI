# Nutriscope AI: Component-Level Specification

This document defines the structural and visual rules for key UI components in the Nutriscope AI "Next-Gen" interface. Use these specifications alongside the core design tokens in DOCUMENT_4.

---

## 1. Macro Pills (The "Protein-First" Unit)
The primary data visualization component for macros.

| Property | Specification |
| :--- | :--- |
| **Height** | 32pt |
| **Corner Radius** | Full (Capsule) |
| **Padding** | Horizontal: 12pt, Vertical: 4pt |
| **Background (Default)** | `secondary-container` (#f7f2f2) |
| **Background (Highlight)** | `primary` (#a93702) with 10% opacity |
| **Typography** | `label-caps` (12pt / Bold / Uppercase) |
| **Interaction** | Slight scale increase (1.05x) on tap. |

### SwiftUI Pattern:
```swift
struct MacroPill: View {
    let label: String
    var isHighlighted: Bool = false
    
    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(isHighlighted ? Color.nsPrimary.opacity(0.1) : Color.nsSecondaryContainer)
            .foregroundColor(isHighlighted ? Color.nsPrimary : Color.nsTextMain)
            .clipShape(Capsule())
    }
}
```

---

## 2. Next-Gen Glassmorphic Cards
Used for the Dashboard and Progress sections to create depth.

| Property | Specification |
| :--- | :--- |
| **Background** | `surface-container` (#ffffff) |
| **Opacity** | 80% - 90% depending on layer depth |
| **Blur** | Background Material: `.ultraThinMaterial` |
| **Border** | 1pt solid / `surface-dim` (#ddd9d8) @ 20% opacity |
| **Shadow** | `soft-shadow` (x: 0, y: 4, radius: 20, color: #f26b38 @ 8%) |
| **Corner Radius** | 24pt |

---

## 3. Protein Trend Chart
Interactive line chart for weekly/monthly insights.

| Property | Specification |
| :--- | :--- |
| **Line Color** | `primary` (#a93702) |
| **Line Weight** | 3pt, rounded caps |
| **Data Points** | 6pt Diameter circle, `primary` fill, `surface-main` border |
| **Grid Lines** | `surface-dim` (#ddd9d8), 1pt dash (4,4) |
| **Area Fill** | Vertical Gradient: `primary` (10% opacity) to Clear |

---

## 4. Coach Chat Bubbles
Differentiating between AI and User messages.

### AI (Coach Nova)
- **Background:** `surface-bright` (#fdf8f8)
- **Typography:** `body-lg` (#1c1b1b)
- **Shape:** Rounded Rect (TL: 4, TR: 20, BL: 20, BR: 20)
- **Icon:** 24pt Coach Avatar (Circle crop)

### User
- **Background:** `primary` (#a93702)
- **Typography:** `body-lg` (#ffffff)
- **Shape:** Rounded Rect (TL: 20, TR: 4, BL: 20, BR: 20)

---

## 5. Main Action Button (FAB)
The center "Scan" button in the tab bar.

| Property | Specification |
| :--- | :--- |
| **Size** | 64pt x 64pt |
| **Icon Size** | 28pt |
| **Background** | `primary` (#a93702) |
| **Elevation** | Floating with 12pt shadow depth |
| **Effect** | Luminous glow behind the button (Coach Orange @ 15% opacity) |

---

## 🛠 Swift Composition Example: Dashboard Header
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Today's Protein")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary)
    
    HStack(alignment: .lastTextBaseline) {
        Text("148g")
            .font(.system(size: 40, weight: .black))
            .foregroundColor(Color.nsPrimary)
        Text("/ 180g")
            .font(.title3)
            .bold()
            .foregroundColor(.secondary)
    }
}
.padding(24)
.background(.ultraThinMaterial)
.cornerRadius(24)
.shadow(color: Color.nsCoachOrange.opacity(0.08), radius: 20, x: 0, y: 4)
```