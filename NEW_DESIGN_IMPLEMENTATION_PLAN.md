# Nutriscope AI — New Design Implementation Plan

**Created:** 2026-06-23  
**Source of truth:** `new stitch designs/`  
**Legacy reference only:** `old stich designs/`, `other pages/`

---

## 1. New Design Source of Truth

| Item | Path |
|------|------|
| **Primary design folder** | `new stitch designs/` |
| **Design tokens** | `new stitch designs/nutriscope_ai_design_tokens.md` |
| **Component spec** | `new stitch designs/nutriscope_ai_component_spec.md` |
| **Interaction spec** | `new stitch designs/nutriscope_ai_interaction_spec.md` |
| **Kinetic Harvest palette** | `new stitch designs/kinetic_harvest_1/DESIGN.md`, `kinetic_harvest_2/DESIGN.md` |
| **Total HTML prototypes** | 170 `code.html` files across 170 subfolders |
| **Canonical screens (deduped)** | 48 feature areas |

**Canonical variant selection rule:** Prefer `*_ios_native_final` → `*_next_gen_final` → `*_ios_native` → `*_next_gen` → branded variants.

---

## 2. Legacy / Reference-Only Folders

| Folder | Status | Notes |
|--------|--------|-------|
| `old stich designs/` | Legacy reference only | 76 HTML files; superseded by `new stitch designs/` |
| `old stich designs/stitch_designs/` | Legacy reference only | Previous Stitch exports |
| `old stich designs/stitch_proteinplate_ai_tracker*` | Legacy reference only | Tracker-era prototypes |
| `other pages/` | Legacy reference only | Misc tracker variants (1)–(4) |
| `stitch_designs/` (repo root) | **Removed** | Was moved to `old stich designs/` |
| `CANONICAL_SCREENS.md` | **Outdated** | References old `stitch_designs/` paths; superseded by this plan |

Do **not** use old folders as primary reference unless a screen is missing from `new stitch designs/`.

---

## 3. Phase 1 — Design File Inventory (Canonical Screens)

| Design file (canonical) | Folder | Screen/feature | New or old | Should implement? | App screen exists? | Matching SwiftUI file | Status | Notes |
|-------------------------|--------|----------------|------------|-------------------|--------------------|-----------------------|--------|-------|
| Splash | — | Splash / brand intro | — | Yes | Yes | `SplashView.swift` | Partially implemented | No HTML prototype; adapt from design system |
| `onboarding_welcome_ios_native_2` | new | Welcome / auth intro | New | Yes | Yes | `AuthFlowView.swift` (welcomePage) | Implemented but not redesigned | 11 welcome variants; this is canonical |
| `goal_setting_next_gen` | new | Onboarding goals | New | Yes | Yes | `AuthFlowView.swift` (goalPage) | Partially implemented | Uses KineticGoalCard; needs next-gen layout |
| `onboarding_preferences` | new | Diet preferences | New | Yes | Yes | `AuthFlowView.swift` (dietPage) | Partially implemented | |
| `onboarding_profile_ios_native` | new | Profile basics (onboarding) | New | Yes | Yes | `AuthFlowView.swift` (targetPage profile section) | Partially implemented | Profile fields embedded in target step |
| `onboarding_protein_target_branded` | new | Protein target locked | New | Yes | Yes | `AuthFlowView.swift` (targetPage) | Partially implemented | OnboardingTargetHero present |
| `onboarding_calculating_your_plan` | new | Calculating plan loading | New | Optional | No (inline) | `AuthFlowView.swift` | Missing | No dedicated loading screen |
| `onboarding_success_branded` | new | Onboarding complete | New | Optional | No | — | Missing | Flow goes directly to first meal |
| `ai_meal_scan` | new | Add first meal / scan entry | New | Yes | Yes | `AddFirstMealView.swift`, `ScanMealView.swift` | Partially implemented | |
| `scan_tutorial_next_gen` | new | First scan tutorial | New | Yes | Yes | `FirstScanTutorialView.swift` | Partially implemented | |
| `camera_permission_ios_native_final` | new | Camera permission | New | Yes | Yes | `CameraPermissionPromptView.swift` | Partially implemented | |
| `mic_permission_prep_ios_native_2` | new | Mic permission | New | Yes | Yes | `KineticPermissionPromptView.swift` | Partially implemented | |
| `notification_permission_ios_native_1` | new | Notification permission | New | Yes | Yes | `NotificationPermissionPromptView` | Partially implemented | |
| `voice_listening_ios_native_final` | new | Voice listening overlay | New | Yes | Yes | `VoiceListeningOverlay.swift` | Partially implemented | |
| `meal_analysis_next_gen` | new | Meal scan results | New | Yes | Yes | `MealResultView.swift` | Partially implemented | |
| `post_scan_success_next_gen_v3` | new | Post-save success | New | Yes | Yes | `PostScanSuccessView.swift` | Partially implemented | Has confetti |
| `scan_failed_ios_native_final` | new | Scan failed (camera) | New | Yes | Yes | `ScanFailedView.swift` | Partially implemented | |
| `scan_analysis_failed_ios_native` | new | Analysis failed / follow-up | New | Yes | Yes | `ScanFailedView.swift`, `FollowUpQuestionsView.swift` | Partially implemented | |
| `manual_meal_log_next_gen` | new | Manual meal log | New | Yes | Yes | `ScanMealView.swift` (text mode) | Partially implemented | |
| `dashboard_today_ios_native_final` | new | Today dashboard | New | Yes | Yes | `TodayView.swift` | Implemented but not redesigned | ProteinArcRing + CoachInsightCard exist |
| `meal_history_next_gen` | new | Meal history (week) | New | Yes | Yes | `MealsView.swift` | Partially implemented | |
| `meal_history_monthly_ios_native` | new | Meal history (month) | New | Yes | Yes | `MealsView.swift` | Partially implemented | |
| `empty_saved_meals_ios_native_2` | new | Saved meals empty | New | Yes | Yes | `MealsView.swift` (empty) | Partially implemented | |
| `coach_next_move_next_gen` | new | Coach home / next move | New | Yes | Yes | `CoachView.swift` | Partially implemented | |
| `coach_chat_ios_native` | new | Coach chat thread | New | Yes | Yes | `CoachView.swift` | Partially implemented | KineticCoachChatBubble exists |
| `coach_refined_maintenance_pivot` | new | Course correction state | New | Yes | Yes | `CoachView.swift` | Partially implemented | State-dependent |
| `tomorrow_s_plan_ios_native` | new | Tomorrow protein plan | New | Yes | Yes | `TomorrowProteinPlanView.swift` | Partially implemented | |
| `food_search_next_gen` | new | Food database search | New | Yes | Yes | `FoodSearchView.swift` | Partially implemented | |
| `food_search_no_results` | new | Food search empty | New | Yes | Yes | `FoodSearchView.swift` | Partially implemented | |
| `grocery_list_ios_native` | new | Grocery list | New | Yes | Yes | `GroceryListView.swift` | Partially implemented | |
| `grocery_empty_state_ios_native_1` | new | Grocery empty | New | Yes | Yes | `GroceryListView.swift` | Partially implemented | |
| `recipe_calculator_next_gen` | new | Recipe calculator | New | Yes | Yes | `RecipeCalculatorView.swift` | Partially implemented | |
| `insights_trends_next_gen` | new | Insights / trends | New | Yes | Yes | `InsightsTrendsView.swift` | Partially implemented | Was v2; now implemented |
| `weekly_progress_next_gen_final` | new | Weekly report | New | Yes | Yes | `WeeklyReportView.swift` | Partially implemented | |
| `weight_trends_next_gen` | new | Weight tracking | New | Yes | Yes | `WeightTrackingSection.swift` | Partially implemented | |
| `user_profile_settings_ios_native` | new | Profile home | New | Yes | Yes | `ProfileView.swift`, `ProfileAccountView.swift` | Partially implemented | |
| `privacy_data_ios_native_final` | new | Data & privacy | New | Yes | Yes | `DataPrivacyView.swift` | Partially implemented | |
| `reminders_notifications` | new | Reminder settings | New | Yes | Yes | `ReminderSettingsView.swift` | Partially implemented | |
| `goal_setting_next_gen` | new | Goals settings (profile) | New | Yes | Yes | `ProfileGoalsSettingsView.swift` | Partially implemented | |
| `nutriscope_pro_paywall_ios_native` | new | Pro paywall | New | Yes | Yes | `PaywallView.swift` | Partially implemented | StoreKit prices dynamic |
| `scan_quota_exhausted_paywall` | new | Scan quota paywall | New | Yes | Yes | `ScanQuotaPaywallView.swift` | Partially implemented | |
| `subscription_success_next_gen_v2` | new | Subscription success | New | Yes | Yes | `SubscriptionSuccessView.swift` | Partially implemented | |
| `manage_subscription_ios_native` | new | Manage subscription | New | Yes | Yes | `ManageSubscriptionView.swift` | Partially implemented | |
| `trial_ending_soon_ios_native` | new | Trial ending prompt | New | P2 | No dedicated view | `PaywallView.swift` (inline) | Missing | Design exists; no dedicated screen |
| `authentication_next_gen` | new | Sign in | New | Yes | Yes | `SignInView.swift` | Partially implemented | |
| `sign_up_trial_start` | new | Sign up | New | Yes | Yes | `SignUpView.swift` | Partially implemented | |
| `forgot_password_ios_native_2` | new | Forgot password | New | Yes | Yes | `ResetPasswordView.swift` | Partially implemented | |
| `account_choice` | new | Save progress / account choice | New | Yes | Yes | `SaveProgressView.swift` | Partially implemented | |
| `confirmation_dialogs` | new | Confirmation dialogs | New | Yes | Partial | Alert modifiers app-wide | Missing | No shared dialog component |
| `toast_notifications` | new | Toast system | New | P2 | No | — | Missing | No global toast component |
| `social_meal_estimator_ai` | new | Mystery meal estimation | New | No (v2) | No | — | Future/v2 | Not in current flow |
| `subscription_legal_links` | — | Legal links on paywall | — | Yes | Yes | `SubscriptionLegalLinksView.swift` | Implemented | No HTML prototype |
| `nutriscope_ai` | new | Design system index | New | Reference | — | `AppTheme.swift` | Reference | Meta folder |
| Asset folders (PNG only) | new | Illustrations | New | Reference | Partial | Various | Not applicable | Food photo, scan-failed illustration |

### Duplicate / Legacy Variant Folders (not canonical — 122 folders)

All other folders in `new stitch designs/` are alternate variants. Examples: `dashboard_today_1`, `dashboard_today_2`, `onboarding_welcome_1`, `post_scan_success`, `nutriscope_pro_paywall`, etc. Status: **Legacy reference only** within the new folder (use canonical pick above).

---

## 4. Phase 2 — New Design vs Current App Comparison

| New design screen | Current SwiftUI file | Implemented already? | Needs redesign? | Missing components | Flow impact | Priority |
|-------------------|---------------------|----------------------|-----------------|-------------------|-------------|----------|
| Splash | `SplashView.swift` | Yes | Yes | Radial gradient bg, brand lockup | None | P1 |
| Welcome | `AuthFlowView.swift` | Yes | Yes | iOS native hero layout, pill CTAs | None | P0 |
| Goals | `AuthFlowView.swift` | Yes | Yes | Next-gen card grid | None | P0 |
| Diet prefs | `AuthFlowView.swift` | Yes | Yes | Chip grid polish | None | P0 |
| Protein target | `AuthFlowView.swift` | Yes | Yes | Glass hero card, coach note | None | P0 |
| Calculating plan | — | No | Yes | Loading animation screen | Low | P3 |
| Onboarding success | — | No | Optional | Celebration interstitial | Low | P3 |
| Add first meal | `AddFirstMealView.swift` | Yes | Yes | Scan CTA prominence | None | P0 |
| First scan tutorial | `FirstScanTutorialView.swift` | Yes | Yes | Next-gen tutorial steps | None | P1 |
| Camera permission | `CameraPermissionPromptView.swift` | Yes | Yes | Native final layout | None | P1 |
| Mic permission | `KineticPermissionPromptView.swift` | Yes | Yes | Native final layout | None | P2 |
| Notification permission | `NotificationPermissionPromptView` | Yes | Yes | Native final layout | None | P2 |
| Scan meal | `ScanMealView.swift` | Yes | Yes | Camera chrome, voice FAB | None | P0 |
| Voice listening | `VoiceListeningOverlay.swift` | Yes | Yes | Waveform, native final | None | P1 |
| Meal result | `MealResultView.swift` | Yes | Yes | Macro bento, coaching card | None | P0 |
| Post-scan success | `PostScanSuccessView.swift` | Yes | Yes | Next-gen v3 celebration | None | P1 |
| Scan failed | `ScanFailedView.swift` | Yes | Yes | Native final illustration | None | P1 |
| Analysis failed | `FollowUpQuestionsView.swift` | Yes | Yes | Native follow-up UI | None | P1 |
| Today dashboard | `TodayView.swift` | Yes | Yes | Glass cards, streak pill, tab bar FAB glow | None | P0 |
| Meals history | `MealsView.swift` | Yes | Yes | Next-gen weekly arc | None | P1 |
| Saved meals empty | `MealsView.swift` | Yes | Yes | Native empty state | None | P2 |
| Coach | `CoachView.swift` | Yes | Yes | Next-gen next move + chat | None | P1 |
| Tomorrow plan | `TomorrowProteinPlanView.swift` | Yes | Yes | iOS native plan cards | None | P1 |
| Food search | `FoodSearchView.swift` | Yes | Yes | Next-gen search UI | None | P2 |
| Grocery list | `GroceryListView.swift` | Yes | Yes | Protein-first list | None | P2 |
| Recipe calculator | `RecipeCalculatorView.swift` | Yes | Yes | Next-gen macro calc | None | P2 |
| Insights trends | `InsightsTrendsView.swift` | Yes | Yes | Chart interactions | None | P2 |
| Weekly report | `WeeklyReportView.swift` | Yes | Yes | Next-gen final charts | None | P2 |
| Weight tracking | `WeightTrackingSection.swift` | Yes | Yes | Trend chart polish | None | P2 |
| Profile | `ProfileView.swift` | Yes | Yes | iOS native settings layout | None | P1 |
| Data privacy | `DataPrivacyView.swift` | Yes | Yes | Native final export UI | None | P1 |
| Reminders | `ReminderSettingsView.swift` | Yes | Yes | Toggle list polish | None | P2 |
| Paywall | `PaywallView.swift` | Yes | Yes | iOS native paywall cards | **StoreKit** — prices dynamic | P0 |
| Scan quota paywall | `ScanQuotaPaywallView.swift` | Yes | Yes | Quota countdown UI | **Quota logic** | P0 |
| Subscription success | `SubscriptionSuccessView.swift` | Yes | Yes | Next-gen v2 celebration | None | P1 |
| Manage subscription | `ManageSubscriptionView.swift` | Yes | Yes | Native subscription mgmt | **StoreKit** | P1 |
| Trial ending | — | No | Yes | Dedicated trial banner/sheet | Paywall trigger | P2 |
| Sign in | `SignInView.swift` | Yes | Yes | Authentication next-gen | **Auth** | P1 |
| Sign up | `SignUpView.swift` | Yes | Yes | Trial-start framing | **Auth** | P1 |
| Forgot password | `ResetPasswordView.swift` | Yes | Yes | Native form | **Auth** | P2 |
| Save progress | `SaveProgressView.swift` | Yes | Yes | Account choice cards | **Optional auth** | P1 |
| Confirmation dialogs | — | Partial | Yes | Shared destructive dialog | Delete account | P2 |
| Toast notifications | — | No | Yes | Global toast component | Feedback UX | P3 |
| Social meal estimator | — | No | No | Full new feature | New backend scope | Future/v2 |

---

## 5. Missing New Design Screens / Pages

| Missing design screen/page | Design file path | Required for current app flow? | Current app equivalent? | Should implement now? | Priority | Reason |
|----------------------------|------------------|------------------------------|-------------------------|----------------------|----------|--------|
| Calculating your plan (loading) | `new stitch designs/onboarding_calculating_your_plan/` | No | Inline recalculation in target step | No | P3 | Nice-to-have; targets compute instantly |
| Onboarding success celebration | `new stitch designs/onboarding_success_branded/` | No | Skipped → first meal directly | No | P3 | Flow works without it |
| Trial ending soon prompt | `new stitch designs/trial_ending_soon_ios_native/` | No (Pro users only) | Paywall shown on premium actions | Later | P2 | Needs StoreKit trial-end detection |
| Toast notification system | `new stitch designs/toast_notifications/` | No | System alerts / inline messages | Later | P3 | Polish; not blocking core flow |
| Shared confirmation dialogs | `new stitch designs/confirmation_dialogs/` | Partial | Per-view `.alert()` modifiers | Later | P2 | Standardize delete/logout UX |
| Social meal estimator | `new stitch designs/social_meal_estimator_ai/` | No | Scan flow handles meals | No | Future/v2 | New feature; out of v1 scope |
| Splash screen prototype | — | Yes | `SplashView.swift` (code-only) | Adapt from system | P1 | No HTML; use design tokens |
| Subscription legal links | — | Yes | `SubscriptionLegalLinksView.swift` | Keep current | P2 | No prototype; required for App Store |

### Screens in app WITHOUT new design prototypes

| App screen | SwiftUI file | Adaptation strategy |
|------------|--------------|---------------------|
| Splash | `SplashView.swift` | Apply Kinetic Harvest tokens + radial gradient |
| Subscription legal links | `SubscriptionLegalLinksView.swift` | Match paywall typography/spacing |
| Pro feature gate | `ProFeatureGate.swift` | Match paywall card style |
| Follow-up questions (partial) | `FollowUpQuestionsView.swift` | Align with `scan_analysis_failed_ios_native` |
| Weight tracking (embedded) | `WeightTrackingSection.swift` | Use `weight_trends_next_gen` patterns |

---

## 6. Summary Counts

| Category | Count |
|----------|-------|
| Total new design files inspected | 170 |
| Canonical feature areas (deduped) | 48 |
| Implemented and redesigned | 0 (baseline — kinetic system exists but not aligned to ios_native_final) |
| Implemented but not redesigned | 38 |
| Partially implemented | 8 |
| Missing from app | 4 (calculating, onboarding success, trial ending, toast) |
| Future/v2 | 1 (social meal estimator) |
| Not applicable / duplicate | 122 variant folders + 2 asset-only folders |

---

## 7. Shared Design System Changes Needed

### Colors (from `nutriscope_ai_design_tokens.md` + `kinetic_harvest_1/DESIGN.md`)
- Align `background` → `#FBF9F4` / `#FCF9F8`
- Add `surfaceBright`, `surfaceContainer`, `secondaryContainer` (`#F7F2F2`)
- Add `glassBg` (white 70–80%), `glassBorder`
- Keep `coachOrange` `#F26B38`, `primary` `#A93702`, `proteinTeal` `#2D6A4F`

### Typography
- Hanken Grotesk primary; Inter for label-caps
- Add `display-lg` (40pt black), `headline-lg` (32pt bold)
- Standardize `label-caps` (10–12pt bold uppercase, 0.1em tracking)

### Spacing & Radii
- `marginMain` = 20pt (done)
- `radius-lg` = 24pt for cards (currently 16–20)
- `stack-lg` = 32pt between sections

### Components to create/update
| Component | Action |
|-----------|--------|
| `GlassCard` | Add blur + 24pt radius + soft shadow |
| `MacroPill` | New — 32pt capsule, highlight state |
| `ScanFAB` | Update tab bar center button with breathing glow |
| `KineticEmptyState` | Align with ios_native empty states |
| `KineticToast` | New — optional P3 |
| `KineticConfirmationDialog` | New — destructive action pattern |
| `PrimaryButtonStyle` | Pill radius 999, coach-orange shadow |
| `ProteinArcRing` | Gradient stroke, glow on progress |
| `NutriscopeTopBar` | Match dashboard native final |
| `OnboardingChrome` | Match ios_native progress header |
| Animation tokens | `nsStandardSpring`, `nsBouncySpring` |

---

## 8. Screens to Redesign (Implementation Order)

### Phase A — Design system (P0 foundation)
1. `AppTheme.swift` — tokens, radii, glass, animations
2. `AppTypography.swift` — display/headline tokens
3. `KineticComponents.swift` — GlassCard, MacroPill, FAB glow, empty states

### Phase B — Onboarding flow (P0)
4. `SplashView.swift`
5. `AuthFlowView.swift` — welcome, goals, diet, target
6. `AddFirstMealView.swift`

### Phase C — Core value loop (P0)
7. `ScanMealView.swift`, `FirstScanTutorialView.swift`
8. `MealResultView.swift`, `PostScanSuccessView.swift`
9. `ScanFailedView.swift`, `FollowUpQuestionsView.swift`
10. `TodayView.swift` + `RootView.swift` tab bar

### Phase D — Main tabs (P1)
11. `MealsView.swift`
12. `CoachView.swift`, `TomorrowProteinPlanView.swift`
13. `ProfileView.swift`, `ProfileAccountView.swift`, `DataPrivacyView.swift`

### Phase E — Monetization & auth (P0–P1)
14. `PaywallView.swift`, `ScanQuotaPaywallView.swift`
15. `SubscriptionSuccessView.swift`, `ManageSubscriptionView.swift`
16. `SignInView.swift`, `SignUpView.swift`, `ResetPasswordView.swift`, `SaveProgressView.swift`

### Phase F — Tools & reports (P2)
17. `FoodSearchView.swift`, `GroceryListView.swift`, `RecipeCalculatorView.swift`
18. `InsightsTrendsView.swift`, `WeeklyReportView.swift`, `WeightTrackingSection.swift`
19. `ReminderSettingsView.swift`, permission prompts

### Phase G — Polish (P2–P3)
20. Empty states pass, error states, loading states
21. Optional: trial ending sheet, toast system, confirmation dialog component

---

## 9. Risky Areas — Do Not Break

| Area | Files | Rule |
|------|-------|------|
| Root navigation gate | `RootView.swift`, `AppState.swift` | Gate only on `hasCompletedOnboarding` |
| Guest mode | `GuestModeManager.swift`, `AuthFlowView` | Auth optional before dashboard |
| Scan quota | `ScanQuotaManager.swift`, `ScanQuotaPaywallView` | 5-scan free limit unchanged |
| StoreKit | `SubscriptionManager.swift`, `PaywallView` | `Product.displayPrice` only; no hardcoded prices |
| Trial UI | `SubscriptionPlansSection` | Show trial only when StoreKit intro offer exists |
| Restore purchases | `AppState.restorePurchases()` | Keep on auth + paywall |
| Supabase auth | `BackendAuthBootstrap`, `SupabaseAuthClient` | Anonymous session for guests |
| Backend proxy | `ProxyAIService`, `MealAnalysisService` | No device OpenAI keys in Release |
| Delete account | `AccountDeletionService`, `DataPrivacyView` | Keep flow intact |
| Legal links | `SubscriptionLegalLinksView`, `AppLegalLinks` | Required for subscriptions |

---

## 10. Product Flow (Preserved)

```
Splash → Welcome → Goals → Diet → Target → Add First Meal → Scan/Log
  → Meal Result → Post-Save → Dashboard (guest OK)
  → [Premium action or quota hit] → Paywall → StoreKit → Subscription Success
  → [Optional] Save Progress / Sign Up
  → Premium or free dashboard
```

**Do not:** move signup before dashboard, move paywall before first value, or gate root on subscription.

---

## 11. Build Verification Command

```bash
xcodebuild -scheme NutriscopeAI -destination 'platform=iOS Simulator,name=iPhone 17' build
```

---

*Plan complete. Proceed to Phase 6+ implementation per section 8 order.*
