---
name: ProteinPlate AI
colors:
  surface: '#fcf9f8'
  surface-dim: '#ddd9d8'
  surface-bright: '#fdf8f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f2f2'
  surface-container: '#f1edec'
  surface-container-high: '#ece7e7'
  surface-container-highest: '#e6e1e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#58423a'
  inverse-surface: '#313030'
  inverse-on-surface: '#f4f0ef'
  outline: '#8c7168'
  outline-variant: '#e0c0b5'
  surface-tint: '#a93702'
  primary: '#812700'
  on-primary: '#ffffff'
  primary-container: '#f26b38'
  on-primary-container: '#ffcdbd'
  inverse-primary: '#ffb59c'
  secondary: '#545a94'
  on-secondary: '#ffffff'
  secondary-container: '#b7bcfd'
  on-secondary-container: '#444a83'
  tertiary: '#005314'
  on-tertiary: '#ffffff'
  tertiary-container: '#006e1d'
  on-tertiary-container: '#8fee8c'
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
  on-secondary-fixed-variant: '#3c427a'
  tertiary-fixed: '#99f895'
  tertiary-fixed-dim: '#7edb7c'
  on-tertiary-fixed: '#002204'
  on-tertiary-fixed-variant: '#005314'
  background: '#fdf8f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
  gauge-track: '#eae7e7'
  glass-bg: rgba(255, 255, 255, 0.7)
  glass-border: rgba(255, 255, 255, 0.9)
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
  label-caps:
    fontFamily: Hanken Grotesk
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.1em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  xs: 4px
  base: 8px
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  margin-mobile: 16px
  margin-desktop: 40px
  gutter: 24px
---

## Brand & Style
ProteinPlate AI embodies a "Premium Wellness" aesthetic, blending the cleanliness of modern SaaS with the warmth of high-end lifestyle photography. The brand personality is optimistic, motivating, and precise. 

The visual style is **Glassmorphism-Infused Minimalism**. It utilizes semi-transparent, high-blur surfaces (20px blur) to create a sense of depth and airiness. The interface feels "alive" through the use of soft radial background gradients that subtly tint the workspace without overwhelming the content. High-impact data visualizations (like the gauge chart) use vibrant gradients and glowing drop shadows to transform clinical data into an engaging, celebratory experience.

## Colors
The palette is built on "Sun-Drenched Organics." 
- **Primary (#a93702):** A deep, burnt terracotta used for critical branding and high-emphasis actions.
- **Primary Container (#f26b38):** A vibrant orange used for progress indicators and interactive elements to provide energy.
- **Secondary (#545a94):** A muted indigo-slate used for secondary headers to provide a professional, calming contrast to the warm primary tones.
- **Background:** Not a flat hex, but a dynamic surface (#fcf9f8) layered with soft radial gradients of `#ffdbcf` (40% opacity) and `#f26b38` (10% opacity) to evoke morning light.
- **Glass Elements:** Backgrounds use 70% white with high-refraction borders (90% white) to maintain legibility over the textured background.

## Typography
The system uses **Hanken Grotesk** exclusively to maintain a sharp, contemporary, and highly legible feel. 
- **Scale:** Bold weights (700-800) are used for "Display" and "Headline" levels to create a strong information hierarchy.
- **Special Treatments:** Large data points (e.g., "72g") utilize ultra-heavy weights (Black/900) and tight tracking for a "dashboard" look.
- **Labels:** Small labels use uppercase styling with increased letter spacing (0.05em to 0.1em) to ensure clarity at small sizes, particularly in navigation and tags.

## Layout & Spacing
The layout follows a **Hybrid Bento-Box Grid**. 
- **Desktop:** A 12-column fluid grid within a 1280px container. Large cards typically span 8 columns, while secondary insights and trends span 4.
- **Mobile:** Single column fluid layout with 16px horizontal margins.
- **Spacing Rhythm:** Based on an 8px scale. `24px` (md) is the standard padding for cards and section spacing. `48px` (lg) is used for major vertical section breaks.
- **Navigation:** Sticky top-bar (64px) for desktop; hybrid bottom navigation with a prominent floating action button (FAB) for mobile to prioritize one-handed "Log Meal" actions.

## Elevation & Depth
Depth is achieved through **Tonal Stacking and Glassmorphism** rather than traditional heavy shadows.
- **Base Level:** Background with soft radial gradients.
- **Mid Level (Cards):** Semi-transparent white (70%) with a 20px backdrop-blur. Borders are solid 90% white to define edges.
- **High Level (Primary FAB/Action Buttons):** Solid primary colors with colored ambient shadows (e.g., `rgba(169, 55, 2, 0.2)`) to make them feel elevated and interactive.
- **Interactive States:** Cards use a subtle scale transform (1.01x) and increased shadow on hover to signal clickability.

## Shapes
The shape language is "Hyper-Rounded," favoring comfort and friendliness.
- **Container Cards:** Use a 32px (`2xl/3xl` equivalent) corner radius, creating a soft, organic feel.
- **Buttons & Chips:** Follow a "Pill" or "Soft Rect" philosophy with 16px to 24px radius.
- **Media:** Images and meal previews use a 16px or 24px radius to match the card containers.
- **Progress Bars:** Fully rounded (caps) to maintain the fluid aesthetic.

## Components
- **Buttons:** Primary buttons are high-contrast (Primary Orange/White text) with a subtle shadow. They should include an icon (Material Symbols) for immediate recognition.
- **Premium Cards:** Must include `backdrop-blur-md`, a semi-transparent white background, and a thin white border.
- **Data Visualization:** Gauges should use linear gradients (from #f26b38 to #a93702) and include a glow effect (`drop-shadow`) on the active progress segment.
- **Chips/Tags:** Used for nutritional data (P/C/F). Primary tags use a 10% primary background with a 20% primary border; secondary tags use a neutral surface-variant.
- **Navigation (Mobile):** The "Home" item uses a container-style highlight, while other items remain icon + label. The center FAB is 64x64px, perfectly circular, with a 4px "safe-zone" border matching the nav background.
- **Input/Action Cards:** Lists of meals should include a 96x96px image with a large corner radius and clear typography hierarchy (Title > Time/Type > Nutrients).