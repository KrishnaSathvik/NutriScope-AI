# Nutriscope AI

**Calories are rough. Protein is the goal.**

Native iOS app (SwiftUI) for protein-first meal tracking with AI photo estimates, confidence ranges, smart follow-up questions, and coach-style next-meal advice.

## MVP features

| Feature | Status |
|---------|--------|
| Photo meal scan | PhotosPicker + Supabase `analyze-meal` edge function |
| AI macro ranges | Mock (offline demo) + server-side OpenAI via Supabase |
| Confidence score | High / medium / low |
| Smart follow-up questions | Oil, portions, cooking style |
| Next-meal protein advice | Coach cards |
| Daily protein tracker | Progress bar on Today tab |
| Meal history | SwiftData, grouped by day |
| Paywall | 5 free scans/week + StoreKit 2 (monthly/yearly) |

## Open in Xcode

```bash
open NutriscopeAI.xcodeproj
```

1. Select your **Development Team** in Signing & Capabilities.
2. Run on simulator or device (iOS 17+).

## Backend setup (required for live meal scans)

See **[doc/BACKEND_SETUP.md](doc/BACKEND_SETUP.md)** for full instructions.

Quick start:

```bash
cp NutriscopeAI/Resources/Backend.xcconfig.example NutriscopeAI/Resources/Backend.xcconfig
# Add your iOS Supabase URL + anon key
```

Guest users get a silent **anonymous Supabase session** so meal scans work without signup. Anonymous auth must be enabled in your Supabase project.

## Demo mode (no backend)

Enable **Offline demo** in Profile → Developer (Debug), or launch with `-OfflineDemo`. Uses mock meal templates — no network required.

## Project structure

```
NutriscopeAI/
├── App/                 AppState, routing
├── Models/              MealAnalysis, MealRecord (SwiftData), UserSettings
├── Services/            AI analysis, scan quota, StoreKit subscriptions
├── Views/               Today, Scan, History, Profile, Paywall, Onboarding
├── Components/          Protein bar, macro cards, coach UI
└── Theme/               Kinetic Harvest palette

supabase/
├── functions/analyze-meal/   Meal scan AI proxy (production)
└── migrations/               ios_user_profiles (future sync)
```

## App Store Connect (before launch)

1. Create app `com.nutriscopeai.app`
2. Add subscription products (must match code):
   - `com.nutriscopeai.pro.monthly`
   - `com.nutriscopeai.pro.yearly`
3. Configure **7-day free trial** introductory offer in App Store Connect (paywall UI shows trial only when StoreKit reports an intro offer)
4. Host live **Terms**, **Privacy**, and **Support** URLs
5. App Store privacy nutrition labels (photos sent to server for AI analysis)

## Implementation status

See **[MASTER_IMPLEMENTATION_AUDIT.md](MASTER_IMPLEMENTATION_AUDIT.md)** and **[P0_FIX_PLAN.md](P0_FIX_PLAN.md)** for the full audit and backend alignment roadmap.

## Regenerate Xcode project

If you add Swift files:

```bash
python3 generate_xcode_project.py
```

## Pricing reference

| Plan | Price (reference) |
|------|-------------------|
| Free | 5 scans/week |
| Monthly | StoreKit `displayPrice` |
| Yearly | StoreKit `displayPrice` |
