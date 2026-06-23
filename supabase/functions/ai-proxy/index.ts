/**
 * Nutriscope AI iOS — ai-proxy edge function
 * Coach chat, tips, grocery, tomorrow plan, follow-up advice.
 * Mirrors OpenAICoachService.swift prompts; OpenAI key stays server-side only.
 */

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

type CoachContext = {
  displayName?: string
  proteinTarget?: number
  proteinToday?: number
  proteinRemaining?: number
  calorieRemainingMin?: number
  calorieRemainingMax?: number
  mealsLoggedToday?: number
  dietPreferences?: string[]
  recentMealNames?: string[]
  healthNote?: string | null
  preferredCoachStyle?: string
}

type ChatHistoryItem = { role: "user" | "assistant"; content: string }

type AIProxyRequest = {
  action: string
  context?: CoachContext
  history?: ChatHistoryItem[]
  userMessage?: string
  proteinRemaining?: number
  proteinTarget?: number
  dietPreferences?: string[]
  eatingOutTomorrow?: boolean
  tomorrowLabel?: string
  proteinGap?: number
  mealNames?: string[]
  mealName?: string
  proteinFormatted?: string
  caloriesFormatted?: string
  followUpAnswers?: string
  dailyProteinTarget?: number
  proteinConsumedToday?: number
}

function contextBlock(context: CoachContext): string {
  const lines = [
    `User: ${context.displayName ?? "there"}`,
    `Protein target: ${context.proteinTarget ?? 135}g`,
    `Protein today: ${context.proteinToday ?? 0}g`,
    `Protein remaining: ${context.proteinRemaining ?? 0}g`,
    `Calorie room: ~${context.calorieRemainingMin ?? 0}–${context.calorieRemainingMax ?? 0} kcal`,
    `Meals logged today: ${context.mealsLoggedToday ?? 0}`,
    `Coach style: ${context.preferredCoachStyle ?? "Quick"}`,
  ]
  if (context.dietPreferences?.length) {
    lines.push(`Diet: ${context.dietPreferences.join(", ")}`)
  }
  if (context.recentMealNames?.length) {
    lines.push(`Recent meals: ${context.recentMealNames.join("; ")}`)
  }
  if (context.healthNote) {
    lines.push(`Health context: ${context.healthNote}`)
  }
  return lines.join("\n")
}

async function openAIChat(
  openAIKey: string,
  messages: Array<{ role: string; content: string }>,
  maxTokens: number,
  jsonObject = false,
): Promise<string> {
  const body: Record<string, unknown> = {
    model: "gpt-4o-mini",
    messages,
    max_tokens: maxTokens,
  }
  if (jsonObject) {
    body.response_format = { type: "json_object" }
  }

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAIKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const detail = await response.text()
    console.error("OpenAI error:", detail)
    throw new Error("AI request failed")
  }

  const completion = await response.json()
  const content = completion?.choices?.[0]?.message?.content
  if (!content || typeof content !== "string") {
    throw new Error("Invalid AI response")
  }
  return content.trim()
}

function parseJSON<T>(raw: string): T {
  const trimmed = raw
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim()
  return JSON.parse(trimmed) as T
}

async function handleAction(body: AIProxyRequest, openAIKey: string): Promise<unknown> {
  const ctx = body.context ?? {}
  const block = contextBlock(ctx)

  switch (body.action) {
    case "coach_chat": {
      const system = `You are Nutriscope AI, a protein-first nutrition coach. Be warm, concise, and actionable.
Use the user's real numbers. Suggest meals with approximate protein grams. No medical claims.
${block}`
      const messages: Array<{ role: string; content: string }> = [
        { role: "system", content: system },
      ]
      for (const item of body.history ?? []) {
        messages.push({ role: item.role, content: item.content })
      }
      messages.push({ role: "user", content: body.userMessage ?? "" })
      const text = await openAIChat(openAIKey, messages, 500)
      return { text }
    }

    case "coach_greeting": {
      const prompt = `Write a short coach greeting (1-2 sentences) for a check-in chat.
Mention protein remaining if > 0. Reference time of day naturally.
${block}
Return plain text only.`
      const text = await openAIChat(
        openAIKey,
        [
          { role: "system", content: "You are a protein-first nutrition coach." },
          { role: "user", content: prompt },
        ],
        120,
      )
      return { text }
    }

    case "daily_tip": {
      const prompt = `Write one short coach tip (max 2 sentences) for the Today dashboard.
${block}
Return plain text only.`
      const text = await openAIChat(
        openAIKey,
        [
          { role: "system", content: "You are a protein-first nutrition coach." },
          { role: "user", content: prompt },
        ],
        120,
      )
      return { text }
    }

    case "protein_suggestions": {
      const remaining = body.proteinRemaining ?? ctx.proteinRemaining ?? 0
      const prompt = `Return JSON: {"suggestions": ["string", "string", "string"]}
Give 3 specific meal/snack ideas to close ${remaining}g protein remaining today.
${block}`
      const raw = await openAIChat(openAIKey, [{ role: "user", content: prompt }], 300, true)
      return parseJSON(raw)
    }

    case "suggestion_card_protein": {
      const prompt = `Return JSON: {"proteinGrams": int}
How many grams of protein should the user aim for in their next meal? Remaining today: ${ctx.proteinRemaining ?? 0}g.`
      const raw = await openAIChat(openAIKey, [{ role: "user", content: prompt }], 80, true)
      const dto = parseJSON<{ proteinGrams: number }>(raw)
      return { proteinGrams: Math.max(10, Math.min(dto.proteinGrams, 60)) }
    }

    case "tomorrow_plan": {
      const prefs = (body.dietPreferences ?? []).join(", ")
      const prompt = `Return JSON:
{
  "meals": [
    {"slot": "breakfast|lunch|dinner", "name": "string", "protein": int, "calories": int, "carbs": int, "fat": int}
  ]
}
Plan 3 meals for tomorrow (${body.tomorrowLabel ?? "Tomorrow"}) totaling ~${body.proteinTarget ?? 135}g protein.
Diet preferences: ${prefs || "none"}.
Eating out tomorrow: ${body.eatingOutTomorrow ? "yes — include a flexible restaurant-style dinner" : "no"}.
Use realistic home-cook or restaurant names with accurate macro estimates.`
      const raw = await openAIChat(openAIKey, [{ role: "user", content: prompt }], 700, true)
      return parseJSON(raw)
    }

    case "grocery_suggestions": {
      const prefs = (body.dietPreferences ?? []).join(", ")
      const prompt = `Return JSON: {"items": ["string"]}
Suggest 6-8 grocery items to help close ${body.proteinGap ?? 0}g protein gap.
Diet: ${prefs || "none"}. Short item names only.`
      const raw = await openAIChat(openAIKey, [{ role: "user", content: prompt }], 250, true)
      return parseJSON(raw)
    }

    case "grocery_items_for_meals": {
      const names = (body.mealNames ?? []).join(", ")
      const prompt = `Return JSON: {"items": ["string"]}
Grocery ingredients needed for: ${names}.
4-8 items, short names.`
      const raw = await openAIChat(openAIKey, [{ role: "user", content: prompt }], 200, true)
      return parseJSON(raw)
    }

    case "followup_advice": {
      const prompt = `Return JSON matching:
{"headline":"string","proteinGapGrams":int,"suggestions":["string"],"coachMessage":"string","balanceScore":int}
Meal: ${body.mealName ?? "meal"}. Protein ${body.proteinFormatted ?? ""}. Calories ${body.caloriesFormatted ?? ""}.
Follow-up answers: ${body.followUpAnswers ?? ""}
Daily protein target: ${body.dailyProteinTarget ?? 135}g. Protein before this meal today: ${body.proteinConsumedToday ?? 0}g.`
      const raw = await openAIChat(openAIKey, [{ role: "user", content: prompt }], 400, true)
      return parseJSON(raw)
    }

    default:
      throw new Error(`Unknown action: ${body.action}`)
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    const openAIKey = Deno.env.get("OPENAI_API_KEY") ?? ""

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(JSON.stringify({ error: "Server configuration error" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    if (!openAIKey) {
      return new Response(JSON.stringify({ error: "OpenAI not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: userData, error: userError } = await supabase.auth.getUser()
    if (userError || !userData.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const body = (await req.json()) as AIProxyRequest
    if (!body.action?.trim()) {
      return new Response(JSON.stringify({ error: "Missing action" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const result = await handleAction(body, openAIKey)

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Internal server error"
    console.error("ai-proxy error:", error)
    const status = message.startsWith("Unknown action") ? 400 : 502
    return new Response(JSON.stringify({ error: message }), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
