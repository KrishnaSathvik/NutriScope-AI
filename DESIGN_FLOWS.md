# Nutriscope AI — Product Brief

Use this as a **north star**, not a screen spec.  
Designers should invent layout, hierarchy, motion, and visual language.  
Only **rules, outcomes, and capabilities** below are fixed unless product says otherwise.

---

## What this product is

**Nutriscope AI** — protein-first AI meal coach for people who don't want a calorie spreadsheet.

**Core belief:** Calories are rough. Protein is the goal.

**Emotional job:** Help users eat better without shame, perfectionism, or obsessive logging.

**Platform:** iOS native (SwiftUI). Local-first today; cloud sync later.

---

## Design principles (non-negotiable)

1. **Protein leads** — calories support, never dominate.
2. **Ranges, not false precision** — estimates feel honest, not clinical.
3. **Low friction logging** — photo, voice, text, or search; user picks what's easiest.
4. **Coach, not judge** — tone adapts; never punitive.
5. **Progress over perfection** — streaks and weekly trends matter more than one bad meal.

Everything else — navigation pattern, card layout, tab structure, onboarding length — is **open for exploration**.

---

## User outcomes (what success looks like)

| Outcome | User feels… |
|---------|-------------|
| Log a meal in <30 seconds | "That was easy" |
| See protein progress | "I know if I'm on track" |
| Get stuck at dinner | "The app told me what to eat next" |
| Repeat a usual meal | "One tap, done" |
| Hit weekly protein goals | "I'm building a habit" |
| Hit scan limit | "I understand the value of Pro" |

---

## Journey map (states, not screens)

High-level states the app must support. **How many screens, steps, or modals** each state uses is up to design.

```
[First open]
    → understand value
    → (optional) personalize body + goal
    → (optional) account or trial decision
    → [Home / active use]

[Active use loop]
    → check today's progress
    → log meal(s)
    → confirm / refine estimate
    → get coaching for what's next
    → review history / patterns
    → adjust goals or preferences

[Monetization moments]
    → hit free scan limit
    → choose trial or stay free
    → manage subscription

[Account lifecycle]
    → guest · signed in · trial · pro · lapsed
```

---

## Capability inventory

What the product **must be able to do**. Not *where* it lives in the UI.

### Logging & analysis
- Capture meal via photo, text, voice, or food database lookup
- Return macro **ranges** with confidence level
- Let user confirm or refine (questions that adjust the estimate)
- Save to today; save as reusable template; re-log saved meals
- Infer meal type from context (time of day)

### Daily coaching
- Show progress toward daily protein target
- Surface contextual tips (time, gap, habits)
- Suggest what to eat next based on remaining protein + preferences
- Offer multiple suggestion styles (diet, cuisine, context)

### History & insight
- Browse meals by time window
- Filter by context (high protein, restaurant, home, saved)
- Streaks and weekly aggregates
- Deeper weekly report (days logged, averages, highlights)

### Personalization
- Fitness goal affects targets
- Body stats → personalized protein + calorie range (BMR/TDEE)
- Diet preferences feed AI + coach
- Adjustable focus (protein-only vs full macros) and coach tone

### Tools (secondary, not core loop)
- Weight log + trend
- Recipe macro calculator
- Grocery list with protein-gap suggestions
- Meal reminders (local notifications)

### Account & data
- Guest path (no account)
- Email/password account (local today)
- Sign in / sign out
- Export data · wipe local data

### Monetization
- Free: limited scans per week
- Pro / trial: unlimited scans + full feature access
- 7-day trial path
- StoreKit subscriptions (monthly / yearly)

---

## Business rules (hard constraints)

These affect flow logic — design must accommodate them, but can present them creatively.

| Rule | Detail |
|------|--------|
| Free scan quota | 5 scans per calendar week |
| Quota gate | No scans left → monetization moment before new scan |
| Soft upsell | Possible nudge after heavy free usage in a week |
| Trial | 7-day Pro access; can start during onboarding or later |
| Guest | Can use app without account; weaker identity / recovery story |
| Sign-in return | Existing profile → skip personalization; new device profile → personalize |
| Offline demo | Works without API keys (mock analysis) |
| Permissions | Camera, photos, mic/speech, notifications — only when feature needs them |

**Pricing (for paywall copy):** ~$7.99/mo · ~$39.99/yr · 7-day trial

---

## Suggested journey threads (inspiration, not wireframes)

Pick, merge, or reinvent these. None are mandatory step orders.

**Thread A — Believer:** Value prop → quick personalize → first scan → wow moment → account optional

**Thread B — Skeptic:** Guest entry → scan first → hit limit → trial → account

**Thread C — Planner:** Full personalize → account → dashboard → coach-heavy daily use

**Thread D — Returning:** Sign in → straight to dashboard

The current codebase implements a multi-step auth + onboarding + account-choice path. **Design may collapse, reorder, or split steps** if the journey still satisfies the rules above.

---

## Areas wide open for design

Explicitly **not defined** — push creativity here:

- Information architecture (tabs vs hub vs feed vs floating action)
- Onboarding length and tone
- How protein progress is visualized (ring, bar, number, ambient)
- Scan entry point prominence
- Meal result confirmation UX (modal, inline, conversational)
- Coach presentation (chat, cards, voice, single hero suggestion)
- Paywall timing, framing, and emotional hook
- Empty states, celebrations, streaks
- Dark mode, brand illustration, motion
- How "ranges" and "confidence" are communicated visually

---

## Anti-patterns to avoid

- Calorie-first dashboard that feels like MyFitnessPal
- Exact macro numbers presented as medical truth
- Blocking account creation before any value
- Shame copy ("you failed", "over budget")
- Too many taps to log a common meal
- Settings-heavy first experience

---

## Reference: current implementation (fallback only)

If design needs a baseline, the **built app today** roughly maps to:

Home · Meals · Scan · Coach · Profile + auth/onboarding/paywall sheets.

Treat this as **v0 engineering layout**, not the target experience.  
Rebuild UI freely as long as capabilities and business rules still work.

---

## For AI / designers reading this

**Do:** Invent screens, flows, and interactions that deliver the outcomes and capabilities above.  
**Don't:** Mirror this document as a 1:1 screen list or copy existing app layout by default.  
**Ask:** What would make protein tracking feel inevitable, not obligatory?

---

*Nutriscope AI · `com.nutriscopeai.app`*
