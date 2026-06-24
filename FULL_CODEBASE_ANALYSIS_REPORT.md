# NutriScope AI — Full Codebase Analysis Report

**Date:** 2026-06-24
**Branch audited:** `claude/clever-ramanujan-slz2it`
**Auditor scope:** Read-only audit of the actual implementation files (no fixes, no redesigns, no new screens).
**Build environment limitation:** This repo was audited on a **Linux container with no Xcode/Swift toolchain** (`xcodebuild`/`swift` not present). Therefore **no compile/build/test was executed**. All Swift findings are from static reading of source, not from a compiler. Where a claim depends on runtime/StoreKit/Supabase behavior, it is flagged as "needs device verification."

---

## What I could and could not verify

| Verifiable from source (done) | NOT verifiable here (needs device / Xcode / live backend) |
|---|---|
| File structure, screens, services, models | Whether project actually compiles (no toolchain) |
| Backend config, secret handling, edge function logic | StoreKit purchase/restore/trial on real Sandbox |
| Auth/session logic, RLS policy text, migration schema | Whether Supabase project has Anonymous auth enabled |
| Design tokens vs theme constants | Whether `DELETE /auth/v1/user` actually deletes (GoTrue config) |
| Pro gating, quota logic, flow wiring | Whether legal/support URLs are live |
| Presence/absence of files & tests | Pixel-level design parity (only HTML+PNG vs Swift code read) |

---

## 1. Executive Summary

NutriScope AI is a **substantially complete, well-architected protein-tracking iOS app** (101 Swift files, SwiftData persistence, Supabase edge-function backend, StoreKit 2 subscriptions, HealthKit, a widget, and a large redesigned UI surface). The frontend has clearly been through several redesign passes against the `new stitch designs/` prototypes and the design-token system is faithfully reflected in `AppTheme`/`AppTypography`. Core flows (onboarding → guest dashboard → scan → result → coach → paywall) are wired and present.

**However, it is NOT yet ready for App Store submission, and has at least two issues that block serious TestFlight testing of returning users.** The most important problems are in **auth and data-durability**, not design:

- **Email sign-in is effectively broken for returning users on a fresh install / new device** — the local-account guard runs before Supabase and rejects users whose credentials aren't already on the device.
- **"Cloud sync" is essentially non-existent.** Only a 5-field profile table exists; meals, saved meals, weight, and grocery data are **on-device only (SwiftData)**. "Save your progress" does not protect a user's history.
- **Account deletion relies on a GoTrue endpoint (`DELETE /auth/v1/user`) that typically requires a service-role and is not standard self-serve** — likely fails in production. Apple **requires** working in-app account deletion.
- **USDA food search cannot work in a Release build** — the USDA API key is only settable through the Debug-only developer panel.
- **Credentials are stored insecurely** — a plaintext password and the Supabase access/refresh tokens are written to `UserDefaults`, not Keychain.

**Overall status: PARTIAL.** Design and feature breadth are strong; auth, sync, account-deletion, and a few production-config gaps must be fixed before submission.

---

## 2. Repo Structure Overview

### Phase 1 — Repo discovery table

| Area | Files/folders inspected | What it does | Status | Notes |
|---|---|---|---|---|
| iOS app entry point | `NutriscopeAI/NutriscopeAIApp.swift` | App `@main`, model container, root | ✅ Present | Not deeply read; referenced by RootView |
| App state | `App/AppState.swift`, `App/AppTab.swift` | Global observable state, sheet routing, quota/sub managers | ✅ Solid | Sheet-driven navigation |
| Root navigation | `Views/RootView.swift` | Gates on `hasCompletedOnboarding`; MainTabView + custom tab bar + Scan FAB | ✅ Good | Single gate flag |
| Onboarding/auth flow | `Views/Auth/AuthFlowView.swift` (+ Splash, SignIn, SignUp, ResetPassword, SaveProgress, AddFirstMeal, OnboardingPlanReady) | Splash→Welcome→Goals→Diet→Profile→PlanReady→FirstMeal | ⚠️ Mostly good | No separate "calculating" or "target" screen (inline) |
| Main tabs | `RootView.MainTabView`, `AppTab.swift` | Today / Meals / Scan(FAB) / Coach / Profile | ✅ | Coach wrapped in `ProFeatureGate` |
| SwiftUI screens | `Views/**` (40+ views) | All feature screens | ✅ Broad coverage | See §4 |
| Shared components | `Components/*` (Kinetic components, gates, bars, pickers, Apple button) | Reusable UI | ✅ | `KineticComponents.swift` is large/central |
| Theme/design system | `Theme/AppTheme.swift`, `Theme/AppTypography.swift` | Colors, spacing, glass, typography tokens | ✅ Matches tokens | See §4 |
| Models / SwiftData | `Models/*` (MealRecord, SavedMeal, WeightLog, UserSettings, GroceryItem, CoachChatMessage, DietPreference, MealType, ReminderSettings, MealAnalysis) | On-device persistence | ✅ | All local |
| Services/managers | `Services/*` (35 files) | Auth, backend, AI, quota, subscription, notifications, health, sync, calculators | ✅ Extensive | See §6/§7 |
| StoreKit | `Services/SubscriptionManager.swift`, `SubscriptionPricing.swift`, `Views/Paywall/*` | StoreKit 2 subscriptions | ✅ Good code | No `.storekit` test config file |
| Supabase client/auth | `Services/SupabaseAuthClient.swift`, `AuthSessionManager.swift`, `BackendAuthBootstrap.swift` | Raw GoTrue REST; dual local+remote auth | ⚠️ Issues | See §10 |
| Supabase edge functions | `supabase/functions/analyze-meal/index.ts`, `ai-proxy/index.ts` | OpenAI proxies, key server-side | ✅ Good | See §8 |
| Supabase migrations/RLS | `supabase/migrations/001_ios_user_profiles.sql` | Single table + RLS | ⚠️ Minimal | Only profiles |
| Config files | `Resources/Shared.xcconfig`, `Info.plist` (x2), entitlements, `supabase/config.toml` | Build + secrets injection | ✅ | `Backend.xcconfig` gitignored/not present |
| Legal links | `Services/AppLegalLinks.swift`, `Views/Paywall/SubscriptionLegalLinksView.swift` | Terms + Privacy URLs | ⚠️ | `nutriscopeai.app/terms|privacy`; no support URL found |
| Debug/developer settings | `Views/Profile/ProfileAccountView.swift` (`#if DEBUG`) | Supabase/OpenAI/USDA key entry, reset onboarding | ✅ Gated | Correctly `#if DEBUG` only |
| Test files/targets | — | — | ❌ None | No test target, no `*Tests` files |
| Design prototypes (new) | `new stitch designs/` (178 dirs, 170 `code.html`, + 3 spec `.md`) | Canonical design source | ✅ | See §3 |
| Old/legacy designs | `old stich designs/`, `other pages/` | Legacy Stitch exports | 🗑️ Legacy | See §15 |
| Existing audit/report files | `MASTER_IMPLEMENTATION_AUDIT.md`, `NEW_DESIGN_IMPLEMENTATION_PLAN.md`, `NEW_DESIGN_REDESIGN_REPORT.md`, `CANONICAL_SCREENS.md`, `DESIGN_FLOWS.md`, `P0_FIX_PLAN.md`, `doc/BACKEND_SETUP.md`, `README.md` | Prior planning/audits | ⚠️ Partly stale | `CANONICAL_SCREENS.md` self-declared outdated; redesign report overstates a few items |
| Project generation | `generate_xcode_project.py`, `NutriscopeAI.xcodeproj` | Pbxproj generator | ✅ | No secrets in script |
| Widget | `NutriscopeWidget/ProteinWidget.swift`, entitlements, Info.plist | Home-screen protein widget | ✅ Present | App group `group.com.nutriscopeai.app` |

---

## 3. Design Prototype Inventory

The design source of truth is **`new stitch designs/`** (178 subfolders, each typically `code.html` + `screen.png`; 170 contain `code.html`), plus three spec files:

| Design folder/file | Type | Screen/feature | Source of truth? | Notes |
|---|---|---|---|---|
| `new stitch designs/` | Folder (170 HTML prototypes) | All screens | ✅ **Yes (canonical)** | Confirmed by `NEW_DESIGN_REDESIGN_REPORT.md` §2 |
| `nutriscope_ai_design_tokens.md` | Token spec | Colors/type/spacing/effects | ✅ Yes | Matches `AppTheme`/`AppTypography` closely |
| `nutriscope_ai_component_spec.md` | Component spec | Reusable components | ✅ Yes | Present |
| `nutriscope_ai_interaction_spec.md` | Interaction spec | Motion/FAB/toasts | ✅ Yes | Present |
| `kinetic_harvest_1/DESIGN.md` (referenced) | Legacy palette | Color/type origin | ⚠️ Partial | Background `#FBF9F4` in code traces to this, not the newer `#fcf9f8` token |
| `old stich designs/` | Folder (legacy) | Old Stitch exports | ❌ Legacy only | ~9 subfolders |
| `other pages/` | Folder (legacy) | Old Stitch variants | ❌ Legacy only | Duplicate of old exports |
| `CANONICAL_SCREENS.md` | Doc | Old canonical map | ❌ Outdated | Self-superseded by implementation plan |

**Token fidelity (spot check `AppTheme.swift` vs `nutriscope_ai_design_tokens.md`):**

| Token | Design value | Code value | Match |
|---|---|---|---|
| `coach-orange` | `#f26b38` | `0xF26B38` | ✅ |
| `primary` | `#a93702` | `0xA93702` | ✅ |
| `surface-bright` | `#fdf8f8` | `0xFDF8F8` | ✅ |
| `surface-main` | `#fcf9f8` | `0xFBF9F4` (background) | ⚠️ Minor mismatch (legacy warm-paper) |
| `margin-main` | 20pt | `marginMain = 20` | ✅ |
| `radius-lg` | 24pt | `cornerRadiusXL = 24` | ✅ |
| Type: Hanken Grotesk | Yes | Fonts bundled + registered in Info.plist | ✅ |

Token system is faithfully implemented. The only visible deviation is the base background hue (legacy Kinetic Harvest `#FBF9F4` vs newer token `#fcf9f8`) — P3 polish.

---

## 4. Frontend Design Parity Analysis

### Phase 2 — Design screen → SwiftUI mapping

Legend — Implemented? / Visually redesigned? based on file presence + reading of the SwiftUI screen and the design folder existence. "Redesigned" = uses the new design-system primitives (ambient background, glass cards, display/headline typography, FAB).

| Design screen/prototype | Matching SwiftUI screen/file | Implemented? | Redesigned? | Missing UI pieces | Mismatch notes | Priority |
|---|---|---|---|---|---|---|
| Splash | `Views/Auth/SplashView.swift` | ✅ | ✅ | — | No HTML prototype; built from tokens | P3 |
| Welcome | `AuthFlowView.welcomePage` | ✅ | ✅ | — | Uses `welcome-hero` asset | — |
| Onboarding goals | `AuthFlowView.goalPage` | ✅ | ✅ | — | `KineticGoalCard` | — |
| Diet preferences | `AuthFlowView.dietPage` | ✅ | ✅ | — | `KineticDietChip` grid | — |
| Profile/body stats | `AuthFlowView.profilePage` | ✅ | ✅ | — | Gender/age/height/weight/activity | — |
| Protein target | (inline in PlanReady) | ⚠️ Partial | ✅ | No standalone target screen | Targets computed inline; design `onboarding_protein_target_branded` not a discrete screen | P2 |
| Plan ready/calculating | `OnboardingPlanReadyView.swift` | ✅ (ready) / ❌ (calculating) | ✅ | **No "calculating your plan" interstitial** | Redesign report claims `OnboardingCalculatingPlanView.swift` — **file does not exist** | P3 |
| Add first meal | `Views/Auth/AddFirstMealView.swift` | ✅ | ✅ | — | — | — |
| Scan meal | `Views/Scan/ScanMealView.swift` | ✅ | ✅ | — | Viewport reticle/scan line | — |
| Manual meal log | `Views/Scan/ManualMealLogView.swift` | ✅ | ✅ | — | — | — |
| Voice input | `Views/Scan/VoiceListeningOverlay.swift` + speech services | ✅ | ✅ | — | — | — |
| Camera permission | `Views/Scan/CameraPermissionPromptView.swift`, `Shared/KineticPermissionPromptView.swift` | ✅ | ✅ | — | — | — |
| Meal result | `Views/Scan/MealResultView.swift` | ✅ | ✅ | — | — | — |
| Follow-up questions | `Views/Scan/FollowUpQuestionsView.swift` | ✅ | ✅ | — | — | — |
| Post-scan success | `Views/Scan/PostScanSuccessView.swift` | ✅ | ✅ | — | — | — |
| Scan failed | `Views/Scan/ScanFailedView.swift` | ✅ | ✅ | — | — | — |
| First scan tutorial | `Views/Scan/FirstScanTutorialView.swift` | ✅ | ✅ | — | — | — |
| Today dashboard | `Views/Home/TodayView.swift` | ✅ | ✅ | — | Protein arc, coach card, widget sync | — |
| Bottom tab bar / Scan FAB | `RootView.swift` | ✅ | ✅ | — | Custom kinetic tab bar | — |
| Meals/history | `Views/Meals/MealsView.swift` | ✅ | ✅ | — | — | — |
| Saved meals | within `MealsView` | ✅ | ✅ | Empty-state present | — | — |
| Coach | `Views/Coach/CoachView.swift` | ✅ | ✅ | — | Pro-gated | — |
| Tomorrow plan | `Views/Coach/TomorrowProteinPlanView.swift` | ✅ | ✅ | — | — | — |
| Food search | `Views/Tools/FoodSearchView.swift` | ✅ | ✅ | — | **Broken in Release (no USDA key path)** | P1 |
| Grocery list | `Views/Tools/GroceryListView.swift` | ✅ | ✅ | — | — | — |
| Recipe calculator | `Views/Tools/RecipeCalculatorView.swift` | ✅ | ✅ | — | — | — |
| Insights/trends | `Views/Reports/InsightsTrendsView.swift` | ✅ | ✅ | — | — | — |
| Weekly report | `Views/Reports/WeeklyReportView.swift` | ✅ | ✅ | — | — | — |
| Weight tracking | `Views/Profile/WeightTrackingSection.swift` | ✅ | ✅ | — | — | — |
| Profile | `Views/Profile/ProfileView.swift` | ✅ | ✅ | — | — | — |
| Account | `Views/Profile/ProfileAccountView.swift` | ✅ | ✅ | — | Includes debug dev panel | — |
| Data/privacy | `Views/Profile/DataPrivacyView.swift` | ✅ | ✅ | — | Export + wipe | — |
| Reminders | `Views/Profile/ReminderSettingsView.swift` | ✅ | ✅ | — | — | — |
| Goals settings | `Views/Profile/ProfileGoalsSettingsView.swift` | ✅ | ✅ | — | — | — |
| Paywall | `Views/Paywall/PaywallView.swift` | ✅ | ✅ | — | — | — |
| Scan quota paywall | `Views/Paywall/ScanQuotaPaywallView.swift` | ✅ | ✅ | — | — | — |
| Subscription success | `Views/Paywall/SubscriptionSuccessView.swift` | ✅ | ✅ | — | — | — |
| Trial ending prompt | `Views/Paywall/TrialEndingSoonView.swift` | ✅ | ✅ | — | StoreKit-driven | — |
| Save progress/account choice | `Views/Auth/SaveProgressView.swift` | ✅ | ✅ | — | Three-path | — |
| Sign in | `Views/Auth/SignInView.swift` | ✅ | ✅ | — | **Logic broken for new device** | P0 |
| Sign up | `Views/Auth/SignUpView.swift` | ✅ | ✅ | — | — | — |
| Forgot password | `Views/Auth/ResetPasswordView.swift` | ✅ | ✅ | — | Two divergent reset paths | P2 |
| Manage subscription | `Views/Paywall/ManageSubscriptionView.swift` | ✅ | ✅ | — | — | — |
| Toasts | `KineticComponents.swift` (`ToastCenter`/`KineticToastHost`) | ✅ | ✅ | — | Hosted on RootView | — |
| Confirmation dialogs | `KineticComponents.swift` (`kineticConfirmationDialog`) | ✅ | ✅ | — | — | — |
| Empty states | Saved meals / grocery / food-search no-results | ✅ | ✅ | — | — | — |
| Error states | Scan failed, unconfigured backend messages | ✅ | ✅ | — | — | — |

**Parity verdict:** Frontend design parity is **high**. Almost every canonical design screen has a redesigned SwiftUI counterpart. The two real gaps are a **non-existent "calculating plan" interstitial** (claimed but absent) and the **protein-target step folded into Plan Ready** rather than a discrete screen.

---

## 5. Missing Screens / Features

### Phase 3 — Missing items

| Missing screen/feature | Source/design file | Required for current flow? | App equivalent exists? | Implement now? | Priority | Reason |
|---|---|---|---|---|---|---|
| Calculating-your-plan interstitial | `onboarding_calculating_your_plan/` | No | Plan Ready transition | Optional | P3 | Branded "computing targets" moment; flow works without it. Redesign report incorrectly claims it is implemented |
| Discrete protein-target screen | `onboarding_protein_target_branded/` | No | Folded into Plan Ready | Optional | P2 | Targets shown on PlanReady; a dedicated tuning screen would improve clarity |
| Social meal estimator | `social_meal_estimator_ai/` | No | Scan flow | No | Future/v2 | Out of current scope |
| Support/contact screen or URL | (App Store requirement) | Yes (for submission) | None found | Yes | P1 | App Store requires a working support URL |

### Classification

- **Missing and required:** Support URL/contact (App Store requirement).
- **Partially implemented:** Protein-target step (inline, not discrete); cloud sync (profile only).
- **Implemented but not redesigned:** None material — all canonical screens use the new system.
- **Future/v2:** Social meal estimator.
- **Not applicable:** Most of the 170 HTML files are duplicate/variant explorations of the ~48 canonical screens.
- **Duplicate/legacy design only:** `old stich designs/`, `other pages/`.

### Counts

| Category | Count |
|---|---:|
| Total design files inspected (HTML prototypes) | 170 |
| Canonical design screens (per redesign plan) | ~48 |
| Implemented and redesigned | ~46 |
| Implemented but not redesigned | 0 |
| Partially implemented | 2 (target step, cloud sync) |
| Missing from app | 1–2 (calculating interstitial; support URL) |
| Future/v2 | 1 (social meal estimator) |
| Duplicate/legacy/not applicable | ~122 |

---

## 6. End-to-End Flow Audit

### Phase 4 — Flow table

| Flow | Actual implemented path | Works? | Broken/incomplete step | Files | Priority | Notes |
|---|---|---|---|---|---|---|
| Fresh install onboarding | Splash → Welcome → Goals → Diet → Profile → PlanReady → FirstMeal → (scan/manual) → onboarding complete → Today | ✅ | No "calculating"/discrete target screen | `AuthFlowView`, `OnboardingPlanReadyView`, `AddFirstMealView`, `ScanMealView`/`ManualMealLogView` | P3 | Guest completes without auth |
| Returning — onboarding complete | RootView shows MainTabView (gated on `hasCompletedOnboarding`) | ✅ | — | `RootView`, `AppState` | — | — |
| Returning — onboarding incomplete | `resumeFlowIfNeeded()` jumps to FirstMeal if local profile exists | ✅ | — | `AuthFlowView` | — | — |
| Guest user | Anonymous Supabase session via `BackendAuthBootstrap`; `GuestModeManager.isGuest = true` | ✅ | Requires Anonymous auth enabled in Supabase (needs verify) | `BackendAuthBootstrap`, `GuestModeManager` | P1 | If anonymous auth off → scans/coach fail with unauthorized |
| Signed-in user | Local account + Supabase session | ⚠️ | See sign-in flow | `AuthSessionManager`, `SupabaseAuthClient` | P0 | — |
| Subscribed user | `subscriptionManager.isSubscribed` → unlimited scans, coach | ✅ | — | `SubscriptionManager`, `AppState` | — | — |
| Unsubscribed user | 5 scans/week, paywall on overflow + pro features | ✅ | — | `ScanQuotaManager`, `ProFeatureGate` | — | — |
| Free hits quota/premium | `presentScanIfAllowed()` → `.scanQuota`; coach gated → `ProFeatureGate` | ✅ | — | `AppState`, `RootView` | — | — |
| Paywall monthly/yearly | `PaywallView` + `SubscriptionPlansSection`, `Product.displayPrice` | ✅ | — | Paywall views | — | Needs live products to render real prices |
| StoreKit purchase | `SubscriptionManager.purchase()` → verify → `refreshEntitlements()` | ✅ | — | `SubscriptionManager` | — | Needs Sandbox verify |
| Success screen | `completePurchaseSuccess()` → `.subscriptionSuccess` | ✅ | — | `AppState`, `SubscriptionSuccessView` | — | — |
| Optional Save Progress | `promptSaveProgressIfNeeded()` if not signed-in | ✅ | Saving doesn't migrate meal history (no sync) | `SaveProgressView`, `AppState` | P1 | "Save progress" is misleading vs reality |
| Restore purchases | `AppStore.sync()` + refresh; surfaced on Welcome/SignIn/Account | ✅ | — | `SubscriptionManager`, `AppState` | — | — |
| Cancelled purchase | `.userCancelled`/`.pending` → no-op | ✅ | — | `SubscriptionManager` | — | — |
| Expired subscription | `currentEntitlements` excludes expired → `isSubscribed=false` | ✅ | — | `SubscriptionManager` | — | — |
| Trial ending prompt | `shouldPromptTrialEnding` (≤3d, intro offer) → `.trialEnding` | ✅ | — | `SubscriptionManager`, `AppState`, `TrialEndingSoonView` | — | Needs Sandbox verify |
| Anonymous guest mode | Silent anonymous Supabase signup | ✅ | Depends on backend toggle | `BackendAuthBootstrap` | P1 | — |
| Email signup | `AuthSessionManager.signUp` (local, plaintext pw) + `SupabaseAuthClient.signUpWithEmail` (or link if anon) | ⚠️ | Stores plaintext password locally | `AuthFlowView.submitCreateAccount` | P1 | Dual writes |
| Apple signup/sign-in | `SignInWithAppleButton` → `SupabaseAuthClient.signInWithApple` (link if anon) | ✅ | — | `SupabaseAuthClient`, components | — | Needs device verify |
| Email login | `AuthSessionManager.signIn` (local check FIRST) → then Supabase | ❌ | **Local guard rejects users not already on device** | `AuthFlowView.submitSignIn`, `AuthSessionManager.signIn` | **P0** | New device/reinstall login impossible via email |
| Logout | `AuthSessionManager.signOut` → clears local, signs out Supabase, re-creates anon guest | ✅ | — | `AuthSessionManager` | — | — |
| Guest→account conversion | Anonymous session linked via email/Apple link endpoints | ✅ (auth) / ⚠️ (data) | On-device data stays; profile-only cloud | `SupabaseAuthClient.linkEmailPassword/linkAppleIdentity` | P1 | Linking works; history not migrated to cloud (it stays local, which is fine, but not "backed up") |
| Forgot password | `ResetPasswordView` → Supabase `recover` email OR local `AuthSessionManager.resetPassword` | ⚠️ | Two divergent paths; local path bypasses email verification | `ResetPasswordView`, `SupabaseAuthClient.requestPasswordReset`, `AuthSessionManager.resetPassword` | P2 | Inconsistent |
| Delete account | `AccountDeletionService` → `SupabaseAuthClient.deleteCurrentUser()` (`DELETE /auth/v1/user`) + local wipe | ❌ likely | GoTrue self-delete typically needs service role | `AccountDeletionService`, `SupabaseAuthClient` | **P0/P1** | App Store requires working deletion; verify on backend |

**Key flow finding (P0):** In `submitSignIn()`, the code calls `AuthSessionManager.signIn(email:password:)` **before** Supabase. That function throws `.invalidCredentials` unless a matching `currentAccount` (and matching plaintext password) already exists in this device's `UserDefaults`. On a fresh install or a second device, no local account exists, so login fails before the Supabase call is ever reached. **Returning email users cannot log in on a new device.**

---

## 7. Feature Implementation Matrix

### Phase 5 — Feature table

| Feature | Implemented? | Frontend file(s) | Backend/service | Free/Pro | Offline? | Prod-ready? | Issues | Priority |
|---|---|---|---|---|---|---|---|---|
| AI meal scan | ✅ | `ScanMealView`, `MealResultView` | `ProxyMealAnalysisService` → `analyze-meal` | Free (quota) | ❌ | ✅ | Needs anon auth on backend | P1 |
| Manual meal log | ✅ | `ManualMealLogView` | `analyze-meal` (text) | Free (quota) | ❌ | ✅ | — | — |
| Voice input | ✅ | `VoiceListeningOverlay` | `SpeechTranscriptionService`, `WhisperTranscriptionService` | Free | Partial | ✅ | Two transcription services; confirm which is wired | P2 |
| Food DB search | ✅ UI | `FoodSearchView` | `USDAFoodSearchService` | Free | ❌ | ❌ | **No USDA key path in Release** | P1 |
| Meal result | ✅ | `MealResultView`, `FollowUpQuestionsView` | `analyze-meal` | Free | ❌ | ✅ | — | — |
| Meal saving | ✅ | `MealsView`, `SavedMeal` | SwiftData | Free | ✅ | ✅ | Local only | — |
| Today dashboard | ✅ | `TodayView` | SwiftData + `WidgetDataStore` | Free | ✅ | ✅ | — | — |
| Protein progress | ✅ | `ProteinProgressBar`, Kinetic arc | SwiftData | Free | ✅ | ✅ | — | — |
| Scan quota | ✅ | quota paywall | `ScanQuotaManager` (UserDefaults) | Free | ✅ | ⚠️ | Client-side only; resettable by reinstall | P2 |
| Saved meals | ✅ | `MealsView` | SwiftData | Free | ✅ | ✅ | — | — |
| Coach chat | ✅ | `CoachView` | `ProxyAIService`/`OpenAICoachService` → `ai-proxy` | **Pro** | ❌ | ✅ | Pro-gated in RootView | — |
| Daily coach tip | ✅ | `TodayView` | `DailyCoachTipCache` + `ai-proxy` | Free/Pro | Cached | ✅ | — | — |
| Tomorrow plan | ✅ | `TomorrowProteinPlanView` | `TomorrowPlanCalculator` + `ai-proxy` | Pro-ish | ❌ | ✅ | — | — |
| Grocery suggestions | ✅ | `GroceryListView` | `ai-proxy` grocery actions | Free | ❌ | ✅ | — | — |
| Recipe calculator | ✅ | `RecipeCalculatorView` | local calc | Free | ✅ | ✅ | — | — |
| Insights/trends | ✅ | `InsightsTrendsView` | `InsightsTrendsCalculator` | Pro-likely | ✅ | ✅ | Verify gating | P2 |
| Weekly report | ✅ | `WeeklyReportView` | `WeeklyReportCalculator` | Pro-likely | ✅ | ✅ | Verify gating | P2 |
| Weight tracking | ✅ | `WeightTrackingSection` | `WeightLog` SwiftData | Free | ✅ | ✅ | Local only | — |
| Reminders/notifications | ✅ | `ReminderSettingsView` | `NotificationManager`, `RealtimeNotificationService` | Free | ✅ | ✅ | — | — |
| HealthKit | ✅ | (Profile/Today) | `HealthKitService` | Free | ✅ | ✅ | Entitlement present | — |
| Profile/settings | ✅ | `ProfileView`, `ProfileGoalsSettingsView`, `ProfileAccountView` | SwiftData | Free | ✅ | ✅ | — | — |
| Data export | ✅ | `DataPrivacyView`, `ShareSheet` | local | Free | ✅ | ✅ | Verify format | P3 |
| Delete local data | ✅ | `DataPrivacyView` | SwiftData wipe | Free | ✅ | ✅ | — | — |
| Delete account | ⚠️ | `ProfileAccountView` | `AccountDeletionService` | — | — | ❌ likely | GoTrue self-delete | P0/P1 |
| StoreKit paywall | ✅ | Paywall views | `SubscriptionManager` | — | — | ✅ | — | — |
| Trial ending prompt | ✅ | `TrialEndingSoonView` | `SubscriptionManager` | — | — | ✅ | Sandbox verify | P2 |
| Restore purchases | ✅ | multiple | `SubscriptionManager` | — | — | ✅ | — | — |
| Save Progress/account | ✅ | `SaveProgressView` | auth services | — | — | ⚠️ | No history backup | P1 |
| Widget | ✅ | `NutriscopeWidget/ProteinWidget.swift` | `WidgetDataStore` (app group) | Free | ✅ | ✅ | Verify timeline reloads | P3 |

---

## 8. Backend/Supabase Audit

### Phase 6 — Backend table

| Backend feature | Implemented? | Files | FE connected? | DB table? | RLS? | Prod-ready? | Missing/issue | Priority |
|---|---|---|---|---|---|---|---|---|
| Supabase config | ✅ | `supabase/config.toml`, `BackendConfig.swift` | ✅ | — | — | ✅ | URL/key via xcconfig→Info.plist | — |
| Anonymous auth (guest) | ✅ code | `BackendAuthBootstrap`, `SupabaseAuthClient.signInAnonymously` | ✅ | n/a | n/a | ⚠️ | **Must enable Anonymous sign-ins in Supabase** | P1 |
| Email auth | ✅ | `SupabaseAuthClient` | ⚠️ (local guard) | n/a | n/a | ❌ | Sign-in blocked by local layer | P0 |
| Apple auth | ✅ | `SupabaseAuthClient.signInWithApple` | ✅ | n/a | n/a | ⚠️ | Device verify; provider config | P1 |
| Session storage | ✅ | `SupabaseAuthClient.currentSession` | ✅ | n/a | n/a | ❌ | **Tokens in UserDefaults, not Keychain** | P1 |
| Backend config in iOS | ✅ | `BackendConfig`, `Shared.xcconfig`, `Info.plist` | ✅ | — | — | ✅ | Release relies on `Backend.xcconfig` (gitignored, absent) | P1 (ops) |
| `analyze-meal` edge fn | ✅ | `supabase/functions/analyze-meal/index.ts` | ✅ | n/a | n/a | ✅ | Requires auth, accepts anon; gpt-4o-mini | — |
| `ai-proxy` edge fn | ✅ | `supabase/functions/ai-proxy/index.ts` | ✅ | n/a | n/a | ✅ | Coach/tip/tomorrow/grocery/followup | — |
| OpenAI key server-side | ✅ | both edge fns (`Deno.env`) | n/a | — | — | ✅ | Never shipped to device in Release | — |
| No device OpenAI in Release | ✅ | `BackendConfig.usesDeviceOpenAIForCoach` (`#if DEBUG` only) | ✅ | — | — | ✅ | Confirmed | — |
| Profile upsert/sync | ✅ | `IOSUserProfileSyncService` | ✅ | `ios_user_profiles` | ✅ | ⚠️ | Linked accounts only; 5 fields only (no diet/weight/goal) | P2 |
| Meal sync | ❌ | — | — | ❌ | — | ❌ | **On-device only** (migration comment confirms) | P1 |
| Saved meals sync | ❌ | — | — | ❌ | — | ❌ | On-device only | P1 |
| Weight sync | ❌ | — | — | ❌ | — | ❌ | On-device only | P1 |
| Grocery sync | ❌ | — | — | ❌ | — | ❌ | On-device only | P2 |
| Scan quota backend | ❌ | `ScanQuotaManager` (UserDefaults) | n/a | ❌ | — | ⚠️ | Client-side; bypass via reinstall | P2 |
| Delete account backend | ⚠️ | `SupabaseAuthClient.deleteCurrentUser` | ✅ | cascades profile | ✅ FK | ❌ likely | `DELETE /auth/v1/user` typically needs service-role edge fn | P0/P1 |
| Secrets/env | ✅ | edge fns env, `Backend.xcconfig` | — | — | — | ✅ | No secrets committed (verified) | — |
| Prod vs debug behavior | ✅ | `BackendConfig.isReleaseBuild`, `#if DEBUG` | — | — | — | ✅ | Dev panel + device-OpenAI Debug-only | — |

**RLS:** `ios_user_profiles` has correct owner-scoped policies (select/insert/update `auth.uid() = id`). **No DELETE policy** (deletion is via auth cascade). No other tables exist, so no other RLS to assess.

**Edge functions:** Both are clean — CORS, method guard, auth-required (anon allowed), server-side OpenAI key, JSON-mode responses, error handling. Good.

---

## 9. StoreKit/Subscription Audit

### Phase 7 — StoreKit table

| StoreKit item | Implemented? | File(s) | Correct? | Issue/missing | Priority |
|---|---|---|---|---|---|
| Monthly product ID | ✅ | `SubscriptionManager` | `com.nutriscopeai.pro.monthly` | Must match App Store Connect | P1 (verify) |
| Yearly product ID | ✅ | `SubscriptionManager` | `com.nutriscopeai.pro.yearly` | Must match App Store Connect | P1 (verify) |
| Products loaded via StoreKit | ✅ | `loadProducts()` | `Product.products(for:)` | — | — |
| Paywall uses `displayPrice` | ✅ | `displayPrice(for:)` | Falls back to `SubscriptionPricing.monthlyFallback` | Fallback is a hardcoded string when products fail to load | P2 |
| Intro/trial UI from real offer | ✅ | `hasIntroductoryOffer`, `introductoryOfferDescription` | Reads `subscription.introductoryOffer` | — | — |
| Purchase flow | ✅ | `purchase()` | Verifies `.verified` only | — | — |
| Entitlement refresh | ✅ | `refreshEntitlements()` | `Transaction.currentEntitlements` | — | — |
| Transaction updates | ✅ | `startObservingTransactionUpdates()` | `Transaction.updates` | — | — |
| Restore purchases | ✅ | `restore()` | `AppStore.sync()` | — | — |
| Cancelled purchase | ✅ | `purchase()` | `.userCancelled`/`.pending` no-op | — | — |
| Expired subscription | ✅ | `refreshEntitlements()` | Excluded from entitlements | — | — |
| Trial ending prompt | ✅ | `shouldPromptTrialEnding`, `refreshTrialStatus()` | Uses `subscription.status` intro offer | — | — |
| Legal links | ✅ | `SubscriptionLegalLinksView`, `AppLegalLinks` | Terms/Privacy URLs | Verify live; no EULA note of auto-renew in all entry points (present in `renewalDisclosure`) | P1 |
| Continue free/close | ✅ | Paywall dismiss | — | — | — |
| No lifetime product | ✅ | only monthly/yearly | Correct | — | — |
| StoreKit test config | ❌ | no `.storekit` file | — | Add for local Sandbox testing | P3 |

**Verdict:** StoreKit 2 implementation is **clean and correct in code**. Remaining work is configuration/verification: products in App Store Connect, live legal URLs, and Sandbox testing on device.

---

## 10. Auth and Account Audit

There are **two parallel auth systems** that are imperfectly reconciled:

1. **Local (`AuthSessionManager`)** — stores a `LocalUserAccount` and a **plaintext password** in `UserDefaults`. Drives `isSignedIn` and gating.
2. **Remote (`SupabaseAuthClient`)** — raw GoTrue REST; stores `SupabaseSession` (access/refresh tokens) in `UserDefaults`.

Findings:

- **P0 — Email sign-in broken on new device:** `submitSignIn()` runs the local guard first; it throws before Supabase is consulted when no matching local account exists (fresh install / new device).
- **P1 — Plaintext password in `UserDefaults`:** `AuthSessionManager.signUp` does `UserDefaults.standard.set(password, forKey: passwordKey)`. Sensitive and unnecessary; should be Keychain or removed entirely (Supabase is the real authority).
- **P1 — Tokens in `UserDefaults`:** access/refresh tokens persisted unencrypted (readable in backups). Should be Keychain.
- **P2 — Divergent forgot-password:** Supabase `recover` email vs local `resetPassword` (no verification). Pick one (Supabase).
- **P0/P1 — Delete account:** `DELETE /auth/v1/user` with a user JWT is **not** the standard GoTrue self-delete (admin delete is `/admin/users/{id}` with service role). Likely fails → user sees error and account isn't deleted → **App Store rejection risk**. Recommended: an edge function using the service role to delete the user, called from the app.
- **Guest mode:** correct — silent anonymous session; `is_anonymous` honored; linking on signup/Apple. Depends on Anonymous sign-ins being enabled in the Supabase project (verify).

---

## 11. Data Sync Audit

| Data | Local store | Cloud table | Synced? | Risk |
|---|---|---|---|---|
| Profile (name/email/targets) | `UserSettings` (SwiftData) | `ios_user_profiles` (5 fields) | ⚠️ Partial (linked accounts only) | Diet prefs/goal/age/weight NOT in cloud |
| Meals | `MealRecord` | — | ❌ | **Lost on reinstall / new device** |
| Saved meals | `SavedMeal` | — | ❌ | Lost on reinstall |
| Weight logs | `WeightLog` | — | ❌ | Lost on reinstall |
| Grocery | `GroceryItem` | — | ❌ | Lost on reinstall |
| Coach chat | `CoachChatMessage` | — | ❌ | Lost on reinstall |

**The app presents "Save your progress" / "synced to our servers" language** (e.g., the delete-account dialog says it "removes cloud profile data"), but in reality only a tiny profile row is in the cloud. This is both a **data-durability problem** and a **truth-in-UI problem**. Either build real sync (meals table + RLS + sync service) or soften all "cloud/backup/sync" copy to "stored on this device." (P1)

---

## 12. Security / Production Readiness Audit

### Phase 8 — Production issues

| Production issue | File(s) | Risk | Priority | Recommended fix |
|---|---|---|---|---|
| Plaintext password in UserDefaults | `AuthSessionManager.swift` | High (credential exposure) | P1 | Remove local password; rely on Supabase; use Keychain if local needed |
| Auth tokens in UserDefaults | `SupabaseAuthClient.swift` | High (token theft via backup) | P1 | Move session to Keychain |
| Email sign-in unreachable on new device | `AuthFlowView.submitSignIn`, `AuthSessionManager.signIn` | High (returning users locked out) | P0 | Make Supabase the source of truth; drop/condition local guard |
| Account deletion likely non-functional | `SupabaseAuthClient.deleteCurrentUser` | High (App Store rejection) | P0/P1 | Service-role edge function for user delete |
| USDA food search has no Release key path | `MealAnalysisService.Secrets.usdaAPIKey`, `USDAFoodSearchService` | Medium (feature dead in prod) | P1 | Proxy USDA via edge fn, or inject key via xcconfig/Info.plist |
| No real cloud sync but UI implies it | `AccountDeletionService` copy, `SaveProgressView` | Medium (data loss + misleading) | P1 | Build sync OR correct copy |
| Anonymous auth dependency unverified | `BackendAuthBootstrap` | Medium (all AI fails if off) | P1 | Verify Anonymous sign-ins enabled |
| Release relies on absent `Backend.xcconfig` | `Shared.xcconfig`, `Info.plist` | Medium (broken release build) | P1 | Ensure CI/build injects URL+anon key |
| No support URL/contact | (App Store metadata) | Medium (submission requirement) | P1 | Add support URL/email |
| Legal URLs unverified | `AppLegalLinks` | Medium | P1 | Confirm `/terms` and `/privacy` are live |
| Client-side-only scan quota | `ScanQuotaManager` | Low/Med (revenue bypass via reinstall) | P2 | Server-side quota if monetization matters |
| Hardcoded price fallback string | `SubscriptionPricing` | Low (stale price shown if load fails) | P2 | Prefer hiding price until products load |
| No automated tests | (whole repo) | Medium (regression risk) | P2 | Add unit tests for calculators, quota, sub logic |
| Background hue deviates from token | `AppTheme.background` | Low | P3 | Align to `#fcf9f8` if desired |
| Stale/inaccurate audit docs | `NEW_DESIGN_REDESIGN_REPORT.md` (claims `OnboardingCalculatingPlanView`) | Low | P3 | Correct docs |

**Positive security findings:** No hardcoded API keys/JWTs/Supabase URLs in source (grep verified). OpenAI key is server-side only. Debug developer panel and device-OpenAI paths are correctly `#if DEBUG`. Permission usage strings present in Info.plist. Entitlements (Apple Sign In, HealthKit, App Group) configured.

---

## 13. App Store Readiness

| Requirement | Status | Notes |
|---|---|---|
| Working account deletion | ❌ | Likely broken (GoTrue self-delete) — **blocker** |
| Sign in with Apple (since 3rd-party login present) | ✅ code | Verify on device |
| Privacy policy URL | ⚠️ | Present in code; verify live |
| Terms of use / EULA | ⚠️ | Present; auto-renew disclosure in `renewalDisclosure` |
| Support URL | ❌ | Not found — required |
| Subscription disclosures (price, period, auto-renew) | ✅ | `renewalDisclosure` covers it |
| Permission strings | ✅ | Camera/mic/photo/speech/health all present |
| Privacy nutrition labels (data collection) | ⚠️ | Must declare profile/health/usage data |
| No private API / placeholder content | ✅ | None observed |
| Functional core flow without crashes | ⚠️ | Cannot build here; needs device run |

---

## 14. Build/Test Results

### Phase 9 — Build/test table

| Check | Result | Notes |
|---|---|---|
| Build command | Not run | **No Xcode/Swift toolchain in this Linux environment** (`which xcodebuild swift` → none) |
| Build result | Unknown | Prior `NEW_DESIGN_REDESIGN_REPORT.md` claims `BUILD SUCCEEDED` on iPhone 17 sim — unverified here |
| Warnings | Unknown | Cannot assess |
| Errors | Unknown | Static read found no obvious syntax issues, but compiler not run |
| Test targets found | ❌ None | No test target in pbxproj; no `*Tests.swift` files |
| Tests run | None | N/A |
| Missing critical tests | Yes | PersonalizedTargetCalculator, ScanQuotaManager, SubscriptionManager entitlement logic, auth flows |

**Action:** Build and run on a Mac with Xcode before TestFlight; this environment cannot validate compilation.

---

## 15. Dead Code / Legacy Files

| Item | Type | Recommendation |
|---|---|---|
| `old stich designs/` | Legacy design exports (~9 dirs) | Keep out of build; archive/remove later |
| `other pages/` | Legacy duplicates | Archive/remove later |
| `CANONICAL_SCREENS.md` | Outdated doc (self-declared) | Update or delete |
| `AuthSessionManager.deleteAccount()` | `@available(deprecated)` | Remove after confirming no callers |
| `AuthSessionManager` local password/account layer | Redundant with Supabase | Candidate for removal (causes the P0 sign-in bug) |
| `MockMealAnalysisService` | Demo-only (`-OfflineDemo`) | Keep (screenshots) |
| Two transcription services (`SpeechTranscriptionService`, `WhisperTranscriptionService`) | Possible redundancy | Confirm which is wired; remove the other |
| `NEW_DESIGN_REDESIGN_REPORT.md` claim of `OnboardingCalculatingPlanView.swift` | Inaccurate (file absent) | Correct doc |

*(Do not delete now — per instructions. Listed for awareness.)*

---

## 16. Top Issues by Priority

**P0 — Must fix before serious TestFlight**
1. Email sign-in unreachable on fresh install / new device (local guard precedes Supabase).
2. Account deletion likely non-functional (GoTrue self-delete) — also an App Store blocker.

**P1 — Must fix before App Store submission**
3. Plaintext password and auth tokens stored in `UserDefaults` (move to Keychain / remove local password).
4. No real cloud sync for meals/weight/saved/grocery while UI implies backup — build sync or correct copy.
5. USDA food search dead in Release (no key path) — proxy or inject key.
6. Verify Anonymous sign-ins enabled in Supabase (otherwise all AI features fail for guests).
7. Ensure `Backend.xcconfig` (URL + anon key) is injected in release builds.
8. Add support URL; verify Terms/Privacy URLs are live; complete privacy nutrition labels.
9. Confirm StoreKit product IDs exist in App Store Connect.

**P2 — Should fix before launch polish**
10. Unify forgot-password to the Supabase email path only.
11. Server-side scan quota if quota bypass matters for monetization.
12. Profile sync stores only 5 fields (no diet/goal/age/weight) — expand or document.
13. Add a unit-test target for calculators, quota, and subscription logic.
14. Add a discrete protein-target step if product wants it.

**P3 — Future / nice-to-have**
15. "Calculating your plan" interstitial (claimed but absent).
16. `.storekit` test config for Sandbox.
17. Align background hue to token; correct stale audit docs; social meal estimator (v2).

---

## 17. Recommended Fixing Order

1. **Auth source-of-truth refactor (P0):** Make Supabase the authority for email sign-in/sign-up; remove or bypass the local password layer; move session to Keychain. This fixes the sign-in P0 and the plaintext-password P1 together.
2. **Account deletion edge function (P0):** Add a service-role edge function to delete the auth user; call it from `AccountDeletionService`. Verify end-to-end.
3. **Backend enablement verification (P1):** Confirm Anonymous sign-ins on, edge functions deployed with `OPENAI_API_KEY`, `Backend.xcconfig` injected in release.
4. **Truth-in-UI / sync decision (P1):** Either implement `ios_meals` (+RLS+sync) or soften all "cloud/backup/save progress" copy to on-device.
5. **USDA food search (P1):** Add a USDA proxy edge function (preferred) or inject the key via xcconfig.
6. **App Store metadata (P1):** Support URL, live legal URLs, privacy labels, product IDs.
7. **Device build + StoreKit Sandbox pass (P1):** Build in Xcode; smoke-test purchase/restore/trial/quota/delete.
8. **Polish (P2/P3):** forgot-password unification, tests, quota hardening, docs cleanup, optional onboarding screens.

---

*Report generated from static source inspection only. No code was modified. Compilation, StoreKit Sandbox behavior, live backend configuration, and live URL availability were not executable in this environment and must be verified on a Mac with Xcode against the configured Supabase project.*
