# Nutriscope AI — Master Implementation Audit

**Audit date:** 2026-06-23  
**Repo:** `proteinplate-ai`  
**Auditor scope:** Read-only end-to-end inspection — iOS frontend, Supabase backend, StoreKit, auth, design templates, production readiness. No code changes were made.

---

## 1. Executive Summary

### Overall status: **Partial**

Nutriscope AI has a **substantial SwiftUI implementation**: onboarding, five-tab shell, meal scanning, coach, paywall, profile tools, and local SwiftData persistence. The **Kinetic Harvest** design system is partially reflected in `AppTheme` and shared components. However, the app is **not production-ready** for release builds without external Supabase configuration, and several backend/auth policies **conflict** with the implemented guest-first flow.

| Area | Status |
|------|--------|
| iOS UI / navigation | **Strong** — 39 view files, reachable flows |
| Design template parity | **Partial** — canonical v1 mostly built; account choice, trial ending, some polish missing |
| StoreKit 2 | **Implemented** — monthly/yearly, intro-offer-aware UI |
| Supabase auth | **Partial** — client code exists; anonymous auth policy conflicts |
| Supabase data sync | **Missing** — SwiftData local-only |
| AI meal analysis (release) | **Partial** — edge function exists; requires JWT + config |
| Coach / Whisper / tips (release) | **Broken path** — device OpenAI key required |
| Automated tests | **None** |
| Build | **Succeeds** (Debug, iOS Simulator) |

### Top 5 blockers (P0)

1. **Anonymous Supabase auth conflict** — App bootstraps anonymous JWT for guests (`BackendAuthBootstrap`), but `supabase/config.toml` and `doc/BACKEND_SETUP.md` specify Anonymous OFF.
2. **No in-repo production Supabase config** — Release meal scans require `SUPABASE_URL` + `SUPABASE_ANON_KEY` via xcconfig/env; otherwise `UnconfiguredMealAnalysisService` throws.
3. **Coach, Whisper, and coach tips use device-side OpenAI** — Release builds cannot call OpenAI for these without embedding a user API key.
4. **`ios_user_profiles` table unused** — Migration + RLS exist but iOS never writes to PostgREST.
5. **Zero automated tests** — No XCTest target in the Xcode project.

### Top 5 missing screens / features

1. **Account choice** screen (`stitch_designs/account_choice`) — design exists; flow uses implicit guest path.
2. **Trial ending soon** (`stitch_designs/trial_ending_soon`) — no Swift implementation.
3. **Cloud data sync** — meals, profile, weights, grocery, saved meals not synced.
4. **Supabase email password recovery** — `ResetPasswordView` updates local UserDefaults only.
5. **Social meal estimator** (v2 design) — not implemented.

### Top 5 backend gaps

1. No meal / saved-meal / weight / grocery sync tables or iOS client.
2. No coach or Whisper edge functions.
3. No server-side scan quota tracking.
4. No App Store receipt / subscription validation server.
5. Profile upsert to `ios_user_profiles` never called from iOS.

### Recommended next step

Resolve P0 auth + backend configuration conflicts, deploy `analyze-meal` to production Supabase with secrets, proxy remaining AI calls through edge functions, then design cloud-sync schema before TestFlight.

---

## 2. Repo Structure Overview

### Note on `pro/` folder

The user-requested **`pro/` folder does not exist** in this repository (not in workspace or git history). Design templates were audited from:

- [`stitch_designs/`](stitch_designs/) — 68 folders, ~60 `code.html` + design system YAML
- [`stitch_proteinplate_ai_tracker*`](stitch_proteinplate_ai_tracker/) — 8 numbered tracker folders at repo root
- [`other pages/`](other%20pages/) — duplicate tracker designs + misc
- [`CANONICAL_SCREENS.md`](CANONICAL_SCREENS.md) — v1 build plan mapping
- [`DESIGN_FLOWS.md`](DESIGN_FLOWS.md) — product brief and business rules

### iOS app

| Item | Path |
|------|------|
| Entry point | `NutriscopeAI/NutriscopeAIApp.swift` — `@main`, SwiftData container |
| Root navigation | `NutriscopeAI/Views/RootView.swift` |
| Global state | `NutriscopeAI/App/AppState.swift`, `AppTab.swift` |
| Views (screens) | 39 files under `NutriscopeAI/Views/` |
| Components | 11 files under `NutriscopeAI/Components/` |
| Services | 28 files under `NutriscopeAI/Services/` |
| Models | 10 files — 5 `@Model` (SwiftData), 5 Codable structs |
| Theme | `NutriscopeAI/Theme/AppTheme.swift`, `AppTypography.swift` |
| Widget | `NutriscopeWidget/ProteinWidget.swift` |
| Entitlements | HealthKit, Sign in with Apple, App Group `group.com.nutriscopeai.app` |
| Bundle ID | `com.nutriscopeai.app` |

### Backend

| Item | Path |
|------|------|
| Supabase config | `supabase/config.toml` |
| Migrations | `supabase/migrations/001_ios_user_profiles.sql` (only migration) |
| Edge functions | `supabase/functions/analyze-meal/index.ts` (only function) |
| Setup docs | `doc/BACKEND_SETUP.md` |

### Config / secrets

| Item | Path |
|------|------|
| Backend xcconfig example | `NutriscopeAI/Resources/Backend.xcconfig.example` (gitignored live `Backend.xcconfig`) |
| Legal URLs | `NutriscopeAI/Services/AppLegalLinks.swift` |
| Debug developer panel | `ProfileAccountView.swift` — `#if DEBUG` only |

### Tests

**None.** No XCTest target in `NutriscopeAI.xcodeproj/project.pbxproj`. No `@testable import` in Swift sources.

### Architecture (current)

```
NutriscopeAIApp
  └── RootView
        ├── AuthFlowView (onboarding incomplete)
        └── MainTabView (onboarding complete)
              ├── Today / Meals / Coach / Profile tabs
              └── Scan tab → sheet (ScanMealView)
        └── Sheets: scan | paywall | scanQuota | subscriptionSuccess | saveProgress

SwiftData (local): MealRecord, UserSettings, SavedMeal, WeightLog, GroceryItem
Supabase: GoTrue REST auth + analyze-meal edge function (JWT required)
StoreKit 2: SubscriptionManager (monthly/yearly entitlements)
```

---

## 3. Design Templates Found in `pro`

### Design system (foundation)

| File | Describes |
|------|-----------|
| `stitch_designs/kinetic_harvest_1/DESIGN.md` | **Kinetic Harvest** tokens: coach-orange `#F26B38`, protein-teal `#2D6A4F`, warm-sun `#FFD54F`, paper `#FBF9F4`, Hanken Grotesk + Inter |
| `stitch_designs/kinetic_harvest_2/DESIGN.md` | Alternate Kinetic Harvest token set |
| `stitch_designs/nutriscope_ai/DESIGN.md` | Brand / product design notes |
| `CANONICAL_SCREENS.md` | Canonical v1 screen → folder mapping |
| `DESIGN_FLOWS.md` | Product brief: capabilities, business rules, monetization states |

### Canonical v1 screens (`CANONICAL_SCREENS.md`)

| Folder | Screen / flow | Key UI elements | Expected flow | Backend / Pro notes |
|--------|---------------|-----------------|---------------|---------------------|
| `auth_welcome` | Welcome / value prop | Hero image, Get Started, sign-in link | First open → value → onboarding | Guest path supported |
| `sign_in` | Sign in | Email/password, Apple, forgot password | Returning user | Supabase auth implied |
| `sign_up_trial_start` | Sign up + trial | Account creation, trial CTA | Optional during onboarding | 7-day trial, StoreKit |
| `account_choice` | Account / monetization fork | Try Pro 7 days / Create account / Continue free | Post-value decision | Trial + guest + account |
| `onboarding_goals_redesign` | Goal setup | Fitness goal cards | Onboarding step 1 | Writes profile targets |
| `onboarding_profile_redesign` | Profile / body stats | Age, height, weight, activity | Onboarding step 2 | BMR/TDEE calculation |
| `onboarding_target_redesign` | Protein target | Hero protein number, calorie range | Onboarding step 3 | Local profile |
| `onboarding_calculating_your_plan` | Calculating animation | Loading / finalizing | Optional between profile → target | Local calc only |
| `onboarding_preferences` | Diet preferences | Multi-select diet chips | Optional | Feeds AI context |
| `stitch_proteinplate_ai_tracker (5)` | Today dashboard | Streak, protein arc, Fix My Day | Home tab | Coach tips; HealthKit optional |
| `ai_meal_scan` | Camera scan | Camera viewfinder, capture | Scan entry | AI analysis backend |
| `manual_meal_log` | Text / voice log | Text field, voice button | Alternative scan input | Whisper / text analysis |
| `first_scan_tutorial` | First scan overlay | Tips for good photos | First-time scan | Local flag |
| `food_database_search` | USDA search | Search, high-protein filters | Scan sub-flow | USDA API |
| `meal_scan_results_coaching` | Meal result | Macro ranges, confidence, advice | Post-analysis confirm | AI response |
| `post_scan_success_with_celebration` | Post-save celebration | Confetti / success | After logging meal | Local save |
| `coach_chat_2` | Coach chat | Chat bubbles, protein context | Pro tab | OpenAI coach |
| `meal_history_redesign` | Meals history | Period filters, meal cards | Meals tab | SwiftData |
| `user_profile_settings` | Profile hub | Goals, tools, account links | Profile tab | Settings sync later |
| `weekly_progress_report` | Weekly report | Charts, highlights | Profile → Tools | Local aggregation |
| `weight_tracking_trends` | Weight tracking | Log + trend chart | Goals settings embed | Local SwiftData |
| `recipe_macro_calculator` | Recipe calculator | Ingredient macros | Profile → Tools | Local calc |
| `protein_first_grocery_list` | Grocery list | Categories, protein-gap suggestions | Profile → Tools | Local list |
| `reminders_notifications` | Reminders | Meal / protein nudges | Profile → Tools | Local notifications |
| `nutriscope_pro_paywall` | Pro paywall | Feature list, monthly/yearly, trial CTA | Monetization moment | StoreKit prices |
| `stitch_proteinplate_ai_tracker` | Scan quota exhausted | 5/5 used, reset countdown | Quota gate | Free tier rule |
| `stitch_proteinplate_ai_tracker (1)` | Scan failed (PNG) | Retry / describe / database | Error recovery | Re-scan |
| `stitch_proteinplate_ai_tracker (4)` | Voice listening | Waveform, transcribing | Voice input overlay | Whisper |
| `stitch_proteinplate_ai_tracker (3)` | Data & privacy | Export, wipe cache, delete | Account settings | GDPR-style |
| `stitch_proteinplate_ai_tracker (6)` | Camera permission | Pre-prompt explainer | Before camera | iOS permission |
| `stitch_proteinplate_ai_tracker (7)` | Saved meals empty | Empty state illustration | Meals → Saved | Pro filter |
| `trial_ending_soon` | Trial ending | Reminder before trial ends | Subscription lifecycle | StoreKit trial |
| `subscription_success` | Subscription success | Celebration, save progress CTA | Post-purchase | Optional signup |
| `manage_subscription` | Manage / cancel | Cancel flow, restore | Profile → account | StoreKit |
| `confirmation_dialogs` | Dialog patterns | Confirm / destructive | Cross-cutting | — |
| `toast_notifications` | Toast patterns | Success / error toasts | Cross-cutting | — |

### v2 / later designs (canonical marks as not v1)

| Folder | Screen |
|--------|--------|
| `insights_trends` | Deep nutrition charts |
| `tomorrow_s_protein_plan` | Tomorrow meal prep plan |
| `social_meal_estimator_ai` | Social / shared meal estimator |

### Additional `stitch_designs/` variants (non-canonical duplicates)

Multiple alternate onboarding welcomes, goals, profiles, paywalls (`nutriscope_pro`, `nutriscope_pro_final`, `proteinplate_pro_updated`), coach variants (`coach_chat_1`, `coach_advice`, `coach_course_correction`), meal history variants, dashboard variants (`dashboard_today`, `dashboard_today_high_impact`, `daily_tracker`). These are design explorations; canonical picks are in `CANONICAL_SCREENS.md`.

### `stitch_proteinplate_ai_tracker*` (root)

| Folder | Title (from HTML) | Purpose |
|--------|-------------------|---------|
| `stitch_proteinplate_ai_tracker` | Scan Limit Reached | Quota paywall |
| `stitch_proteinplate_ai_tracker (1)` | DESIGN.md only (PNG asset) | Scan failed illustration |
| `stitch_proteinplate_ai_tracker (3)` | Data & Privacy | Export / delete |
| `stitch_proteinplate_ai_tracker (4)` | Voice Input | Listening overlay |
| `stitch_proteinplate_ai_tracker (5)` | Today | Dashboard |
| `stitch_proteinplate_ai_tracker (6)` | Camera Permission | Pre-prompt |
| `stitch_proteinplate_ai_tracker (7)` | Saved Meals empty | Empty state |
| `stitch_proteinplate_ai_tracker (8)` | Grocery List | Alt grocery design |

`other pages/` contains duplicates of tracker (1)–(4) HTML/DESIGN files plus a generic `code.html`.

---

## 4. Design Template vs Implementation Comparison

| Design/template file | Expected screen/feature | Implemented? | Matching file(s) | Missing pieces | Mismatch notes | Priority |
|----------------------|-------------------------|--------------|------------------|----------------|---------------|----------|
| `auth_welcome` | Welcome / hero | Yes (partial) | `AuthFlowView` welcomePage | Standalone `WelcomeView` | Inline view, copy/layout differs from HTML | P2 |
| `sign_in` | Sign in | Yes | `SignInView.swift` | — | Functional match | — |
| `sign_up_trial_start` | Sign up | Yes | `SignUpView.swift` | Trial CTA on signup screen | Trial starts at paywall, not signup | P2 |
| `account_choice` | Account / trial / free fork | **No** | — | Dedicated screen | Guest path implicit after first meal | P1 |
| `onboarding_goals_redesign` | Goal setup | Yes | `AuthFlowView` goalPage | — | Uses `KineticGoalCard` | — |
| `onboarding_profile_redesign` | Body stats | Yes (merged) | `AuthFlowView` targetPage `profileCalibrationSection` | Separate profile step | Profile merged into target step, not step 2 alone | P2 |
| `onboarding_target_redesign` | Protein target hero | Yes | `AuthFlowView` targetPage, `OnboardingTargetHero` | — | "Target Locked" copy vs design | P3 |
| `onboarding_calculating_your_plan` | Calculating animation | Partial | `OnboardingChrome` `showsFinalizing` on target | Full-screen animation | Minimal finalizing indicator only | P3 |
| `onboarding_preferences` | Diet prefs | Yes | `AuthFlowView` dietPage | — | — | — |
| `stitch_proteinplate_ai_tracker (5)` | Today dashboard | Yes | `TodayView.swift` | Fix My Day card parity | Core elements present; visual polish may differ | P2 |
| `ai_meal_scan` | Camera scan | Yes | `ScanMealView.swift` | — | Also supports photo picker, text, voice | — |
| `manual_meal_log` | Text log | Yes | `ScanMealView.swift` text mode | — | Combined in one scan sheet | P3 |
| `first_scan_tutorial` | First scan tutorial | Yes | `FirstScanTutorialView.swift` | — | — | — |
| `food_database_search` | Food search | Yes | `FoodSearchView.swift` | — | Embedded in scan flow | — |
| `meal_scan_results_coaching` | Meal result | Yes | `MealResultView.swift` | — | Follow-ups via `FollowUpQuestionsView` | — |
| `post_scan_success_with_celebration` | Post-save success | Yes | `PostScanSuccessView.swift` | — | — | — |
| `coach_chat_2` | Coach chat | Yes | `CoachView.swift` | — | Pro-gated | — |
| `meal_history_redesign` | Meals history | Yes | `MealsView.swift` | Monthly heatmap view | Week/month periods; no monthly grid from design | P2 |
| `user_profile_settings` | Profile hub | Yes | `ProfileView.swift` | — | — | — |
| `weekly_progress_report` | Weekly report | Yes | `WeeklyReportView.swift` | — | Free (not Pro-gated) | P3 |
| `weight_tracking_trends` | Weight tracking | Yes | `WeightTrackingSection.swift` in goals | Standalone nav screen | Embedded in goals settings | P3 |
| `recipe_macro_calculator` | Recipe calculator | Yes | `RecipeCalculatorView.swift` | — | Free | — |
| `protein_first_grocery_list` | Grocery list | Yes | `GroceryListView.swift` | Premium gap-suggestion card | Basic list; premium design has protein-gap hero | P2 |
| `protein_first_grocery_list_premium` | Premium grocery UX | Partial | `GroceryListView.swift` | Protein-gap hero card | Not Pro-gated in code | P2 |
| `reminders_notifications` | Reminders | Yes | `ReminderSettingsView.swift` | — | — | — |
| `nutriscope_pro_paywall` | Pro paywall | Yes | `PaywallView.swift` | — | Uses StoreKit `displayPrice` | — |
| `stitch_proteinplate_ai_tracker` | Scan quota exhausted | Yes | `ScanQuotaPaywallView.swift` | — | Reset countdown implemented | — |
| `stitch_proteinplate_ai_tracker (1)` | Scan failed full screen | Yes | `ScanFailedView.swift` | PNG-only design asset | Retry/describe/database actions present | P2 |
| `stitch_proteinplate_ai_tracker (4)` | Voice listening | Yes | `VoiceListeningOverlay.swift` | — | — | — |
| `stitch_proteinplate_ai_tracker (3)` | Data & privacy | Yes | `DataPrivacyView.swift` | — | Reachable via Profile → Account | — |
| `stitch_proteinplate_ai_tracker (6)` | Camera permission | Yes | `CameraPermissionPromptView.swift` | — | — | — |
| `stitch_proteinplate_ai_tracker (7)` | Saved meals empty | Partial | `MealsView.swift` empty state | Dedicated empty illustration screen | Asset `saved-meals-empty` exists | P3 |
| `trial_ending_soon` | Trial ending reminder | **No** | — | Screen + notification logic | — | P2 |
| `subscription_success` | Post-purchase success | Yes | `SubscriptionSuccessView.swift` | — | Prompts save progress | — |
| `manage_subscription` | Manage subscription | Yes | `ManageSubscriptionView.swift` | — | — | — |
| `confirmation_dialogs` | Dialog patterns | Partial | SwiftUI `.confirmationDialog` | Styled toast/dialog components | Native dialogs only | P3 |
| `toast_notifications` | Toasts | Partial | Inline `Text` messages | Dedicated toast component | — | P3 |
| `insights_trends` (v2) | Insights charts | Yes | `InsightsTrendsView.swift` | — | Implemented despite v2 label; Pro-gated | P3 |
| `tomorrow_s_protein_plan` (v2) | Tomorrow plan | Yes | `TomorrowProteinPlanView.swift` | — | Pro-gated; local calculator not edge fn | P2 |
| `social_meal_estimator_ai` (v2) | Social estimator | **No** | — | Entire feature | — | P3 |
| Kinetic Harvest design system | Global tokens / typography | Partial | `AppTheme.swift`, `AppTypography.swift`, `KineticComponents.swift` | Full MD3 token parity | Core colors/fonts match | P2 |

---

## 5. Full Pages/Screens Inventory

| Screen/page | File | Exists? | Reachable? | Entry point | Primary CTA | Secondary CTA | Backend dependency | Pro/free behavior | Design template match | Status | Notes |
|-------------|------|---------|------------|-------------|-------------|---------------|-------------------|---------------------|------------------------|--------|-------|
| Splash | `SplashView.swift` | Yes | Yes | App launch → `AuthFlowView` | Auto-advance | — | None | Free | Partial | OK | Animated splash |
| Welcome | `AuthFlowView` welcomePage | Yes | Yes | After splash | Get Started | I already have an account | None | Free | Partial | OK | Not separate file |
| Onboarding intro (×3) | `OnboardingIntroView.swift` | Yes | Yes | Welcome → intro | Continue | Back | None | Free | Partial | OK | Product carousel |
| Goal setup | `AuthFlowView` goalPage | Yes | Yes | Intro → goals | Continue | Back | None | Free | Yes | OK | |
| Diet setup | `AuthFlowView` dietPage | Yes | Yes | Goals → diet | Continue | Back | None | Free | Yes | OK | |
| Protein target setup | `AuthFlowView` targetPage | Yes | Yes | Diet → target | Add first meal | Back | None | Free | Partial | OK | Includes profile fields |
| Add first meal | `AddFirstMealView.swift` | Yes | Yes | Target → firstMeal | Scan photo / Type meal | Back | Scan needs Supabase JWT | Free (quota) | Yes | OK | |
| Scan meal | `ScanMealView.swift` | Yes | Yes | Tab scan / onboarding / Today | Analyze | Camera, voice, search | `analyze-meal` edge fn | Quota / Pro | Yes | Conditional | Needs backend config |
| Meal result | `MealResultView.swift` | Yes | Yes | After analysis | Save meal | Follow-ups, quick log | None (post-analysis) | Quick log = Pro | Yes | OK | |
| Post-scan success | `PostScanSuccessView.swift` | Yes | Yes | After save (non-onboarding) | Continue | — | None | Free | Yes | OK | |
| Scan failed | `ScanFailedView.swift` | Yes | Yes | Scan error path | Retry | Describe / database | Retry needs backend | Free | Partial | OK | |
| Follow-up questions | `FollowUpQuestionsView.swift` | Yes | Yes | Low-confidence result | Submit answers | — | Re-analysis backend | Free | Yes | OK | |
| First scan tutorial | `FirstScanTutorialView.swift` | Yes | Yes | First scan overlay | Dismiss | — | None | Free | Yes | OK | |
| Camera permission | `CameraPermissionPromptView.swift` | Yes | Yes | Before camera | Open Settings | Not now | None | Free | Yes | OK | |
| Voice listening | `VoiceListeningOverlay.swift` | Yes | Yes | Scan voice mode | — | Cancel | Whisper (device OpenAI) | Free | Yes | Risky | Release needs API key |
| Food search | `FoodSearchView.swift` | Yes | Yes | Scan → database | Select food | Search | USDA API (client) | Free | Yes | OK | |
| Dashboard / Today | `TodayView.swift` | Yes | Yes | Today tab | Scan (via tab) | Coach tip load | Coach tip = OpenAI device | Tomorrow link = Pro | Partial | OK | |
| Meals / history | `MealsView.swift` | Yes | Yes | Meals tab | Filter meals | Open meal detail | None | Saved filter = Pro | Partial | OK | |
| Coach | `CoachView.swift` | Yes | Yes | Coach tab | Send message | — | OpenAI device | Pro only | Yes | Risky | Gate + API key |
| Insights / trends | `InsightsTrendsView.swift` | Yes | Yes | Profile → Tools | — | — | Local calc | Pro only | Yes | OK | |
| Saved meals | `MealsView` filter + cards | Yes | Yes | Meals → Saved filter | Re-log | — | None | Pro to open filter | Partial | OK | |
| Tomorrow plan | `TomorrowProteinPlanView.swift` | Yes | Yes | Profile / Today link | — | — | Local `TomorrowPlanCalculator` | Pro only | Partial | OK | No edge fn |
| Weekly report | `WeeklyReportView.swift` | Yes | Yes | Profile → Tools | — | — | Local | Free | Yes | OK | |
| Recipe calculator | `RecipeCalculatorView.swift` | Yes | Yes | Profile → Tools | Calculate | — | Local | Free | Yes | OK | |
| Grocery list | `GroceryListView.swift` | Yes | Yes | Profile → Tools | Add/check items | — | Local | Free | Partial | OK | |
| Profile / settings | `ProfileView.swift` | Yes | Yes | Profile tab | Navigate tools | Upgrade | None | Mixed | Yes | OK | |
| Goals settings | `ProfileGoalsSettingsView.swift` | Yes | Yes | Profile → goals rows | Save | HealthKit | Local | Free | Partial | OK | Includes weight |
| Account settings | `ProfileAccountView.swift` | Yes | Yes | Profile → Account | Sign in / upgrade | Data privacy | Supabase optional | Mixed | Partial | OK | |
| Reminders | `ReminderSettingsView.swift` | Yes | Yes | Profile → Tools | Toggle reminders | — | Local notifications | Free | Yes | OK | |
| Data / privacy | `DataPrivacyView.swift` | Yes | Yes | Profile → Account → Data | Export / delete | Legal links | Delete uses Supabase if signed in | Free | Yes | OK | |
| Subscription paywall | `PaywallView.swift` | Yes | Yes | Sheet / upgrade CTAs | Subscribe / trial | Restore, continue free | StoreKit | Upsell | Yes | OK | |
| Scan quota paywall | `ScanQuotaPaywallView.swift` | Yes | Yes | Quota exhausted | Upgrade | Continue free | StoreKit | Upsell | Yes | OK | |
| Subscription success | `SubscriptionSuccessView.swift` | Yes | Yes | Post-purchase sheet | Continue | Skip signup | StoreKit | Pro | Yes | OK | |
| Save progress / signup | `SaveProgressView.swift` | Yes | Yes | Post-success / account | Apple / email | Skip | Supabase auth | Pro context | Partial | Misleading | iCloud icon; no data upload |
| Manage subscription | `ManageSubscriptionView.swift` | Yes | Yes | Profile (Pro) / Account | Restore / cancel info | — | StoreKit | Pro | Yes | OK | |
| Sign in | `SignInView.swift` | Yes | Yes | Welcome / account | Sign in | Apple, forgot password | Supabase + local | Free | Yes | OK | |
| Sign up | `SignUpView.swift` | Yes | Yes | Sign in flow / save progress | Create account | Apple | Supabase + local | Free | Partial | OK | |
| Reset password | `ResetPasswordView.swift` | Yes | Yes | Sign in → forgot | Update password | Back | **Local only** | Free | Partial | Broken | No Supabase email reset |
| Account choice | — | **No** | No | — | — | — | — | — | No | Missing | Design only |
| Trial ending soon | — | **No** | No | — | — | — | StoreKit trial | Pro | No | Missing | Design only |
| Social meal estimator | — | **No** | No | — | — | — | AI backend | — | No | Missing | v2 design |
| Mic permission prompt | `KineticPermissionPromptView` | Yes | Conditional | Speech if needed | Allow | — | None | Free | Partial | OK | Generic component |
| Notification permission | `KineticPermissionPromptView` | Yes | Conditional | Reminders setup | Allow | — | None | Free | Partial | OK | |
| Widget | `ProteinWidget.swift` | Yes | Yes | Home screen | — | — | App Group local | Free | N/A | OK | Extension target |

---

## 6. Missing Pages / Screens

| Missing screen | Required by design? | Required by app flow? | Required by App Store? | Expected location | Backend needed? | Priority | Notes |
|----------------|--------------------|-----------------------|------------------------|-------------------|-----------------|----------|-------|
| Account choice | Yes (`account_choice`) | Implicit guest works without it | No | After welcome or post-target | Auth optional | P1 | Design shows trial/account/free fork |
| Trial ending soon | Yes (`trial_ending_soon`) | Only if ASC intro offer configured | Recommended | Push / modal before renewal | StoreKit subscription state | P2 | No Swift screen |
| Social meal estimator | Yes (v2 design) | No | No | Scan or tools | AI edge fn | P3 | Explicitly v2 in canonical |
| Dedicated Welcome view file | Yes (`auth_welcome`) | No — inline works | No | Auth flow | No | P3 | Cosmetic / structure |
| Onboarding calculating screen | Optional canonical | No | No | Between profile and target | No | P3 | Chrome hint only |
| Supabase password reset email flow | No dedicated design | Yes — forgot password exists | Yes (if email auth offered) | `ResetPasswordView` | Supabase Auth email | P1 | Currently local-only |
| Cloud sync UI | Implied by Save Progress copy | No for local-first MVP | No | Save progress / settings | Full sync backend | P1 | Misleading UX today |
| Server-side scan quota UI | No | No | No | N/A | Edge fn + DB | P3 | Client-side quota only |

---

## 7. End-to-End Flow Audit

### Fresh install flow

| Flow | Current path | Works? | Broken step | File(s) involved | Backend needed? | Priority | Notes |
|------|--------------|--------|-------------|------------------|-----------------|----------|-------|
| Splash → Welcome | `splash` → `welcome` | Yes | — | `SplashView`, `AuthFlowView` | No | — | |
| Welcome → Onboarding intro | `introTrackFast` → `introProteinProgress` → `introSmartMeals` | Yes | — | `OnboardingIntroView` | No | — | |
| Intro → Goal → Diet → Target | `goals` → `diet` → `target` | Yes | — | `AuthFlowView` | No | — | Persists `UserSettings` |
| Target → First meal | `firstMeal` → fullscreen `ScanMealView` | Partial | Scan analysis in release | `AddFirstMealView`, `ScanMealView` | Supabase JWT + edge fn | P0 | Guest needs anonymous auth |
| First meal → Dashboard | `finishOnboardingAfterFirstMeal` | Yes | — | `AuthFlowView` | No | — | Sets guest if unsigned |
| Resume incomplete onboarding | Profile exists → `firstMeal` | Yes | — | `AuthFlowView.resumeFlowIfNeeded` | No | — | |

### Returning user flows

| Flow | Current path | Works? | Broken step | File(s) | Backend? | Priority | Notes |
|------|--------------|--------|-------------|---------|----------|----------|-------|
| Onboarding completed | `MainTabView` directly | Yes | — | `RootView` | No | — | `hasCompletedOnboarding` flag |
| Onboarding incomplete + profile | Jump to `firstMeal` | Yes | — | `AuthFlowView` | No | — | |
| Guest user | `GuestModeManager.isGuest` | Partial | Cloud identity weak | Multiple | Anonymous Supabase | P0 | Auth policy conflict |
| Signed-in user | Local + non-anonymous Supabase | Partial | No sync | `AuthSessionManager` | Supabase | P1 | |
| Subscribed user | `subscriptionManager.isSubscribed` | Yes* | *Needs ASC products | `SubscriptionManager` | StoreKit | P1 | Simulator may lack products |
| Unsubscribed user | Quota + Pro gates | Yes | — | `ScanQuotaManager`, gates | No | — | |

### Subscription flow

| Flow | Current path | Works? | Broken step | File(s) | Backend? | Priority | Notes |
|------|--------------|--------|-------------|---------|----------|----------|-------|
| Free user hits premium feature | `ProFeatureGate` → paywall sheet | Yes | — | `ProFeatureGate`, `PaywallView` | StoreKit | — | |
| Free user exhausts scans | `presentScanIfAllowed` → `scanQuota` sheet | Yes | — | `ScanQuotaPaywallView` | No | — | 5/week client-side |
| Paywall monthly/yearly | `SubscriptionPlansSection` | Yes* | Products may not load | `SubscriptionManager` | StoreKit | P2 | Fallback price "—" |
| StoreKit purchase | `purchase()` → `completePurchaseSuccess` | Yes* | ASC setup required | `SubscriptionManager` | StoreKit | P1 | |
| Success screen | `subscriptionSuccess` sheet | Yes | — | `SubscriptionSuccessView` | No | — | |
| Optional save progress | `promptSaveProgressIfNeeded` | Partial | No data upload | `SaveProgressView` | Supabase auth only | P1 | |
| Skip signup | Skip buttons present | Yes | — | `SaveProgressView`, success view | No | — | |
| Restore purchase | `restore()` + `AppStore.sync` | Yes* | ASC required | `SubscriptionManager` | StoreKit | — | |
| Cancelled purchase | `userCancelled` — no unlock | Yes | — | `SubscriptionManager` | StoreKit | — | |
| Expired subscription | `refreshEntitlements` clears `isSubscribed` | Yes | — | `SubscriptionManager` | StoreKit | — | |
| Trial ending reminder | — | **No** | No screen | — | StoreKit | P2 | Design exists |

### Auth flow

| Flow | Current path | Works? | Broken step | File(s) | Backend? | Priority | Notes |
|------|--------------|--------|-------------|---------|----------|----------|-------|
| Anonymous / guest mode | Onboarding without sign-in → `isGuest=true` | Partial | Anonymous JWT if Supabase on | `GuestModeManager`, `BackendAuthBootstrap` | Anonymous auth | P0 | |
| Email signup | Local + Supabase signup | Partial | No profile row sync | `SignUpView`, `SupabaseAuthClient` | Supabase | P1 | |
| Apple signup/sign-in | `SignInWithAppleButton` → Supabase id_token | Partial | ASC + Supabase Apple provider | `SignInWithAppleButton` | Supabase | P1 | |
| Login | Local + Supabase password grant | Partial | Same as signup | `SignInView` | Supabase | P1 | |
| Logout | `AuthSessionManager.signOut` | Partial | May leave Supabase session | `ProfileView` | Optional | P2 | |
| Guest → account conversion | `linkEmailPassword` / `linkAppleIdentity` | Partial | Untested E2E | `SupabaseAuthClient` | Supabase | P1 | |
| Delete account | `AccountDeletionService` | Partial | Remote delete needs user JWT + dashboard setting | `DataPrivacyView`, `ProfileAccountView` | Supabase DELETE user | P1 | |

---

## 8. Frontend Implementation Audit

### Implemented frontend capabilities

| Capability | Implementation | Notes |
|------------|----------------|-------|
| Multi-step onboarding | `AuthFlowView` state machine | 12 `AuthFlowStep` values |
| Custom tab bar + center scan | `MainTabView.kineticTabBar` | Scan opens sheet, not tab content |
| Photo / text / voice / search logging | `ScanMealView` | Unified scan sheet |
| Macro ranges + confidence | `MealAnalysis`, `MealResultView` | Range display, `ConfidenceBadge` |
| Follow-up questions | `FollowUpQuestionsView` | Low-confidence path |
| Daily protein progress | `ProteinProgressCard`, `TodayView` | |
| Coach tips on Today | `OpenAICoachService.generateCoachTip` | Device OpenAI |
| Meal history + filters | `MealsView` | Period + filter chips |
| Saved meals / quick re-log | `SavedMeal` model, `MealsView` | Pro-gated |
| Weight tracking | `WeightLog`, `WeightTrackingSection` | Chart in goals |
| Grocery list | `GroceryItem`, `GroceryListView` | Local only |
| Recipe calculator | `RecipeCalculatorView` | Local macro math |
| Weekly report | `WeeklyReportView`, `WeeklyReportCalculator` | |
| Insights charts | `InsightsTrendsView` | Pro-gated |
| Tomorrow plan | `TomorrowProteinPlanView` | Pro-gated, local calculator |
| Reminders | `NotificationManager`, `ReminderSettingsView` | |
| HealthKit snapshot | `HealthKitService` | Workouts on Today |
| Home screen widget | `ProteinWidget`, `WidgetDataStore` | App Group |
| Data export | `DataExportService` in `WeeklyReportCalculator` | JSON share sheet |
| Offline demo mode | `MockMealAnalysisService` | `-OfflineDemo` launch arg |
| Kinetic design system | `KineticComponents`, `AppTheme` | Large shared component file |

### Frontend gaps

- No dedicated **account choice** monetization screen.
- No **trial ending** UX.
- **README** still describes direct OpenAI scans as primary path (stale vs `doc/BACKEND_SETUP.md`).
- **Grocery premium** design not fully implemented; feature not Pro-gated.
- **Monthly meal heatmap** from `meal_history_monthly_view` design not built.

---

## 9. Backend/Supabase Implementation Audit

| Backend feature | Implemented? | File(s) | Frontend connected? | DB table/migration exists? | RLS exists? | Production ready? | Missing pieces | Priority |
|-----------------|--------------|---------|---------------------|---------------------------|-------------|-------------------|----------------|----------|
| Supabase URL/key config | Yes | `BackendConfig.swift` | Yes | N/A | N/A | Partial | Not in repo for release | P0 |
| GoTrue REST client | Yes | `SupabaseAuthClient.swift` | Yes | N/A | N/A | Partial | No Swift SDK | — |
| Anonymous auth | Code yes, policy no | `SupabaseAuthClient.signInAnonymously`, `config.toml` | Yes | N/A | N/A | **No** | `enable_anonymous_sign_ins = false` | P0 |
| Email auth | Yes | `SupabaseAuthClient` | Yes | `auth.users` | N/A | Partial | Dual local layer | P1 |
| Apple auth | Yes | `SignInWithAppleButton`, `SupabaseAuthClient` | Yes | `auth.users` | N/A | Partial | Needs ASC + Supabase provider | P1 |
| Account linking | Yes | `linkEmailPassword`, `linkAppleIdentity` | Yes | N/A | N/A | Partial | Untested E2E | P1 |
| Session storage | Yes | UserDefaults `supabaseSession` | Yes | N/A | N/A | OK | | — |
| Session refresh | Yes | `refresh(session:)` | Yes | N/A | N/A | OK | | — |
| `ios_user_profiles` table | Migration only | `001_ios_user_profiles.sql` | **No** | Yes | Yes (select/insert/update) | No | iOS never writes | P1 |
| Meal records sync | No | — | No | No | No | No | Local SwiftData only | P1 |
| Saved meals sync | No | — | No | No | No | No | | P1 |
| Weight logs sync | No | — | No | No | No | No | | P2 |
| Grocery sync | No | — | No | No | No | No | | P2 |
| Scan quota (server) | No | `ScanQuotaManager` local | No | No | No | No | Client-only 5/week | P2 |
| Subscription entitlement server | No | `SubscriptionManager` local | Yes | No | No | No | No receipt validation | P2 |
| AI meal analysis edge fn | Yes | `analyze-meal/index.ts` | Yes | N/A | JWT verify | Partial | Deploy + secrets | P0 |
| Coach edge fn | No | `OpenAICoachService.swift` | Yes (device) | No | No | No | Direct OpenAI | P0 |
| Tomorrow plan edge fn | No | `TomorrowPlanCalculator.swift` | Yes (local) | No | No | N/A | Local only | P3 |
| Whisper / transcription | No | `WhisperTranscriptionService.swift` | Yes (device) | No | No | No | Direct OpenAI | P0 |
| Delete account server | Partial | `SupabaseAuthClient.deleteCurrentUser` | Yes | Cascade on `auth.users` | N/A | Partial | Dashboard user-delete setting | P1 |
| Data export | Local only | `DataExportService` | Yes | N/A | N/A | OK | No server export | — |
| OpenAI key server-side only | Partial | Edge fn for scans only | Scans yes | N/A | N/A | No | Coach/whisper on device | P0 |
| No production OpenAI in iOS | Partial | `MealAnalysisServiceFactory` | Release scans OK | N/A | N/A | No | Coach/whisper/tips fail | P0 |

### Supabase config conflict (critical)

| Source | Anonymous auth |
|--------|----------------|
| `supabase/config.toml` | `enable_anonymous_sign_ins = false` |
| `doc/BACKEND_SETUP.md` | "Anonymous → OFF" |
| `BackendAuthBootstrap.swift` | Calls `signInAnonymously()` for guest JWT |
| `MealAnalysisError.unauthorized` | Tells user to enable Anonymous sign-ins |

**Resolution required before production:** Enable anonymous sign-ins in Supabase dashboard **or** remove anonymous bootstrap and require linked accounts before any scan.

---

## 10. StoreKit/Subscription Audit

| StoreKit item | Implemented? | File(s) | Correct? | Missing/issue | Priority |
|---------------|--------------|---------|----------|---------------|----------|
| Monthly product ID `com.nutriscopeai.pro.monthly` | Yes | `SubscriptionManager.swift` | Yes | ASC must match | P1 |
| Yearly product ID `com.nutriscopeai.pro.yearly` | Yes | `SubscriptionManager.swift` | Yes | ASC must match | P1 |
| Products loaded via StoreKit | Yes | `loadProducts()` | Yes | Fails silently to error message | — |
| Paywall uses `Product.displayPrice` | Yes | `SubscriptionPlansSection` | Yes | Fallback `"—"` when unloaded | P2 |
| Intro offer UI gated on real offer | Yes | `hasIntroductoryOffer`, `primaryTitle` | Yes | — | — |
| Purchase flow | Yes | `purchase()` | Yes | Needs ASC products | P1 |
| Entitlements refresh after purchase | Yes | `refreshEntitlements`, `completePurchaseSuccess` | Yes | — | — |
| Restore purchase | Yes | `restore()`, `AppStore.sync` | Yes | — | — |
| Cancelled purchase does not unlock | Yes | `userCancelled` branch | Yes | — | — |
| Expired subscription removes Pro | Yes | `currentEntitlements` loop | Yes | — | — |
| Transaction updates observed | Yes | `Transaction.updates` in `startObservingTransactionUpdates` | Yes | — | — |
| Product load failure handled | Partial | `errorMessage` set | Partial | UI shows error; prices show "—" | P2 |
| Lifetime product | N/A | Not in code | Yes | Correctly absent | — |
| Paywall Terms / Privacy / Restore | Yes | `SubscriptionLegalLinksView` | Yes | URLs not verified live | P1 |
| Paywall close / continue free | Yes | `PaywallView` toolbar + `onContinueFree` | Yes | — | — |
| Trial ending screen | No | — | No | Design only | P2 |
| Server receipt validation | No | — | No | StoreKit 2 local only | P2 |

---

## 11. Free vs Pro Feature Matrix

| Feature | Free behavior | Pro behavior | Gate file/component | Paywall trigger | Implemented correctly? | Mismatch | Priority |
|---------|---------------|--------------|---------------------|-----------------|------------------------|----------|----------|
| AI meal scans | 5 per calendar week | Unlimited | `ScanQuotaManager`, `AppState.presentScanIfAllowed` | `ScanQuotaPaywallView` | Yes | Client-only quota | P2 |
| Scan quota display | Shown on Profile Pro card | "Active subscription" | `ProfileView.proSubtitle` | — | Yes | — | — |
| Coach tab | Lock prompt | Full chat | `ProFeatureGate` in `RootView` | `PaywallView` | Yes | Needs OpenAI in release | P0 |
| Insights & trends | Lock prompt | Full charts | `ProFeatureGate` in `ProfileView` | `PaywallView` | Yes | Canonical v2 but built | P3 |
| Tomorrow's plan | Lock prompt | Full plan | `ProFeatureGate`, `TodayView` link | `PaywallView` | Yes | — | — |
| Saved meals filter | Paywall on filter tap | Browse + re-log | `MealsView` filter handler | `presentPaywall()` | Yes | — | — |
| Save for quick log | Paywall button | Save bookmark | `MealResultView` | `presentPaywall()` | Yes | Matches paywall copy | — |
| Soft upsell after 4th scan | Paywall prompt flag | N/A | `MealResultView` `showPaywallPrompt` | After save | Yes | Per `DESIGN_FLOWS` | — |
| Recipe calculator | Full access | Full access | None | — | Yes | Free in code; paywall doesn't list as Pro | P3 |
| Grocery list | Full access | Full access | None | — | Yes | Premium design suggests upsell possible | P2 |
| Weekly report | Full access | Full access | None | — | Yes | Not Pro in code | P3 |
| Reminders | Full access | Full access | None | — | Yes | — | — |
| Follow-up questions | Available | Available | None | — | Yes | Not gated | — |
| Food database search | Available | Available | None | — | Yes | — | — |
| HealthKit card | Available | Available | None | — | Yes | — | — |
| Data export / delete | Available | Available | None | — | Yes | — | — |

**Paywall marketed Pro features** (`PaywallView`): Unlimited Scans, Smart Questions, Daily Coaching, Saved Meals — gates are **mostly consistent** except grocery/recipe/weekly report remain free.

---

## 12. Auth and Account Flow Audit

### Architecture

**Dual-layer auth:**
1. **Local:** `AuthSessionManager` — email/password in UserDefaults (`localUserAccount`, `localUserPassword`).
2. **Remote:** `SupabaseAuthClient` — GoTrue REST, JWT in UserDefaults (`supabaseSession`).

When `BackendConfig.isSupabaseConfigured`, `isSignedIn` requires **non-anonymous** Supabase session.

### Flow details

| Step | Behavior | Issue |
|------|----------|-------|
| Guest onboarding complete | `GuestModeManager.isGuest = true` if not signed in | OK for local-first |
| Backend bootstrap on launch | `BackendAuthBootstrap.ensureBackendSession()` | Creates anonymous JWT |
| Email sign-up | Local first, then Supabase signup / link | No `ios_user_profiles` insert |
| Apple sign-in | Native ASAuthorization → Supabase id_token | Entitlements configured |
| Sign-out | Clears local; sets guest if not subscribed | Supabase session clearing unclear |
| Save progress post-Pro | Auth only, iCloud metaphor | **No data sync** |
| Reset password | Updates local password in UserDefaults | **Not Supabase recovery email** |
| Delete account | Supabase DELETE + wipe SwiftData + reset onboarding | Requires linked non-anonymous user for remote delete |

### Files

- `NutriscopeAI/Services/AuthSessionManager.swift`
- `NutriscopeAI/Services/SupabaseAuthClient.swift`
- `NutriscopeAI/Services/BackendAuthBootstrap.swift`
- `NutriscopeAI/Services/GuestModeManager.swift`
- `NutriscopeAI/Services/AccountDeletionService.swift`
- `NutriscopeAI/Components/SignInWithAppleButton.swift`
- `NutriscopeAI/Views/Auth/*`

---

## 13. Data Sync Audit

| Data type | Local storage | Cloud table | Sync implemented? | Conflict strategy | Notes |
|-----------|---------------|-------------|-------------------|-------------------|-------|
| User profile / settings | `UserSettings` (SwiftData) | `ios_user_profiles` | **No** | N/A | Migration comment: "future cloud profile sync" |
| Meal records | `MealRecord` | None | **No** | N/A | Explicitly on-device |
| Saved meals | `SavedMeal` | None | **No** | N/A | |
| Weight logs | `WeightLog` | None | **No** | N/A | |
| Grocery items | `GroceryItem` | None | **No** | N/A | |
| Auth session | UserDefaults | `auth.users` | Auth only | N/A | Not profile data |
| Scan quota | UserDefaults | None | **No** | N/A | Client-side only |
| Widget data | App Group UserDefaults | None | **No** | N/A | Local |
| Subscription state | StoreKit + `SubscriptionManager` | None | **No** | N/A | Device-local entitlements |

**Source of truth today:** SwiftData on device. Supabase is used for **auth JWT** and **meal analysis proxy** only.

**Before cloud migration:** Define schema for meals/saved meals/weights; add RLS; build iOS PostgREST sync service; resolve anonymous → linked user ID mapping; add conflict resolution (last-write-wins or server authoritative).

---

## 14. Production Readiness Audit

| Production issue | File(s) | Risk | Priority | Recommended fix |
|------------------|---------|------|----------|-----------------|
| No production Supabase config in repo | `Backend.xcconfig` gitignored | Release scans fail | P0 | CI injects URL/key; document in BACKEND_SETUP |
| Anonymous auth policy conflict | `config.toml`, `BACKEND_SETUP.md`, `BackendAuthBootstrap` | Guest scans 401 | P0 | Align policy with implementation |
| Coach/Whisper/tips need device OpenAI key | `OpenAICoachService`, `WhisperTranscriptionService`, `TodayView` | Pro features broken in release | P0 | Edge functions for all AI |
| Developer settings in DEBUG only | `ProfileAccountView` `#if DEBUG` | Low | — | OK for release |
| Legal URLs not verified | `AppLegalLinks.swift` | App Store rejection | P1 | Host live terms/privacy at nutriscopeai.app |
| Save Progress misleading copy | `SaveProgressView` | User trust / review | P1 | Remove iCloud metaphor or implement sync |
| Local-only password reset | `ResetPasswordView`, `AuthSessionManager.resetPassword` | Security / UX | P1 | Supabase `resetPasswordForEmail` |
| Hardcoded paywall prices | Uses StoreKit — fallback `"—"` | Review confusion | P2 | Hide prices until products load |
| README describes direct OpenAI scans | `README.md` | Dev confusion | P3 | Update to match BACKEND_SETUP |
| No automated tests | Xcode project | Regression risk | P2 | Add XCTest for quota, auth, calculators |
| `ios_user_profiles` unused | Migration + no iOS client | Wasted schema | P2 | Implement upsert or defer migration |
| FAKETEAMID in simulator build | Xcode signing | Device deploy only | P2 | Set real team for TestFlight |
| No server receipt validation | — | Fraud / restore edge cases | P2 | Optional App Store Server API |
| USDA API key client-side | `USDAFoodSearchService` | Key exposure if embedded | P2 | Proxy via edge fn |

---

## 15. Build/Test Results

### Build command

```bash
cd /Users/krishnasathvikmantripragada/proteinplate-ai
xcodebuild -scheme NutriscopeAI -destination 'platform=iOS Simulator,name=iPhone 17' build
```

(Initial attempt with `iPhone 16` failed — simulator not installed. `iPhone 17` on iOS 26.3.1 succeeded.)

### Build result

**BUILD SUCCEEDED** (Debug, iphonesimulator, deployment target iOS 17.0)

### Warnings

| Warning | Source |
|---------|--------|
| `Metadata extraction skipped. No AppIntents.framework dependency found.` | `appintentsmetadataprocessor` — informational |

No Swift compiler warnings observed in build tail output.

### Errors

None (on successful build).

### Tests found

**None.** No test target in `NutriscopeAI.xcodeproj`.

### Tests run

**Not applicable** — no test bundle.

### Missing critical tests

- `ScanQuotaManager` week rollover and 5-scan limit
- `SubscriptionManager` entitlement parsing (mock StoreKit)
- `PersonalizedTargetCalculator` / `WeeklyReportCalculator`
- `MealAnalysisServiceFactory` release vs debug routing
- `SupabaseAuthClient` session refresh and anonymous link
- Onboarding state machine transitions in `AuthFlowView`

---

## 16. Dead Code / Unused Files

| Item | Path | Notes |
|------|------|-------|
| Duplicate tracker designs | `other pages/stitch_proteinplate_ai_tracker*` | Mirrors root tracker folders |
| Non-canonical onboarding variants | `stitch_designs/onboarding_welcome_*`, `onboarding_goals_*`, etc. | Design explorations superseded by canonical picks |
| Alternate paywalls | `nutriscope_pro`, `nutriscope_pro_final`, `proteinplate_pro_updated` | Only `nutriscope_pro_paywall` is canonical |
| Alternate dashboards | `dashboard_today`, `dashboard_today_high_impact`, `daily_tracker` | Canonical uses tracker `(5)` |
| `stitch_proteinplate_ai_tracker (1)` | PNG-only DESIGN.md | Asset reference; implemented as `ScanFailedView` |
| `generate_xcode_project.py` | Root | Project generator; not runtime |
| `MealAnalysisServiceFactory.make(hasProAccess:)` | Parameter unused | `_` ignored — dead parameter |
| Coach design variants | `coach_chat_1`, `coach_advice`, etc. | Not separate screens in app |

No unreachable SwiftUI **screen files** identified — all 39 view files are referenced from navigation graph or sheets.

---

## 17. Required Fixes by Priority

### P0 — Must fix before backend/testing

1. **Resolve anonymous Supabase auth conflict** — enable in dashboard or change guest scan architecture.
2. **Production Supabase configuration** — inject `SUPABASE_URL` + `SUPABASE_ANON_KEY` for Release builds (xcconfig / CI).
3. **Deploy `analyze-meal` edge function** with `OPENAI_API_KEY` secret to production project.
4. **Proxy coach, Whisper, and coach-tip OpenAI calls** through edge functions so Release does not need device API keys.
5. **Verify guest scan E2E** on Release build with production Supabase (anonymous or signed-in path).

### P1 — Must fix before TestFlight

1. **Implement or remove misleading Save Progress UX** — either sync data or change copy/icon.
2. **Supabase email password recovery** — replace local-only `ResetPasswordView` behavior.
3. **Account choice screen** or document intentional omission in onboarding UX review.
4. **App Store Connect** — create monthly/yearly subscriptions with IDs matching code; configure intro offer if advertising trial.
5. **Verify legal URLs** live at `https://nutriscopeai.app/terms` and `/privacy`.
6. **Profile upsert** to `ios_user_profiles` on sign-up/sign-in (minimal cloud identity).
7. **Delete account** — confirm Supabase "enable user deletion" + test E2E.
8. **Update README** to reflect Supabase proxy architecture.

### P2 — Should fix before App Store submission

1. **Trial ending soon** screen/notification if intro offer is configured.
2. **Server-side scan quota** (optional hardening) or document client-only as acceptable v1.
3. **Grocery list premium UX** alignment with `protein_first_grocery_list_premium` design.
4. **Paywall price loading state** — don't show "—" in production UI.
5. **Add XCTest coverage** for quota, calculators, auth edge cases.
6. **Sign-out** — explicitly clear Supabase session.
7. **Meal history monthly view** polish if design parity required.

### P3 — Nice-to-have / cleanup

1. Dedicated `WelcomeView` file matching `auth_welcome` design pixel-perfect.
2. Full `onboarding_calculating_your_plan` animation screen.
3. Toast notification component per design.
4. Social meal estimator (v2).
5. Remove unused `hasProAccess` parameter from `MealAnalysisServiceFactory.make`.
6. Consolidate duplicate `stitch_designs` / `other pages` folders in repo hygiene pass.

---

## 18. Recommended Next Implementation Order

1. **Backend alignment sprint (P0)**
   - Decide anonymous auth policy; update `config.toml` + `BACKEND_SETUP.md` + dashboard to match.
   - Create production Supabase project; run migration; deploy `analyze-meal`; configure iOS Release xcconfig.
   - Smoke-test: fresh install → guest → scan → meal result on Release build.

2. **AI proxy sprint (P0)**
   - Add `coach-chat` and `transcribe-audio` edge functions (or combined `ai-proxy`).
   - Route `OpenAICoachService`, `WhisperTranscriptionService`, and Today coach tips through proxy.
   - Confirm no `OPENAI_API_KEY` in Release binary or UserDefaults requirement.

3. **Auth & account hardening (P1)**
   - Supabase password reset email flow.
   - Profile upsert on auth events.
   - Fix Save Progress copy; optional account choice screen.
   - E2E delete account test.

4. **StoreKit & App Store prep (P1)**
   - ASC products + intro offer.
   - Legal pages live.
   - TestFlight internal build with production backend.

5. **Cloud sync design (post-TestFlight)**
   - Schema for meals, saved meals, weights.
   - iOS sync service + conflict policy.
   - Only after P0/P1 stable.

6. **Quality & polish (P2/P3)**
   - XCTest suite.
   - Trial ending UX.
   - Design parity pass on grocery, meal history monthly, welcome screen.

---

*End of audit. No code was modified during this review.*
