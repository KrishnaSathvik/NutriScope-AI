# NutriScope AI — UI / UX Improvement Plan

**Date:** 2026-06-24
**Branch:** `claude/clever-ramanujan-slz2it`
**Scope:** Design / UI / UX / product-experience review **only**. No code changed, no screens redesigned, no features added, no backend/auth/StoreKit logic touched.
**Basis:** Read the actual SwiftUI screens, `AppTheme`/`AppTypography`, shared components, the three design spec files, the `new stitch designs/` prototypes, and the prior audit docs (`FULL_CODEBASE_ANALYSIS_REPORT.md`, `NEW_DESIGN_*`).
**Environment note:** Reviewed statically (no Mac/Xcode here), so visual scores are based on reading layout code + comparing to prototype HTML/PNG, not on running pixels on a device. Where a score depends on live rendering it is noted.

---

## 1. Executive Summary

NutriScope AI already looks and feels like a **premium, cohesive, well-designed app**. The design-token system (`AppTheme`/`AppTypography`) faithfully implements the `new stitch designs/` spec, the screens consistently use the same primitives (ambient background, glass cards, FAB, macro bento, kinetic components), and the core surfaces — Today dashboard, Meal Result, Paywall, onboarding — are genuinely strong. This is **not** an app that needs a redesign.

What it needs is **targeted polish in five areas**:

1. **Conversion experience** — the Scan-Quota paywall is styled like a *red error/alarm* and forces a two-tap path to the real paywall, which hurts both premium feel and conversion.
2. **Truthful copy** — several screens promise "sync across devices" / "protect your data on our servers" while (per the codebase audit) only a 5-field profile is in the cloud and meals are device-only. This is a trust + App Store-review risk.
3. **Accessibility** — all typography uses fixed point sizes with **no Dynamic Type scaling**, so accessibility text settings have no effect. This is the single biggest usability gap.
4. **Brand consistency** — the app icon/logo mark is inconsistent (leaf vs. fork-knife) across Splash, Welcome, and Save Progress.
5. **Micro-interaction fidelity** — a few delightful behaviors specified in the interaction spec (animated "typing" dots, macro-pill expansion, skeleton loaders) are implemented as plain placeholders.

None of these require new screens. They're refinements to existing, already-good screens.

---

## 2. Overall UI/UX Score

**Status: Good (trending Strong).**

| Dimension | Score /10 | Comment |
|---|---:|---|
| Visual design quality | 8.5 | Cohesive, premium, token-faithful |
| Prototype parity | 8.5 | Most screens are strong matches |
| UX clarity / flow | 7.5 | Mostly clear; quota paywall + double account prompts add friction |
| Copywriting | 7.0 | Warm and protein-first, but some overpromises and alarm tones |
| Conversion design | 7.0 | Strong main paywall; weak quota paywall |
| Accessibility | 5.0 | No Dynamic Type scaling; some icon buttons unlabeled |
| Consistency / design system | 8.0 | Strong, minor brand-mark + dismiss-copy drift |
| **Overall** | **7.5** | Polished base; a focused design sprint gets it to ~9 |

---

## 3. Best Screens Right Now

1. **Meal Result** (`MealResultView.swift`) — rich, well-sequenced: hero → macro bento → confirmation → coach insight → advice → success banner → "what now." Best-in-app.
2. **Today Dashboard** (`TodayView.swift`) — date-first header, protein arc, streak pill, coach card, meals grouped by type, strong empty state.
3. **Paywall** (`PaywallView.swift` + `SubscriptionPlansSection.swift`) — yearly default, savings %, real intro offer, restore, legal, continue-free, renewal disclosure. Clean and trustworthy.
4. **Add First Meal** (`AddFirstMealView.swift`) — focused two-choice layout, primary vs. secondary clearly differentiated, good pre-permission copy.
5. **Save Progress / Account Choice** (`SaveProgressView.swift`) — three clear paths with recommended trial first; good progressive disclosure of the create-account section.

---

## 4. Weakest Screens Right Now

1. **Scan-Quota Paywall** (`ScanQuotaPaywallView.swift`) — red alarm styling + two-step to actual paywall. Highest-impact fix.
2. **Subscription Success** (`SubscriptionSuccessView.swift`) — converts well but immediately re-prompts for account (double ask) and overpromises "protect your profile … on our servers."
3. **Coach** (`CoachView.swift`) — strong layout, but "Thinking…" plain bubble instead of the spec's animated wave dots; quick-prompts discoverability.
4. **Splash** (`SplashView.swift`) — fine but uses a *different* brand mark (leaf) than Welcome (fork-knife); fixed 1.2s delay.
5. **Today coach card loading** — shows literal "Loading coach insight…" text instead of a skeleton/shimmer; feels unfinished on first load.

---

## 5. Screen-by-Screen UI/UX Review

Scores are relative to a premium App Store bar. "Prototype match" = how close to the selected `new stitch designs/` canonical screen.

| Screen | File | Quality /10 | Prototype /10 | UX clarity /10 | Main issue | Recommended improvement | Priority |
|---|---|---:|---:|---:|---|---|---|
| Splash | `Auth/SplashView.swift` | 7 | 7 (no HTML) | 8 | Brand mark differs (leaf vs fork) | Unify logo mark with Welcome/app icon | P2 |
| Welcome | `AuthFlowView.welcomePage` | 9 | 9 | 9 | — | Keep; ensure hero asset crops well on small screens | P3 |
| Onboarding goals | `AuthFlowView.goalPage` | 8 | 8 | 8 | No selected-state affordance described | Confirm clear selected state + haptic | P3 |
| Diet preferences | `AuthFlowView.dietPage` | 8 | 8 | 8 | Multi-select clarity | Add "Pick all that apply" reinforcement on chips | P3 |
| Profile / body stats | `AuthFlowView.profilePage` | 8 | 8 | 7 | Numeric fields keyboard friction | Numeric keypad + done bar; unit clarity | P2 |
| Protein target | (inline in PlanReady) | 7 | 6 | 7 | No discrete tuning screen | Optional: dedicated adjustable target step | P2 |
| Calculating plan | — (not implemented) | n/a | n/a | n/a | Screen absent (claimed in docs) | Optional branded interstitial | P3 |
| Plan ready | `Auth/OnboardingPlanReadyView.swift` | 8 | 8 | 8 | — | Keep; ensure numbers animate in | P3 |
| Add first meal | `Auth/AddFirstMealView.swift` | 9 | 8 | 9 | — | Keep | P3 |
| Scan meal | `Scan/ScanMealView.swift` | 8 | 8 | 8 | Viewport chrome good | Verify reticle/scan-line on device | P2 |
| Manual meal log | `Scan/ManualMealLogView.swift` | 8 | 8 | 8 | — | Keyboard handling polish | P2 |
| Voice input | `Scan/VoiceListeningOverlay.swift` | 8 | 8 | 7 | Two transcription services | Confirm single path; clear "listening" state | P2 |
| Permission prompts | `Scan/CameraPermissionPromptView.swift`, `Shared/KineticPermissionPromptView.swift` | 8 | 8 | 8 | — | Keep; ensure copy matches actual ask | P3 |
| Meal result | `Scan/MealResultView.swift` | 9 | 9 | 9 | Long screen | Keep; consider sticky save CTA | P3 |
| Follow-up questions | `Scan/FollowUpQuestionsView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Post-scan success | `Scan/PostScanSuccessView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Scan failed | `Scan/ScanFailedView.swift` | 8 | 8 | 8 | — | Ensure 3 recovery paths obvious | P2 |
| First scan tutorial | `Scan/FirstScanTutorialView.swift` | 7 | 8 | 7 | May add a step before value | Make skippable / lightweight | P3 |
| Today dashboard | `Home/TodayView.swift` | 9 | 9 | 9 | Coach-tip loading text | Skeleton loader for coach card | P2 |
| Tab bar / Scan FAB | `RootView.swift` | 9 | 9 | 9 | — | Verify FAB breathing-glow + tap spring per spec | P3 |
| Meals / history | `Meals/MealsView.swift` | 8 | 8 | 8 | — | Keep; confirm grouping + empty state | P3 |
| Saved meals | within `MealsView` | 8 | 8 | 8 | — | Keep empty state | P3 |
| Coach | `Coach/CoachView.swift` | 7.5 | 8 | 8 | Plain "Thinking…" bubble | Animated wave-dots; surface quick prompts | P2 |
| Tomorrow plan | `Coach/TomorrowProteinPlanView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Food search | `Tools/FoodSearchView.swift` | 7 | 8 | 7 | Dead in Release (no USDA key) | Backend fix (in code audit); add no-results state polish | P1 |
| Grocery list | `Tools/GroceryListView.swift` | 8 | 8 | 8 | — | Keep; empty state | P3 |
| Recipe calculator | `Tools/RecipeCalculatorView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Insights / trends | `Reports/InsightsTrendsView.swift` | 8 | 8 | 7 | Chart interactivity per spec | Add scrubber/tooltip (spec §5) | P2 |
| Weekly report | `Reports/WeeklyReportView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Weight tracking | `Profile/WeightTrackingSection.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Profile | `Profile/ProfileView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Account | `Profile/ProfileAccountView.swift` | 7.5 | 8 | 7 | Dense; mixes states | Tighten section grouping | P2 |
| Data / privacy | `Profile/DataPrivacyView.swift` | 8 | 8 | 8 | "cloud" wording | Match copy to real sync scope | P1 |
| Reminders | `Profile/ReminderSettingsView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Goals settings | `Profile/ProfileGoalsSettingsView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Paywall | `Paywall/PaywallView.swift` | 8.5 | 9 | 9 | — | Keep | P3 |
| Scan-quota paywall | `Paywall/ScanQuotaPaywallView.swift` | 5 | 7 | 6 | Red alarm + two-step convert | Reframe as warm upsell with inline CTA | P1 |
| Subscription success | `Paywall/SubscriptionSuccessView.swift` | 7 | 8 | 7 | Double account prompt + copy | Single soft account nudge; fix copy | P2 |
| Trial ending prompt | `Paywall/TrialEndingSoonView.swift` | 8 | 8 | 8 | — | Verify tone is non-pushy | P2 |
| Save progress | `Auth/SaveProgressView.swift` | 8 | 8 | 8 | "sync across devices" overpromise | Fix copy to match reality | P1 |
| Sign in | `Auth/SignInView.swift` | 8 | 8 | 6 | Login logic broken on new device (code audit) | UX is fine; logic fix is in code report | P0 (logic) |
| Sign up | `Auth/SignUpView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Forgot password | `Auth/ResetPasswordView.swift` | 7 | 8 | 6 | Two divergent reset paths | Single Supabase email path; clear confirmation | P2 |
| Manage subscription | `Paywall/ManageSubscriptionView.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Toasts | `KineticComponents.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Confirmation dialogs | `KineticComponents.swift` | 8 | 8 | 8 | — | Keep | P3 |
| Empty states | various | 8 | 8 | 8 | — | Consistent illustration vs text | P3 |
| Error states | various | 6.5 | 7 | 6 | Some surface raw/technical text | Friendlier copy + retry affordances | P2 |

---

## 6. Design Prototype Parity Review

| Screen | New design prototype | Match level | What matches | What does not match | Improve? | Priority |
|---|---|---|---|---|---|---|
| Welcome | `onboarding_welcome_ios_native_2` | Strong | Hero, headline, dual CTA | — | No | P3 |
| Goals | `goal_setting_next_gen` | Strong | Cards, headline-lg | Selected-state animation | Minor | P3 |
| Diet | `onboarding_preferences` | Strong | Chip grid | — | No | P3 |
| Profile | `onboarding_profile_ios_native` | Strong | Gender segment, metric fields, activity radios | — | No | P3 |
| Plan ready | `onboarding_success_branded` | Good enough | Hero + summary | Numbers animation | Minor | P3 |
| Today | `dashboard_today_ios_native_final` | Strong | Arc, coach card, macros | Coach card loading skeleton; "Fix My Day" naming | Minor | P2 |
| Scan | `ai_meal_scan` | Strong | Viewport reticle/scan line | Rotating-rim active state (spec §1) | Minor | P2 |
| Meal result | `meal_analysis_next_gen` | Strong | Hero, bento, advice | — | No | P3 |
| Post-save | `post_scan_success_next_gen_v3` | Strong | Celebration | — | No | P3 |
| Coach | `coach_next_move_next_gen` + `coach_chat_ios_native` | Good enough | Gap card, bubbles | Typing wave-dots, advice spotlight (spec §4) | Yes | P2 |
| Meals | `meal_history_next_gen` | Strong | Inline header, grouping | — | No | P3 |
| Paywall | `nutriscope_pro_paywall_ios_native` | Strong | Glass features, plans | — | No | P3 |
| Scan-quota | `scan_quota_exhausted_paywall` | Partial | Usage bar, benefits | **Red alarm tone**, two-step convert | Yes | P1 |
| Insights | `insights_trends_next_gen` | Good enough | Glass chart cards | Interactive scrubber/tooltip (spec §5) | Yes | P2 |
| Weekly | `weekly_progress_next_gen_final` | Strong | Layout | — | No | P3 |
| Profile/Account | `user_profile_settings_ios_native` | Strong | Sections | Account screen density | Minor | P2 |
| Privacy | `privacy_data_ios_native_final` | Strong | Export/cache cards | "cloud" copy | Copy | P1 |
| Splash | (no HTML) | No prototype | Token-built | Brand-mark mismatch | Yes | P2 |
| Macro pills | component spec §1/§2 | Good enough | Capsule pills | Tap-expand + sparkle bloom (spec §2) | Future | P3 |

**Net:** parity is high. The weak/partial items are concentrated in **Scan-quota (tone)**, **Coach (typing animation)**, **Insights (chart interactivity)**, and **Splash (brand mark)**.

---

## 7. User Flow UX Review

| Flow | Current UX | Friction point | Improvement | Priority | Reason |
|---|---|---|---|---|---|
| First-time | Splash → Welcome → Goals → Diet → Profile → PlanReady → Add first meal → Scan/log → Result → Dashboard | Strong; targets recalc live | No "computing" beat; first-scan tutorial may delay value | Keep flow; make tutorial skippable; optional calculating beat | P3 | Flow already converts to first logged meal |
| Returning | Launch → Dashboard (gated on `hasCompletedOnboarding`) | Instant | — | Keep | — | Good |
| Free → quota | Dashboard → 5 scans → `.scanQuota` | Quota screen reads as **error**, then needs a 2nd tap to reach paywall | Reframe as warm upsell; inline "Start Free Trial" CTA | **P1** | Loses momentum at the highest-intent moment |
| Premium conversion | Premium action → Paywall → StoreKit → Success → optional Save Progress | Success screen **immediately re-prompts** account | Make account nudge a single soft step, not a second sheet | P2 | Double ask feels naggy post-purchase |
| Auth / save progress | Guest → Save Progress → Apple/email → optional account | Copy promises cross-device sync that doesn't exist | Align copy to reality | P1 | Trust + App Store review |
| Scan | Photo/text/voice/DB → analysis → follow-up → save | Strong; confirmation + follow-up are excellent | Food DB path dead in Release (code) | Fix backend (code report); add no-results polish | P1 | Broken capability surfaces in UI |
| Failure | Scan fail → retry / manual / database | Good recovery options | Ensure all three equally prominent; friendly copy | P2 | Reduce abandonment after a failed scan |
| Profile / settings | Profile → account / privacy / subscription / tools | Clear | Account screen is dense (debug + states) | Tighten grouping | P2 | Scannability |

---

## 8. Copywriting Improvement Review

Tone target: calm, warm, premium, non-judgmental, protein-first, not AI-hype, never fear/shame.

| Screen | Current copy | Issue | Better copy suggestion | Priority |
|---|---|---|---|---|
| Scan-quota paywall | "Scan Limit Reached" + red ⚠️ | Alarmist; punishes the user | "You've used all 5 free scans this week" (calm) + "Go unlimited with Pro" | P1 |
| Scan-quota dismiss | "Maybe Later" | Inconsistent w/ Paywall's "Continue with free plan" | Standardize: "Not now" everywhere | P2 |
| Save Progress (create account) | "Secure your data and sync across devices." | **Untrue** — no meal cloud sync | "Keep your account and Pro access safe." | P1 |
| Subscription success | "Create an account to protect your profile … on our servers." | Overstates server backup | "Add an account so your Pro access follows you." | P1 |
| Subscription success title flow | "You're Pro!" → "Continue to Pro dashboard" → re-prompt | Double account ask | Keep "You're Pro!"; single soft "Add account (optional)" | P2 |
| Welcome | "Eat smarter. Live stronger." | Good — keep | (keep) | — |
| Today coach card (loading) | "Loading coach insight…" | Reads unfinished | Use shimmer/skeleton, no literal loading text | P2 |
| Today coach error | "Couldn't load your coach tip. Check your connection and try again." | OK; slightly long | "Coach tip unavailable — pull to refresh." | P3 |
| Paywall headline | "Hit your protein goal without manual tracking." | Strong — keep | (keep) | — |
| Meal result save CTA | "Looks right — Save meal" | Good, human — keep | (keep) | — |
| Backend error (meal) | "Meal scans use Supabase, not a device OpenAI key. Add Supabase URL + anon key in Profile → Developer…" | **Developer-facing text shown to users** | User-safe: "Couldn't analyze right now. Please try again." (log details in Debug) | P1 |
| Unauthorized error | "Guest sign-in failed. In Supabase enable Anonymous sign-ins…" | Dev instructions leaking to users | "Couldn't connect. Check your internet and try again." | P1 |
| Food search failure | "Food search failed. Add a USDA API key in Profile → Developer." | Dev leak | "Search is unavailable right now." | P1 |
| Permission (camera) | "Camera permission is only asked when you choose photo scan." | Good, reassuring — keep | (keep) | — |
| Restore | "No active subscription found." | Fine | (keep) | — |

**Cross-cutting copy rule:** several `LocalizedError` descriptions in services are written for the **developer** (mention Supabase/USDA/Developer panel). In Release these can surface to real users. Replace user-visible strings with calm, non-technical copy; keep diagnostics behind `#if DEBUG`.

---

## 9. Conversion / Paywall UX Review

| Screen / gate | Current UX | Conversion /10 | Risk | Improvement | Priority |
|---|---|---:|---|---|---|
| Main paywall | Yearly default, savings %, trial, restore, legal, continue-free | 8.5 | Price won't render if products fail to load (fallback string) | Hide price until loaded; keep else | P2 |
| Scan-quota paywall | Red alarm, usage bar, then taps through to main paywall | 5 | Alarm tone + extra tap kills momentum | Warm framing + **inline** "Start Free Trial"; keep benefits | P1 |
| Trial ending prompt | Countdown + benefits, StoreKit-driven | 7.5 | Could feel pushy | Calm reminder tone; one clear action + dismiss | P2 |
| Subscription success | Celebration + benefits + account nudge | 7 | Double account ask | Single soft optional account step | P2 |
| Save progress | Three paths, trial recommended first | 8 | "sync" overpromise | Fix copy (see §8) | P1 |
| Manage subscription | Glass cancel-flow cards | 8 | — | Keep | P3 |
| Restore placement | Welcome, Sign-in, Account, both paywalls | 8.5 | — | Good coverage — keep | — |
| Pro feature gates | `ProFeatureGate` on Coach; gates in Today/Meals/MealResult/ManageSub | 7.5 | Inconsistent benefit framing across entry points | Unify gate copy + single benefits list reused everywhere | P2 |

**Answers to the checklist:**
- **Right time?** Main paywall yes (premium action/quota). Quota paywall fires correctly but is styled as an error.
- **Benefits clear?** Yes, but the benefit list differs slightly between Paywall / Quota / Success / Gate — unify.
- **Trial explained?** Yes — driven by real StoreKit intro offer (`renewalDisclosure`). Good.
- **Pricing clean?** Yes, `displayPrice` + per-month equivalent + savings %.
- **Yearly vs monthly clear?** Yes — yearly default, "Best value" badge.
- **Continue Free visible?** Yes on both (wording inconsistent).
- **Restore visible?** Yes, broadly.
- **Terms/Privacy visible?** Yes (`SubscriptionLegalLinksView`).
- **Premium not scammy?** Main paywall yes; quota paywall's red alarm undercuts this.
- **Consistent across entry points?** Mostly; unify benefit copy and dismiss labels.

---

## 10. Accessibility / Usability Review

| Area | Issue | Screen/file | Recommended fix | Priority |
|---|---|---|---|---|
| Dynamic Type | **All fonts use `.custom(family, size:)` with fixed sizes — no scaling** | `Theme/AppTypography.swift` | Use `.custom(_:size:relativeTo:)` to bind each token to a text style | **P1** |
| VoiceOver labels | Icon-only buttons (xmark close on Paywall/SaveProgress) lack explicit labels | `PaywallView`, `SaveProgressView` | Add `.accessibilityLabel("Close")` | P2 |
| Contrast | `textTertiary` / muted captions on warm bg may fail 4.5:1 | theme usages | Verify contrast; darken tertiary if needed | P2 |
| Tap targets | Most ≥44pt; small text buttons ("See All", "Terms/Privacy") borderline | Today, SaveProgress | Ensure ≥44pt hit area | P2 |
| Loading states | Literal "Loading coach insight…"/"Thinking…" text | `TodayView`, `CoachView` | Skeleton shimmer / animated dots | P2 |
| Error readability | Developer-oriented error strings can reach users | services | User-safe copy (see §8) | P1 |
| Keyboard | Numeric onboarding fields + manual log need keypad/done bar | `AuthFlowView.profilePage`, `ManualMealLogView` | `.keyboardType(.numberPad)` + toolbar Done | P2 |
| Small screens | Long screens (MealResult, SaveProgress) on SE — verify | those views | Test SE; sticky primary CTA where useful | P2 |
| Reduce Motion | Spring/bounce/breathing-glow animations | Splash, FAB, Success | Respect `accessibilityReduceMotion` | P3 |
| Color-only meaning | Red usage bar / quota state communicated mainly by color | `ScanQuotaPaywallView` | Pair with text/icon (already partly) | P3 |

---

## 11. Design System Improvement Review

| Component / token | Current status | Issue | Improvement | Priority |
|---|---|---|---|---|
| Typography tokens | Comprehensive, token-faithful | **No Dynamic Type binding** | Add `relativeTo:` per token | P1 |
| Color tokens | Match spec closely | Base background `#FBF9F4` vs token `#fcf9f8` | Align if desired | P3 |
| Glass cards | `GlassCard` used widely | Risk of overuse / readability over busy bg | Audit contrast on glass; reserve for hero cards | P2 |
| Macro pills | `MacroPill` present | Spec interactions (tap-expand, sparkle bloom, haptic) not implemented | Add later for delight | P3 |
| Scan FAB | Breathing glow + spring | Verify matches interaction spec §1 (rotating rim when scanning) | Add active-state rim | P3 |
| Progress ring | `ProteinArcRing` glass + gradient | Strong | Keep | P3 |
| Toasts | `ToastCenter`/`KineticToastHost` | Consistent | Keep | P3 |
| Confirmation dialogs | `kineticConfirmationDialog` | Consistent | Keep | P3 |
| Buttons | `PrimaryButtonStyle`/`SecondaryButtonStyle` (+pill variants) | Mostly consistent | Audit pill vs non-pill usage for consistency | P2 |
| Brand mark | leaf.fill (Splash/SaveProgress) vs fork.knife (Welcome) | Inconsistent identity | Pick one mark app-wide; match app icon | P2 |
| Dismiss copy | "Maybe Later" vs "Continue with free plan" vs "Skip for now" | Inconsistent | Standardize dismiss language | P2 |
| Coach typing | Plain "Thinking…" bubble | Spec wants wave-dots | Animated indicator | P2 |
| Empty states | Mostly text cards | Some have illustration, some don't | Consistent empty-state pattern | P3 |

**Cohesion verdict:** the system is genuinely cohesive — same primitives, same spacing, same palette across 40+ screens. The drift is small (brand mark, dismiss copy, a few unimplemented spec micro-interactions).

---

## 12. Missing or Weak Empty / Error / Loading States

| State type | Where weak | Current | Improve to |
|---|---|---|---|
| Loading | Today coach card | "Loading coach insight…" text | Skeleton shimmer |
| Loading | Coach reply | "Thinking…" bubble | Animated wave dots |
| Loading | Paywall price | Fallback hardcoded price string | Hide price until products load |
| Error | Meal scan / coach / food search | Developer-facing strings | Calm user copy; diagnostics in Debug |
| Error | Food search | "Add USDA key in Developer" | "Search unavailable right now" |
| Empty | Saved meals / grocery / food no-results | Present, mostly text | Consistent illustrated empty pattern |
| Empty | Today meals | Strong (actionable card) | Keep as the model for others |
| Success | Subscription success | Strong, but double account ask | Single soft account step |

---

## 13. Improvements by Priority

| Priority | Improvement | Screen/file | Why it matters | Effort | Notes |
|---|---|---|---|---|---|
| P0 | (Sign-in logic) — UX is fine, fix is in code report | `SignInView`/auth | Returning users blocked | Medium | Tracked in `FULL_CODEBASE_ANALYSIS_REPORT.md` |
| P1 | Reframe scan-quota paywall from alarm → warm upsell with inline trial CTA | `ScanQuotaPaywallView.swift` | Highest-intent conversion moment | Medium | Remove red ⚠️; one-tap to trial |
| P1 | Fix overpromising "sync across devices / on our servers" copy | `SaveProgressView`, `SubscriptionSuccessView`, `DataPrivacyView` | Trust + App Store review | Small | Match real (device-only) scope |
| P1 | Replace developer-facing error strings shown to users | `MealAnalysisService`, `SupabaseAuthClient`, `USDAFoodSearchService` errors | Looks broken/leaky in Release | Small–Med | Keep diagnostics in `#if DEBUG` |
| P1 | Add Dynamic Type scaling to typography tokens | `AppTypography.swift` | Accessibility baseline | Medium | `relativeTo:` per token |
| P2 | Skeleton/shimmer for Today coach card; wave-dots for Coach typing | `TodayView`, `CoachView` | Premium polish | Medium | Per interaction spec |
| P2 | Unify brand mark across Splash/Welcome/SaveProgress | those views | Brand consistency | Small | Match app icon |
| P2 | Standardize dismiss + benefit copy across paywalls/gates | paywall views, `ProFeatureGate` | Consistency + conversion | Small | One benefits list reused |
| P2 | Remove double account prompt after purchase | `SubscriptionSuccessView` | Reduce post-purchase friction | Small | Single optional nudge |
| P2 | Numeric keypad + Done bar on onboarding/manual fields | `AuthFlowView`, `ManualMealLogView` | Input friction | Small | — |
| P2 | Add `accessibilityLabel` to icon-only buttons; verify contrast & tap targets | multiple | Accessibility | Small | — |
| P2 | Unify forgot-password to single Supabase path with clear confirmation | `ResetPasswordView` | Clarity | Medium | Logic-adjacent |
| P2 | Insights chart interactivity (scrubber/tooltip) | `InsightsTrendsView` | Matches spec, feels premium | Medium | Spec §5 |
| P3 | Optional "calculating your plan" interstitial; numbers animation on PlanReady | onboarding | Delight | Small–Med | Non-blocking |
| P3 | Macro-pill tap-expand + sparkle bloom; FAB rotating-rim active | components | Delight | Medium | Spec §1/§2 |
| P3 | Align background hue to token; consistent illustrated empty states | theme, empties | Polish | Small | — |
| P3 | Respect Reduce Motion | animated screens | Accessibility nicety | Small | — |

---

## 14. Recommended Next Design Sprint

A focused ~1-week design-polish sprint (no new screens, no backend changes):

1. **Conversion polish (P1):** rebuild the scan-quota screen as a calm, premium upsell with an inline "Start Free Trial," and unify benefit/dismiss copy across all paywalls and the Pro gate.
2. **Truthful copy pass (P1):** scrub every user-visible string that implies cloud sync/server backup; rewrite all developer-facing error messages into calm user copy (diagnostics stay in Debug).
3. **Accessibility baseline (P1):** bind typography tokens to Dynamic Type; add VoiceOver labels to icon buttons; verify contrast and tap targets.
4. **Premium micro-interactions (P2):** skeleton loaders (Today coach card), animated coach typing dots, FAB active-state rim, brand-mark unification.
5. **Post-purchase + input friction (P2):** remove the double account prompt; add numeric keypad/Done bars.

Outcome: moves the app from ~7.5 to ~9/10 on premium feel and App Store readiness without touching architecture.

---

## 15. Screens Not Worth Changing Yet

These are already strong — leave them alone for now:

- **Welcome** (`AuthFlowView.welcomePage`)
- **Meal Result** (`MealResultView.swift`)
- **Main Paywall** (`PaywallView.swift` / `SubscriptionPlansSection.swift`)
- **Add First Meal** (`AddFirstMealView.swift`)
- **Today Dashboard** layout (only the coach-card loader needs a skeleton)
- **Meals / Saved Meals**, **Grocery**, **Recipe Calculator**, **Weekly Report**, **Weight Tracking**, **Reminders**, **Goals Settings**, **Manage Subscription**, **Toasts**, **Confirmation Dialogs**, **Tab bar / FAB**

---

*Design/UX review only — no code, screens, features, or backend/auth/StoreKit logic were modified. Visual scores are from static reading of SwiftUI + prototype comparison and should be confirmed on-device (especially Dynamic Type, contrast, and small-screen layout).*
