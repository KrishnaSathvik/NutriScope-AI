---
name: Kinetic Harvest
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#58423a'
  inverse-surface: '#313030'
  inverse-on-surface: '#f3f0ef'
  outline: '#8c7168'
  outline-variant: '#e0c0b5'
  surface-tint: '#a93702'
  primary: '#a93702'
  on-primary: '#ffffff'
  primary-container: '#f26b38'
  on-primary-container: '#561700'
  inverse-primary: '#ffb59c'
  secondary: '#545a94'
  on-secondary: '#ffffff'
  secondary-container: '#b7bcfe'
  on-secondary-container: '#444a83'
  tertiary: '#006e1d'
  on-tertiary: '#ffffff'
  tertiary-container: '#4aa74e'
  on-tertiary-container: '#003509'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59c'
  on-primary-fixed: '#380c00'
  on-primary-fixed-variant: '#822800'
  secondary-fixed: '#dfe0ff'
  secondary-fixed-dim: '#bdc2ff'
  on-secondary-fixed: '#0e144d'
  on-secondary-fixed-variant: '#3c427b'
  tertiary-fixed: '#98f994'
  tertiary-fixed-dim: '#7ddb7b'
  on-tertiary-fixed: '#002204'
  on-tertiary-fixed-variant: '#005313'
  background: '#fcf9f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-bold:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.05em
  caption:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style
The design system for Nutriscope AI balances high-energy nutritional intelligence with approachable warmth. The "Kinetic Harvest" aesthetic moves away from sterile, clinical environments in favor of a vibrant, food-centric atmosphere. It targets health-conscious individuals who view nutrition as fuel for an active lifestyle rather than a medical restriction.

The visual style is a hybrid of **Minimalism** and **High-Contrast Bold**. It utilizes expansive white space to maintain professional clarity, punctuated by aggressive splashes of color and thick, purposeful strokes in data visualization. The emotional response should be one of empowerment and momentum—feeling like a premium kitchen tool rather than a diagnostic instrument.

## Colors
The palette is centered on "Kinetic Orange," a high-chroma primary shade that signals energy and appetite. 

- **Primary (#F26B38):** Used for primary actions, progress indicators, and brand-critical highlights.
- **Secondary (#2D336B):** A deep "Midnight Blue" used for data contrast and deep typography to ground the energetic orange.
- **Tertiary (#47A44B):** A "Leaf Green" specifically reserved for positive nutritional markers and "fresh" status indicators.
- **Neutral:** Pure white (#FFFFFF) is the primary surface color to ensure the vibrant accents feel crisp. Grays are kept warm-toned to maintain the "friendly, not medical" atmosphere.

## Typography
This design system uses **Hanken Grotesk** exclusively to maintain a sharp, contemporary, and highly legible profile. The typeface’s geometry is professional yet accessible.

Large display headings use extra-bold weights and tight tracking to evoke the "Kinetic" energy of the brand. Body text is prioritized for readability with generous line heights. Data labels should use the uppercase "label-bold" style to differentiate metrics from narrative content.

## Layout & Spacing
The design system employs a **Fluid Grid** with a strict 8px baseline rhythm. 

- **Desktop:** 12-column grid with 24px gutters. Content is centered with a max-width of 1280px.
- **Tablet:** 8-column grid with 20px gutters. 
- **Mobile:** 4-column grid with 16px gutters and 16px side margins.

Spacing should favor "Grouping by Proximity"—use small increments (4px, 8px) for related data points within cards, and large increments (48px+) to separate distinct sections of the analysis.

## Elevation & Depth
To maintain the "clean white surface" requirement, depth is created through **Tonal Layers** and **Low-Contrast Outlines** rather than heavy shadows.

- **Level 0 (Background):** Pure White (#FFFFFF) or very light warm gray (#FAFAFA).
- **Level 1 (Cards/Containers):** White surface with a 1px solid border (#EFEFEF).
- **Interactive State:** Elements gain a soft, "Ambient Shadow" (Primary color at 10% opacity, 20px blur) only upon hover or focus to signal interactivity.
- **Data Overlays:** High-contrast Secondary color containers are used for floating action buttons or critical tooltips to pop against the white background.

## Shapes
The system utilizes the **ROUND_EIGHT** philosophy (8px/0.5rem base) to achieve a soft, organic feel that mimics natural food shapes without appearing juvenile.

- **Standard Components:** 8px radius (buttons, input fields, small cards).
- **Feature Containers:** 16px radius (large dashboard widgets, meal photos).
- **Full Rounding:** Pill shapes are reserved exclusively for "Chips" and status indicators.

## Components
- **Buttons:** Primary buttons are solid Kinetic Orange with white text. High-energy hover state increases saturation. Secondary buttons use the Midnight Blue as a 2px outline.
- **Data Visualizations:** Use high-contrast fills. Bar charts and rings should use the 8px corner radius on end-caps to maintain the shape language.
- **Cards:** White background, 1px light gray border, 16px internal padding. Title text in Secondary color.
- **Input Fields:** 8px radius, 1px border. On focus, the border thickens to 2px Primary Orange.
- **Chips:** Highly rounded (pill), used for food categories or allergens. Backgrounds are 10% opacity versions of the Primary or Tertiary colors.
- **Nutriscope AI Insight Box:** A special component with a subtle Tertiary (Green) gradient border to denote AI-generated "fresh" advice.