# Nutriscope AI: Interactive Component Behaviors

This document specifies the interactive states and micro-interactions for the Nutriscope AI "Next-Gen" UI components.

---

## 1. The Luminous Scan FAB
The central action in the bottom navigation bar.

| State | Behavior | Visual Feedback |
| :--- | :--- | :--- |
| **Idle** | Breathing Glow | A slow (4s period) opacity pulse of the `coach-orange` glow behind the button (0.05 to 0.15). |
| **Tap (Down)** | Scale & Compress | Scale down to 0.92x. Glow intensifies to 0.3 opacity. |
| **Release (Up)** | Spring Launch | Scale back to 1.0x with a light spring (stiffness: 300, damping: 15). |
| **Active/Scanning** | Rotating Rim | A subtle white gradient rotation around the border of the inner icon. |

---

## 2. Dynamic Macro Pills
The "Protein-First" data units.

| Interaction | Behavior | Visual Feedback |
| :--- | :--- | :--- |
| **On Tap** | Expansion | Pill expands horizontally (+15%) to reveal a numeric breakdown (e.g., "35g P" -> "35g Protein / 140 kcal"). |
| **Selection** | Haptic Bump | Medium impact haptic. Background shifts from `secondary-container` to 10% `primary`. |
| **Goal Hit** | Sparkle Bloom | When a log completes a goal, the pill emits a brief "bloom" effect (radial expansion of the primary color). |

---

## 3. Glassmorphic Card Parallax
Used for the Dashboard "Today" cards.

| State | Behavior | Visual Feedback |
| :--- | :--- | :--- |
| **Scroll Trigger** | Vertical Parallax | The internal elements (the protein number and "Fix My Day" button) move at 1.1x the scroll speed of the card container. |
| **Tap (Card)** | Elevation Lift | The shadow `soft-shadow` radius increases from 20pt to 32pt. |

---

## 4. Coach Chat Bubbles
AI (Nova) vs. User.

| Interaction | Behavior | Visual Feedback |
| :--- | :--- | :--- |
| **Nova Typing** | Wave Dots | Three dots following a sine-wave path. |
| **Message Arrival** | Slide-Fade | Messages slide up from 10pt below their final position while fading in (250ms duration). |
| **Nova Advice Tap** | Spotlight | Tapping a Coach suggestion highlights the referenced UI element (e.g., the Log button) with a soft orange pulse. |

---

## 5. Progress Chart Interactions
Interactive line chart for Weekly/Monthly insights.

| State | Behavior | Visual Feedback |
| :--- | :--- | :--- |
| **Long Press** | Vertical Scrubber | A vertical line follows the finger. The nearest data point scales to 1.5x. |
| **Scrub Tooltip** | Snap-to-Point | Tooltip "snaps" to the active data point with a 100ms lag for a "magnetic" feel. |
| **Switch View** | Cross-Fade | Transitioning from Weekly to Monthly uses a cross-dissolve with a slight horizontal slide (left-to-right). |

---

## 🛠 SwiftUI Implementation: Spring Animation Token
```swift
extension Animation {
    static let nsStandardSpring = Animation.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0)
    static let nsBouncySpring = Animation.spring(response: 0.45, dampingFraction: 0.5, blendDuration: 0)
}
```
