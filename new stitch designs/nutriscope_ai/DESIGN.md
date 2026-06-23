---
name: Nutriscope AI
colors:
  surface: '#fcf8fb'
  surface-dim: '#dcd9dc'
  surface-bright: '#fcf8fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f5'
  surface-container: '#f0edef'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e4e2e4'
  on-surface: '#1b1b1d'
  on-surface-variant: '#584239'
  inverse-surface: '#303032'
  inverse-on-surface: '#f3f0f2'
  outline: '#8c7168'
  outline-variant: '#e0c0b5'
  surface-tint: '#a83900'
  primary: '#a83900'
  on-primary: '#ffffff'
  primary-container: '#f06a33'
  on-primary-container: '#531800'
  inverse-primary: '#ffb59a'
  secondary: '#2c694e'
  on-secondary: '#ffffff'
  secondary-container: '#aeeecb'
  on-secondary-container: '#316e52'
  tertiary: '#7c5800'
  on-tertiary: '#ffffff'
  tertiary-container: '#bf8900'
  on-tertiary-container: '#3b2800'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59a'
  on-primary-fixed: '#380d00'
  on-primary-fixed-variant: '#812900'
  secondary-fixed: '#b1f0ce'
  secondary-fixed-dim: '#95d4b3'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#0e5138'
  tertiary-fixed: '#ffdea8'
  tertiary-fixed-dim: '#ffba20'
  on-tertiary-fixed: '#271900'
  on-tertiary-fixed-variant: '#5e4200'
  background: '#fcf8fb'
  on-background: '#1b1b1d'
  surface-variant: '#e4e2e4'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Work Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  mono-data:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-margin: 20px
  stack-gap: 12px
---

## Brand & Style
The brand personality for the design system is "Optimistic Utility." It moves away from the clinical coldness of traditional medical apps, adopting a "friendly, not medical" tone that feels like a knowledgeable kitchen companion rather than a doctor's office. The target audience consists of health-conscious individuals who prioritize protein intake and need a high-velocity, low-friction tracking experience.

The design style is **Modern Corporate with a Kinetic twist**, heavily inspired by **iOS 17+ SwiftUI** patterns. This manifests as high-clarity typography, large interactive targets, and a sense of depth achieved through subtle layering rather than heavy shadows. The aesthetic is "Kinetic Harvest"—celebrating the energy of whole foods through vibrant color accents and fluid motion, wrapped in a clean, professional shell that ensures the data remains the hero.

The user should feel empowered and focused. The interface reflects the tagline "Calories are rough. Protein is the goal." by visually prioritizing protein metrics and simplifying complex nutritional data into actionable, high-contrast visual cues.

## Colors
The palette is rooted in a professional yet appetizing selection of "Harvest" tones.
- **Primary (Zest Orange):** Used for protein-related call-to-actions, progress rings, and primary highlights. It conveys energy and metabolic fire.
- **Secondary (Earth Green):** Used for overall health indicators, vegetable intake, and success states. It grounds the design in a food-focused context.
- **Tertiary (Yolk Gold):** An accent color for "warning" or "near-goal" states, providing warmth and variety to data visualizations.
- **Neutral (Obsidian & Cloud):** We utilize a strict iOS-inspired neutral scale. Backgrounds use a tiered system of off-whites and light greys to create a sense of hierarchy without heavy borders.

## Typography
This design system uses a triple-font approach to maximize readability and information density:
1. **Plus Jakarta Sans** for headlines and display text. Its soft, rounded terminals provide the "friendly" atmosphere necessary for a health app.
2. **Work Sans** for all body copy. It is professional, grounded, and exceptionally legible even in dense ingredient lists.
3. **Geist** for labels and data points. Its technical, precise nature is used for calorie counts, gram measurements, and timestamped logs, providing a "high-performance" feel to the tracking aspect.

For mobile, headlines are capped at 28px to ensure protein goals are always visible above the fold. All body text maintains a minimum 16px size for iOS accessibility standards.

## Layout & Spacing
The layout follows a **Fluid SwiftUI logic**, prioritizing safe-area margins and dynamic content blocks.
- **Grid:** A standard 4-column mobile grid and 12-column desktop grid, but the core layout relies on a **Stack-based model**. Elements are grouped in vertical containers with a `stack-gap` of 12px.
- **Margins:** 20px side margins are used on mobile to provide breathing room while maximizing the horizontal space for data cards.
- **Adaptability:** On larger screens, the layout shifts from a single vertical feed to a multi-column "Dashboard" view, where primary protein tracking sits on the left and the meal log/history occupies a wider secondary column.

## Elevation & Depth
This design system utilizes **Tonal Layers and Glassmorphism** to reflect the modern iOS interface.
- **Platter System:** Content is housed in "Platters" (cards) with a subtle light-grey background (`#F2F2F7`) against a white base. This avoids heavy shadows.
- **Materials:** High-priority modals and navigation bars use a "Thick Material" backdrop blur (frosted glass) to maintain context while focusing the user.
- **Depth:** 1px "Inner Glow" or "Hairline Borders" (0.5pt in SwiftUI) are used on primary cards to give them a tactile, premium feel without looking cluttered. Shadows are strictly limited to floating action buttons (FABs) and are highly diffused with a 10% opacity primary color tint.

## Shapes
The shape language is consistently **Rounded**, aligning with the "Soft UI" approach.
- **Standard Cards:** Use a 16px (`rounded-lg`) corner radius, matching the standard iOS container aesthetic.
- **Interactive Elements:** Buttons and input fields use a 12px radius to feel distinct from larger containers.
- **Data Accents:** Progress bars and small tags use a fully "Pill-shaped" (999px) radius to indicate fluidity and movement.

## Components
- **Buttons:** Primary buttons use a solid Zest Orange fill with white bold text. Secondary buttons use a "Tonal" style (Light Orange background with Dark Orange text) for a softer hierarchy.
- **Protein Rings:** Circular progress indicators that use a thick stroke for the primary goal (Protein) and thinner, semi-transparent strokes for secondary macros.
- **Meal Cards:** Large-format cards featuring a food image (if available) with a "Glass" overlay at the bottom containing the name and protein count.
- **Chips:** Small, rounded-pill labels used for "High Protein," "Low Carb," or "Quick Add" tags. They use the Secondary Green or Tertiary Gold colors at 15% opacity.
- **Input Fields:** Bottom-aligned labels that transition to a floating state when active. They utilize a subtle background fill rather than a bottom line.
- **The "Goal Bar":** A persistent, fixed component at the top of the dashboard that uses a "Liquid Fill" animation to show progress toward the daily protein goal.