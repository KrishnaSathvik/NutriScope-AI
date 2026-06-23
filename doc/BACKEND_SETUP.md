# iOS Backend Setup

The **Nutriscope AI iOS app** uses its **own dedicated Supabase project** — separate from the [nutriscope web app](https://nutriscope.app) backend.

We only borrowed **patterns** from the web repo (Vercel proxy auth flow, OpenAI server-side key, RLS). No shared database, auth users, or API keys.

## Guest-first auth model

The app is **guest-first**: users can scan and log meals without creating an account.

| User state | Supabase session | Meal scans |
|------------|------------------|------------|
| Guest (no linked account) | Anonymous JWT via `BackendAuthBootstrap` | `analyze-meal` with anonymous user JWT |
| Signed in (email / Apple) | Linked non-anonymous JWT | Same edge function |
| Offline demo | None | `MockMealAnalysisService` (no network) |

**Anonymous sign-ins must be ON** in your Supabase dashboard and in `supabase/config.toml` (`enable_anonymous_sign_ins = true`).

## 1. Create a new Supabase project

1. Go to [supabase.com](https://supabase.com) → **New project** (e.g. `nutriscope-ai-ios`)
2. Run the migration in SQL Editor:
   - `supabase/migrations/001_ios_user_profiles.sql`
3. Authentication → Providers:
   - **Anonymous** → **ON** (required for guest meal scans)
   - **Apple** → ON, bundle ID `com.nutriscopeai.app`
   - **Email** → ON (optional, for email/password sign-up)
4. Copy **Project URL** and **anon public key** from Project Settings → API

## 2. Deploy edge function (from this repo)

```bash
cd proteinplate-ai
supabase login
supabase link --project-ref YOUR_IOS_PROJECT_REF
supabase secrets set OPENAI_API_KEY=sk-...
supabase functions deploy analyze-meal
```

Endpoint:

```
https://YOUR_IOS_PROJECT_REF.supabase.co/functions/v1/analyze-meal
```

### Verify `analyze-meal`

The function requires a valid `Authorization: Bearer <jwt>` header. **Anonymous JWTs are accepted** — `auth.getUser()` succeeds for `is_anonymous: true` users.

**iOS path (source of truth):** `SupabaseAuthClient.signInAnonymously()` via `BackendAuthBootstrap` — equivalent to Supabase's `signInAnonymously()` SDK call. No visible signup UI.

**Ops smoke test (curl):** optional secondary check after enabling Anonymous in the dashboard:

```bash
# 1. Create anonymous session (replace URL and anon key)
curl -s -X POST 'https://YOUR_PROJECT.supabase.co/auth/v1/signup' \
  -H 'apikey: YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{}' | jq -r '.access_token' > /tmp/token.txt

# 2. Call analyze-meal with text description
curl -s -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/analyze-meal' \
  -H "Authorization: Bearer $(cat /tmp/token.txt)" \
  -H 'apikey: YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"mealDescription":"grilled chicken breast with rice","dailyProteinTarget":150}'
```

`OPENAI_API_KEY` is read **only** from Supabase secrets — never from the iOS app in production.

## 3. Configure the iOS app (Release / TestFlight)

**Recommended — `Backend.xcconfig` (not committed):**

```bash
cp NutriscopeAI/Resources/Backend.xcconfig.example NutriscopeAI/Resources/Backend.xcconfig
# Edit Backend.xcconfig with real SUPABASE_URL and SUPABASE_ANON_KEY
```

`Shared.xcconfig` is linked to the Xcode project and optionally includes `Backend.xcconfig`. Values inject into the app `Info.plist` at build time via `INFOPLIST_KEY_SUPABASE_*` (read by `BackendConfig`).

**xcconfig URL trap:** `//` starts a comment in `.xcconfig` files. Write Supabase URLs like this:

```
SUPABASE_URL = https:/$()/YOUR_IOS_PROJECT_REF.supabase.co
```

If the URL is wrong, Xcode build settings will show `SUPABASE_URL = https:` and meal scans will fail.

**Alternative — Xcode scheme environment (Debug only):**

```
SUPABASE_URL = https://YOUR_IOS_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY = eyJ...
```

**Alternative — In app (Debug only):** Profile → Developer → Supabase URL + anon key

## 4. Release build behavior

| Offline demo | Meal analysis | Coach / tips |
|--------------|---------------|--------------|
| ON | Mock (no network) | Needs device OpenAI key (Debug) or edge fn (planned) |
| OFF, Supabase configured | Supabase `analyze-meal` proxy only | Supabase `ai-proxy` (coach, tips, grocery, plans) |
| OFF, not configured | Error — configure Supabase | Error |

Release meal scans **never** call OpenAI directly from the device.

## 5. Sign in with Apple

Apple sign-in creates/links a user in the **iOS Supabase project** only. Anonymous sessions can be **linked** to Apple or email via `SupabaseAuthClient.linkAppleIdentity` / `linkEmailPassword`.

On sign-up or sign-in, the app **upserts** `ios_user_profiles` (display name, email, protein/calorie targets) via `IOSUserProfileSyncService`.

### Password reset

Forgot password uses Supabase Auth email recovery (`/auth/v1/recover`). Users receive a reset link; redirect URL is `com.nutriscopeai.app://auth-callback` (must be allowed in Supabase Auth URL configuration).

SwiftData remains the on-device source of truth until full cloud sync is added.

## 6. Production checklist

- [ ] Supabase project created; migration applied
- [ ] Anonymous auth **ON** in dashboard
- [ ] Apple + Email providers configured
- [ ] `analyze-meal` + `ai-proxy` deployed; `OPENAI_API_KEY` secret set
- [ ] Migration `001_ios_user_profiles.sql` applied in SQL Editor
- [ ] Optional: curl anonymous signup → analyze-meal test passes
- [ ] **`Backend.xcconfig` created locally / injected via CI for Archive builds**
- [ ] **Release E2E proof:** Fresh install → no signup → anonymous session → scan → meal result → save → dashboard

## Reference (not shared infrastructure)

| Web (`nutriscope`) | iOS (`proteinplate-ai`) |
|--------------------|-------------------------|
| Own Supabase project | **New** Supabase project |
| Vercel `/api/chat` | Supabase `analyze-meal` edge function |
| Web auth + Postgres sync | Anonymous/Apple auth + SwiftData (local) |

## Next: AI proxy edge functions

Coach chat, daily tips, grocery suggestions, and tomorrow plans use the **`ai-proxy`** edge function when Supabase is configured. Deploy:

```bash
chmod +x scripts/deploy-ai-proxy.sh
./scripts/deploy-ai-proxy.sh
```

Release builds never call OpenAI directly from the device. Debug can bypass via Profile → Developer → **Use direct OpenAI in Debug**.
