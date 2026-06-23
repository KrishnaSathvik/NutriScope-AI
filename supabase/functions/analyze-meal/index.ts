/**
 * Nutriscope AI iOS — analyze-meal edge function
 * Dedicated Supabase project for the iOS app (separate from nutriscope web).
 * Pattern reference: nutriscope/api/chat.ts (Vercel proxy) + OpenAIMealAnalysisService.swift
 */

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

interface AnalyzeMealRequest {
  imageBase64?: string
  mealDescription?: string
  dailyProteinTarget?: number
  dietPreferences?: string[]
  userContext?: string
  proteinConsumedToday?: number
  caloriesConsumedToday?: number
}

interface MacroRangeDTO {
  min: number
  max: number
}

interface MealAnalysisResponse {
  mealName: string
  calories: MacroRangeDTO
  protein: MacroRangeDTO
  carbs: MacroRangeDTO
  fat: MacroRangeDTO
  confidence: "high" | "medium" | "low"
  followUpQuestions: Array<{ prompt: string; options: string[] }>
  advice: {
    headline: string
    proteinGapGrams: number
    suggestions: string[]
    coachMessage: string
    balanceScore: number
  }
}

const TEXT_EXTRACTION_RULES = `
Text parsing rules:
- If the user gives exact calories or protein for an item, use those values.
- If only portions are given (e.g. "2 rotis", "100g chicken"), estimate with standard values.
- Assume reasonable single servings when amounts are missing.
- Be conservative; prefer ranges over exact numbers.
- For Indian/home meals, account for hidden oil, ghee, and rice/roti portions.
- Return mealName that reflects the user's description when text is provided.
`

function buildPrompt(body: AnalyzeMealRequest): string {
  const dietNote =
    body.dietPreferences && body.dietPreferences.length > 0
      ? `Diet preferences: ${body.dietPreferences.join(", ")}.`
      : ""

  const description = (body.mealDescription ?? "").trim()
  const descriptionNote = description ? `User meal description: "${description}".` : ""

  const contextBlock = body.userContext?.trim() ? `\n${body.userContext.trim()}\n` : ""

  return `You are a protein-first meal coach. Analyze this meal and return ONLY valid JSON with this schema:
{
  "mealName": "string",
  "calories": {"min": int, "max": int},
  "protein": {"min": int, "max": int},
  "carbs": {"min": int, "max": int},
  "fat": {"min": int, "max": int},
  "confidence": "high|medium|low",
  "followUpQuestions": [{"prompt":"string","options":["a","b","c"]}],
  "advice": {
    "headline": "string",
    "proteinGapGrams": int,
    "suggestions": ["string"],
    "coachMessage": "string",
    "balanceScore": int
  }
}
${contextBlock}
${TEXT_EXTRACTION_RULES}
User daily protein target: ${body.dailyProteinTarget ?? 135}g.
Protein eaten today before this meal: ${body.proteinConsumedToday ?? 0}g.
${descriptionNote}
${dietNote}
Use ranges, not exact numbers. Ask 2 follow-up questions about hidden calories (oil, butter, sauces, portion size, fried vs grilled). Be coach-like, not judgmental. No medical claims. Set advice.proteinGapGrams based on remaining daily protein after this meal.`
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

    const body = (await req.json()) as AnalyzeMealRequest
    const hasImage = Boolean(body.imageBase64?.trim())
    const hasDescription = Boolean(body.mealDescription?.trim())

    if (!hasImage && !hasDescription) {
      return new Response(JSON.stringify({ error: "Add a photo or meal description" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const prompt = buildPrompt(body)
    const content: Array<Record<string, unknown>> = [{ type: "text", text: prompt }]

    if (hasImage) {
      content.push({
        type: "image_url",
        image_url: { url: `data:image/jpeg;base64,${body.imageBase64}` },
      })
    }

    const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openAIKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content }],
        max_tokens: 800,
        response_format: { type: "json_object" },
      }),
    })

    if (!openAIResponse.ok) {
      const detail = await openAIResponse.text()
      console.error("OpenAI error:", detail)
      return new Response(JSON.stringify({ error: "Analysis failed", detail }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const completion = await openAIResponse.json()
    const rawContent = completion?.choices?.[0]?.message?.content

    if (!rawContent || typeof rawContent !== "string") {
      return new Response(JSON.stringify({ error: "Invalid AI response" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const analysis = JSON.parse(rawContent) as MealAnalysisResponse

    return new Response(JSON.stringify(analysis), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    console.error("analyze-meal error:", error)
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
