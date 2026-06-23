# Nutriscope AI — Kinetic Harvest (build plan)

**Status:** Ready to start — missing screens received (`stitch_nutriscope_ai_tracker*`).

**Design system:** [Kinetic Harvest](stitch_designs/kinetic_harvest_1/DESIGN.md)  
- Coach orange `#F26B38` · Protein teal `#2D6A4F` · Warm sun `#FFD54F`  
- Type: **Hanken Grotesk** (UI) · **Inter** (labels)  
- Warm paper background `#FBF9F4`, soft cards, pill progress, iOS-style tab bar + center scan FAB  

Use tokens from `stitch_designs/kinetic_harvest_1/DESIGN.md`. Most `stitch_designs/*/code.html` files already follow this system.

**Product name in UI:** Nutriscope AI

---

## Canonical screens (v1)

One folder per flow — implement these when we start.

| Flow | Folder |
|------|--------|
| Auth welcome | `auth_welcome` |
| Sign in | `sign_in` |
| Sign up | `sign_up_trial_start` |
| Account choice | `account_choice` |
| Onboarding — goals | `onboarding_goals_redesign` |
| Onboarding — profile | `onboarding_profile_redesign` |
| Onboarding — target | `onboarding_target_redesign` |
| Onboarding — calculating (optional) | `onboarding_calculating_your_plan` |
| Onboarding — diet prefs (optional) | `onboarding_preferences` |
| Dashboard (Today) | `stitch_nutriscope_ai_tracker (5)` *(streak + Fix My Day + protein arc)* |

| Scan — camera | `ai_meal_scan` |
| Scan — manual / voice | `manual_meal_log` |
| First scan tutorial | `first_scan_tutorial` |
| Food database | `food_database_search` |
| Meal result | `meal_scan_results_coaching` |
| Post-save success | `post_scan_success_with_celebration` |
| Coach | `coach_chat_2` |
| Meals history | `meal_history_redesign` |
| Profile | `user_profile_settings` |
| Weekly report | `weekly_progress_report` |
| Weight | `weight_tracking_trends` |
| Recipe calculator | `recipe_macro_calculator` |
| Grocery list | `protein_first_grocery_list` |
| Reminders | `reminders_notifications` |
| Paywall | `nutriscope_pro_paywall` |
| **Scan quota exhausted** | `stitch_nutriscope_ai_tracker` |
| **Scan / analysis failed** | `stitch_nutriscope_ai_tracker (1)` *(PNG; full screen with Retry / Describe / Database)* |
| **Voice listening** | `stitch_nutriscope_ai_tracker (4)` |
| **Data & privacy** | `stitch_nutriscope_ai_tracker (3)` |
| Camera permission pre-prompt | `stitch_nutriscope_ai_tracker (6)` |
| Saved meals empty | `stitch_nutriscope_ai_tracker (7)` |
| Scan failed illustration (asset) | `stitch_nutriscope_ai_tracker (2)` *(PNG component)* |
| Trial ending | `trial_ending_soon` |
| Subscription success | `subscription_success` |
| Manage subscription | `manage_subscription` |
| Dialogs / toasts | `confirmation_dialogs` · `toast_notifications` |

**v2 / later (design exists, not v1 build):** `insights_trends` · `tomorrow_s_protein_plan` · `social_meal_estimator_ai`

---

## New designs received (`stitch_nutriscope_ai_tracker*`)

| Folder | Screen | HTML |
|--------|--------|------|
| `stitch_nutriscope_ai_tracker` | Scan limit reached (5/5, reset countdown) | ✓ |
| `stitch_nutriscope_ai_tracker (1)` | Scan failed — full screen | PNG only |
| `stitch_nutriscope_ai_tracker (2)` | Scan failed — illustration | PNG only |
| `stitch_nutriscope_ai_tracker (3)` | Data & privacy — export + wipe cache | ✓ |
| `stitch_nutriscope_ai_tracker (4)` | Voice input — listening / transcribing | ✓ |
| `stitch_nutriscope_ai_tracker (5)` | Today dashboard — streak, arc, Fix My Day | ✓ |
| `stitch_nutriscope_ai_tracker (6)` | Camera permission pre-prompt | ✓ |
| `stitch_nutriscope_ai_tracker (7)` | Saved meals empty state | ✓ |
| `stitch_nutriscope_ai_tracker (8)` | Grocery list (alt) | ✓ |

All use **Kinetic Harvest** tokens. Also added `screen.png` exports across `stitch_designs/` folders.

---

## Previously missing — now covered

| Screen | Status |
|--------|--------|
| Scan quota exhausted | ✓ `stitch_nutriscope_ai_tracker` |
| Scan / analysis failed | ✓ `(1)` PNG — implementable; optional: add `code.html` |
| Voice listening | ✓ `(4)` |
| Privacy export & clear data | ✓ `(3)` |

**Bonus received:** camera permission `(6)`, saved meals empty `(7)`, richer Today dashboard `(5)`.

**Still optional (not blocking):**
- Mic / notification permission pre-prompts (camera covered)
- Grocery empty inline state
- Forgot password
- `code.html` for scan-failed `(1)` — PNG is enough to build from

---

## When you're ready

1. Confirm canonical picks (especially dashboard `(5)` vs `dashboard_today_high_impact`)
2. Say **start** — Kinetic Harvest theme + UI rebuild screen by screen
