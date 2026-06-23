# iOS Backend Setup

The **Nutriscope AI iOS app** uses its **own dedicated Supabase project** — separate from the [nutriscope web app](https://nutriscope.app) backend.

We only borrowed **patterns** from the web repo (Vercel proxy auth flow, OpenAI server-side key, RLS). No shared database, auth users, or API keys.

## 1. Create a new Supabase project

1. Go to [supabase.com](https://supabase.com) → **New project** (e.g. `nutriscope-ai-ios`)
2. Run the migration in SQL Editor:
   - `supabase/migrations/001_ios_user_profiles.sql`
3. Authentication → Providers:
   - **Anonymous** → OFF (accounts required; no guest access)
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

## 3. Configure the iOS app

**Option A — Xcode scheme environment:**

```
SUPABASE_URL = https://YOUR_IOS_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY = eyJ...
```

**Option B — In app:** Profile → Developer → Supabase URL + anon key

See `NutriscopeAI/Resources/Backend.xcconfig.example`.

## 4. Release build behavior

| Offline demo | Meal analysis |
|--------------|---------------|
| ON | Mock (no network) |
| OFF | iOS Supabase proxy only |

Release builds never call OpenAI directly from the device.

## 5. Sign in with Apple

Apple sign-in creates/links a user in the **iOS Supabase project** only. SwiftData remains the on-device source of truth until cloud sync is added.

## Reference (not shared infrastructure)

| Web (`nutriscope`) | iOS (`proteinplate-ai`) |
|--------------------|-------------------------|
| Own Supabase project | **New** Supabase project |
| Vercel `/api/chat` | Supabase `analyze-meal` edge function |
| Web auth + Postgres sync | Apple auth + SwiftData (local) |
