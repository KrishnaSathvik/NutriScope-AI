# P0 Backend Alignment — Fix Plan & Status

**Date:** 2026-06-23  
**Based on:** [MASTER_IMPLEMENTATION_AUDIT.md](MASTER_IMPLEMENTATION_AUDIT.md)  
**Scope:** Backend alignment sprint (no UI/onboarding changes)

---

## Summary

| Area | Status after this sprint |
|------|------------------------|
| Anonymous auth policy (repo) | **Aligned** — `config.toml` + docs |
| Production Supabase config path | **Improved** — Info.plist injection via `Backend.xcconfig` |
| `analyze-meal` anonymous JWT | **Verified in code** — deploy + dashboard still required |
| Device OpenAI in production | **Documented** — edge functions not built yet |
| README / stale docs | **Updated** |

**You still need to do manually:** Create Supabase project, enable Anonymous in dashboard, deploy edge function, create local `Backend.xcconfig`, test Release guest scan.

---

## What changed (this sprint)

### 1. Anonymous Supabase auth — repo alignment

| File | Change |
|------|--------|
| [`supabase/config.toml`](supabase/config.toml) | `enable_anonymous_sign_ins = true` + comment |
| [`doc/BACKEND_SETUP.md`](doc/BACKEND_SETUP.md) | Anonymous **ON**; guest-first model documented; curl verification steps |
| [`NutriscopeAI/Services/BackendAuthBootstrap.swift`](NutriscopeAI/Services/BackendAuthBootstrap.swift) | No code change — already calls `signInAnonymously()` |

**Action required in Supabase dashboard:** Authentication → Providers → **Anonymous → Enable** (must match repo).

### 2. Production Supabase config (no secrets in git)

| File | Change |
|------|--------|
| [`NutriscopeAI/Resources/Shared.xcconfig`](NutriscopeAI/Resources/Shared.xcconfig) | **New** — optional `#include? "Backend.xcconfig"` |
| [`NutriscopeAI/Resources/Backend.xcconfig.example`](NutriscopeAI/Resources/Backend.xcconfig.example) | `INFOPLIST_KEY_SUPABASE_*` for Release injection |
| [`NutriscopeAI/Services/BackendConfig.swift`](NutriscopeAI/Services/BackendConfig.swift) | Reads env → **Info.plist** → UserDefaults |
| [`NutriscopeAI.xcodeproj/project.pbxproj`](NutriscopeAI.xcodeproj/project.pbxproj) | Links `Shared.xcconfig` to project Debug/Release |

**Setup:**

```bash
cp NutriscopeAI/Resources/Backend.xcconfig.example NutriscopeAI/Resources/Backend.xcconfig
# Edit with real SUPABASE_URL and SUPABASE_ANON_KEY
```

`Backend.xcconfig` remains gitignored.

### 3. `analyze-meal` edge function

| File | Change |
|------|--------|
| [`supabase/functions/analyze-meal/index.ts`](supabase/functions/analyze-meal/index.ts) | Comment: accepts anonymous JWTs |
| [`doc/BACKEND_SETUP.md`](doc/BACKEND_SETUP.md) | Deploy steps + curl test |

Function logic unchanged: `auth.getUser()` validates any valid JWT including `is_anonymous: true`. `OPENAI_API_KEY` only from `Deno.env` (Supabase secrets).

### 4. Documentation cleanup

| File | Change |
|------|--------|
| [`README.md`](README.md) | Supabase proxy architecture; removed stale direct-OpenAI + lifetime product refs |
| [`NutriscopeAI/Services/MealAnalysisService.swift`](NutriscopeAI/Services/MealAnalysisService.swift) | Removed unused `hasProAccess` factory parameter |

### 5. Not changed (by design)

- Onboarding flow
- No new screens
- No forced signup before first scan
- Coach / tips still use device OpenAI (migration plan below)
- Save Progress copy (P1 — Option B recommended for MVP)

---

## Device-side OpenAI paths (production risk)

These still call `OpenAIClient` → `Secrets.openAIAPIKey` and **break in Release** without a user-entered key:

| Feature | File(s) | Edge function needed |
|---------|---------|----------------------|
| Coach chat | `OpenAICoachService.swift`, `CoachView.swift` | `coach-chat` |
| Daily coach tip | `OpenAICoachService.dailyTip`, `TodayView.swift` | `coach-tip` |
| Follow-up advice refresh | `OpenAICoachService.updatedAdvice`, `MealResultView.swift` | `coach-tip` or reuse `analyze-meal` |
| Tomorrow plan AI | `OpenAICoachService.buildTomorrowPlan`, `TomorrowProteinPlanView.swift` | `coach-chat` (structured JSON) |
| Grocery AI suggestions | `OpenAICoachService.grocerySuggestions`, `GroceryListView.swift` | `coach-chat` |
| Whisper transcription | `WhisperTranscriptionService.swift` | **Unused** — scan uses on-device `SpeechTranscriptionService` |

### Recommended edge function layout (Step 2 sprint)

**Preferred for MVP:** one combined function with an `action` field (simpler deploy):

```
supabase/functions/
├── analyze-meal/     ✅ exists — meal vision + text analysis
└── ai-proxy/         NEW — action: coach_chat | daily_tip | grocery_suggestions | tomorrow_plan | followup_advice
```

Alternative (split): separate `coach-chat` and `coach-tip` functions — only if `ai-proxy` grows too large.

**iOS pattern (mirror `ProxyMealAnalysisService`):**

1. `BackendConfig.aiProxyURL`
2. `ProxyAIService` — POST `{ action, ...payload }` with `Authorization: Bearer <jwt>`
3. `OpenAICoachService` delegates to proxy when `BackendConfig.isReleaseBuild && isSupabaseConfigured`
4. Keep direct OpenAI path **Debug-only** (`#if DEBUG` + dev key)

---

## Remaining P0 (manual / next sprint)

### Before serious E2E testing

- [ ] **Supabase dashboard:** Enable Anonymous sign-ins
- [ ] **Deploy:** `supabase functions deploy analyze-meal` + `OPENAI_API_KEY` secret
- [ ] **Local config:** Create `Backend.xcconfig` with production URL/key
- [ ] **Verify:** curl anonymous signup → analyze-meal (see BACKEND_SETUP.md)
- [ ] **iOS Release test:** Fresh install → guest → first scan → meal result
- [ ] **Build edge functions** for coach/tip (Step 2 sprint)

### P1 — before TestFlight

- [x] Save Progress copy — no sync promise until cloud sync ships (`SaveProgressView`, `SubscriptionSuccessView`)
- [ ] Supabase password reset email
- [ ] Profile upsert to `ios_user_profiles`
- [ ] Legal URLs live
- [ ] App Store Connect products + 7-day intro offer

---

## Exact next steps (recommended order)

### Step 1 — You (ops, ~30 min)

1. Create / open iOS Supabase project
2. Run `001_ios_user_profiles.sql`
3. Enable Anonymous + Apple + Email auth
4. `supabase secrets set OPENAI_API_KEY=...`
5. `supabase functions deploy analyze-meal`
6. Run curl test from BACKEND_SETUP.md
7. Copy `Backend.xcconfig.example` → `Backend.xcconfig`, fill values
8. Archive Release build → test guest scan on device

### Step 2 — Agent sprint (AI proxy) — **after Release guest scan passes**

1. Add `ai-proxy` edge function with `action` dispatch
2. Add `ProxyAIService` + wire `OpenAICoachService`
3. Gate device OpenAI to Debug only
4. Re-run Release build; verify Coach + Today tip without device API key

### Step 3 — Agent sprint (auth hardening)

1. Supabase `resetPasswordForEmail` in `ResetPasswordView`
2. `ios_user_profiles` upsert on sign-up
3. Save Progress copy: *"Create an account to protect your profile and subscription access."*
4. `SupabaseAuthClient.signOut()` on Profile sign-out

### Step 4 — App Store Connect

Products, intro offer, sandbox purchase test, restore test.

### Step 5 — Cloud sync (phased)

1. Profile/settings sync
2. Meal records
3. Saved meals, weights, grocery
4. Server-side scan usage (optional)

---

## Build status

```bash
xcodebuild -scheme NutriscopeAI -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Run after pulling these changes to confirm project still compiles with `Shared.xcconfig` linked.

---

## Files touched in this sprint

```
supabase/config.toml
supabase/functions/analyze-meal/index.ts
doc/BACKEND_SETUP.md
README.md
P0_FIX_PLAN.md (this file)
NutriscopeAI/Resources/Shared.xcconfig (new)
NutriscopeAI/Resources/Backend.xcconfig.example
NutriscopeAI/Services/BackendConfig.swift
NutriscopeAI/Services/MealAnalysisService.swift
NutriscopeAI/App/AppState.swift
NutriscopeAI.xcodeproj/project.pbxproj
```
