---
name: Kinetic Harvest
colors:
  surface: '#fbf9f4'
  surface-dim: '#dbdad5'
  surface-bright: '#fbf9f4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3ee'
  surface-container: '#f0eee9'
  surface-container-high: '#eae8e3'
  surface-container-highest: '#e4e2dd'
  on-surface: '#1b1c19'
  on-surface-variant: '#58423a'
  inverse-surface: '#30312e'
  inverse-on-surface: '#f2f1ec'
  outline: '#8c7168'
  outline-variant: '#e0c0b5'
  surface-tint: '#a93702'
  primary: '#a93702'
  on-primary: '#ffffff'
  primary-container: '#f26b38'
  on-primary-container: '#561700'
  inverse-primary: '#ffb59c'
  secondary: '#735c00'
  on-secondary: '#ffffff'
  secondary-container: '#fdd34d'
  on-secondary-container: '#725b00'
  tertiary: '#5d5e63'
  on-tertiary: '#ffffff'
  tertiary-container: '#949499'
  on-tertiary-container: '#2c2d31'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59c'
  on-primary-fixed: '#380c00'
  on-primary-fixed-variant: '#822800'
  secondary-fixed: '#ffe087'
  secondary-fixed-dim: '#ebc23e'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#e3e2e7'
  tertiary-fixed-dim: '#c6c6cb'
  on-tertiary-fixed: '#1a1b1f'
  on-tertiary-fixed-variant: '#46464b'
  background: '#fbf9f4'
  on-background: '#1b1c19'
  surface-variant: '#e4e2dd'
  coach-orange: '#F26B38'
  warm-sun: '#FFD54F'
  protein-teal: '#2D6A4F'
  paper-white: '#FFFFFF'
  ink-black: '#1C1C1E'
typography:
  headline-xl:
    fontFamily: Hanken Grotesk
    fontSize: 34px
    fontWeight: '800'
    lineHeight: 41px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
  title-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 25px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  numeric-display:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-main: 1.25rem
  gutter-card: 1rem
  stack-sm: 0.5rem
  stack-md: 1rem
  stack-lg: 1.5rem
---

## Brand & Style

The design system is built on a "Coach-Style Modernism" aesthetic. It balances the rigor of high-performance nutrition with an encouraging, warm atmosphere. The goal is to move away from the clinical, often anxiety-inducing nature of traditional calorie trackers toward an interface that feels like a supportive mentor.

The style leverages **Modern iOS standards** with a twist of **warmth**:
- **Professional yet Human:** Clean, structured layouts paired with soft, inviting colors.
- **High-Clarity Typography:** Large, accessible headers that make data digestion effortless.
- **Supportive Feedback:** Progress is celebrated through soft, organic shapes rather than harsh, jagged data points.
- **Tactile Comfort:** Generous tap targets and soft-radius containers that feel "at home" on a high-end mobile device.

## Colors

The palette is centered around **Coach Orange**, a vibrant hue that evokes energy and action without the aggression of pure red. This is paired with **Warm Sun** yellows to provide an encouraging glow across the UI.

- **Primary (Coach Orange):** Used for primary actions, active progress states, and brand-critical iconography.
- **Secondary (Warm Sun):** Used for secondary highlights, "attainment" celebrations, and background subtle fills.
- **Neutral (Paper White & Ink Black):** The canvas follows Apple’s high-contrast accessibility standards. The "Paper White" background has a slight warm tint (#F9F7F2) to reduce eye strain and feel more organic than a clinical pure white.
- **Functional Tint (Protein Teal):** A dedicated color for "healthy" thresholds and completed goals to provide visual variety and positive reinforcement.

## Typography

The system utilizes **Hanken Grotesk** as the primary typeface. It serves as a modern, high-fidelity alternative to San Francisco, offering a cleaner, more contemporary look while maintaining excellent legibility.

- **Headlines:** Use heavy weights (700-800) with tight tracking to create a "Large Title" iOS feel.
- **Body:** Set at 17px to match the Apple standard for readability.
- **Labels:** **Inter** is used for smaller UI labels and utility text due to its exceptional clarity at tiny scales.
- **Numeric Display:** Large-scale numbers for protein counts use the `numeric-display` style to make tracking the primary focus of the dashboard.

## Layout & Spacing

This design system follows a **Native iOS Fluid Grid** model. It relies on safe-area margins and a standard 4px/8px baseline rhythm.

- **Main Margins:** 20px (1.25rem) horizontal margins on all screens to ensure content doesn't feel cramped.
- **Card Spacing:** Internal padding for cards is set to 16px (1rem) to maintain a spacious, breathable feel.
- **Reflow:** On Tablet, cards transition from a single stack to a 2-column masonry grid to better utilize horizontal space.
- **Vertical Rhythm:** Elements are grouped in 8px increments (Stack SM = 8px, MD = 16px, LG = 24px) to create a clear visual hierarchy of related information.

## Elevation & Depth

To achieve the "Track without obsessing" vibe, depth is handled through **Tonal Layers** rather than heavy shadows.

- **Surfaces:** Use a two-tier background system. The base is `neutral_color_hex` and the foreground cards are `paper-white`.
- **Shadows:** Use extremely soft "Ambient Glows." For example, a card might have a 15% opacity `coach-orange` shadow with a 20px blur to suggest lift without looking "heavy" or "industrial."
- **Z-Axis:** Active states (like a tapped meal entry) should slightly scale up (1.02x) rather than just darkening, mimicking a tactile physical press.

## Shapes

The shape language is **Rounded**, leaning into the friendliness of the coach persona.

- **Cards:** Use the `rounded-lg` (16px/1rem) setting to match the curvature of modern iPhone hardware corners.
- **Buttons:** Primary call-to-actions utilize a semi-pill shape (24px) to distinguish them from data cards.
- **Progress Bars:** Should always have fully rounded (pill) end-caps to feel fluid and organic.
- **Selection States:** Checkboxes and radio buttons should be fully circular to avoid the "form-filling" feel of square inputs.

## Components

### Buttons
- **Primary:** Coach Orange background, white text, 16px height, rounded-xl.
- **Secondary:** Transparent background, Coach Orange 2px border.
- **Ghost:** Warm Sun text with no background for "Dismiss" or "Back" actions.

### Progress Bars
- High-contrast background (Warm Sun at 20% opacity) with a solid Coach Orange fill. The fill should have a subtle horizontal gradient to suggest movement.

### Cards
- **Meal Card:** White background, 16px rounded corners, subtle orange-tinted shadow. Includes a large-format protein number in the top right.
- **Quick-Add Card:** A smaller, "squishy" feeling card with a centered "+" icon for rapid entry.

### Input Fields
- Understated. No heavy borders—use a soft `neutral_color_hex` fill that darkens slightly on focus. Typography remains at the `body-lg` scale for ease of typing.

### Chips (Macros)
- Used for tagging meals (e.g., "High Protein," "Post-Workout"). Small, pill-shaped containers with a 10% opacity version of the tag's color and 100% opacity text.