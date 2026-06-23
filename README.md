# Nutriscope AI

**Calories are rough. Protein is the goal.**

Native iOS app (SwiftUI) for protein-first meal tracking with AI photo estimates, confidence ranges, smart follow-up questions, and coach-style next-meal advice.

## MVP features

| Feature | Status |
|---------|--------|
| Photo meal scan | ✅ PhotosPicker |
| AI macro ranges | ✅ Mock + OpenAI Vision |
| Confidence score | ✅ High / medium / low |
| Smart follow-up questions | ✅ Oil, portions, cooking style |
| Next-meal protein advice | ✅ Coach cards |
| Daily protein tracker | ✅ Progress bar on Today tab |
| Meal history | ✅ SwiftData, grouped by day |
| Paywall | ✅ 5 free scans/week + StoreKit 2 stub |

## Open in Xcode

```bash
open /Users/krishnasathvikmantripragada/proteinplate-ai/NutriscopeAI.xcodeproj
```

1. Select your **Development Team** in Signing & Capabilities.
2. Run on simulator or device (iOS 17+).

## Demo mode (no API key)

Without an OpenAI key, the app uses **offline demo templates** (Chipotle bowl, Indian dal plate, pizza, breakfast). Great for TikTok demo videos and beta UX testing.

## Live AI scans

Add your OpenAI API key either:

- **In app:** Profile → Developer → OpenAI API key
- **Environment:** `OPENAI_API_KEY` in the Xcode scheme

Uses `gpt-4o-mini` vision with JSON output for structured macro ranges and follow-up questions.

## Project structure

```
NutriscopeAI/
├── App/                 AppState, routing
├── Models/              MealAnalysis, MealRecord (SwiftData), UserSettings
├── Services/            AI analysis, scan quota, StoreKit subscriptions
├── Views/               Today, Scan, History, Profile, Paywall, Onboarding
├── Components/          Protein bar, macro cards, coach UI
└── Theme/               Coach-style warm palette
```

## App Store Connect (before launch)

1. Create app `com.nutriscopeai.app`
2. Add subscription products:
   - `com.nutriscopeai.pro.monthly` — $7.99/mo
   - `com.nutriscopeai.pro.yearly` — $49.99/yr
   - `com.nutriscopeai.pro.lifetime` — $49 one-time
3. Add App Store privacy nutrition labels (photos sent to OpenAI if using live AI)
4. Disclaimer: estimates only, not medical advice

## Validation plan (from research)

1. **Landing page:** “Track meals without obsessing. Photo → protein → next meal advice.”
2. **5 demo videos:** Chipotle, Indian meal, pizza fix, breakfast gap, restaurant estimate
3. **Target:** 100+ beta emails, 10 early payers before full polish

## Regenerate Xcode project

If you add Swift files:

```bash
python3 generate_xcode_project.py
```

## Pricing reference

| Plan | Price |
|------|-------|
| Free | 5 scans/week |
| Monthly | $7.99/mo |
| Yearly | $49.99/yr |
| Lifetime (launch) | $49 once |
