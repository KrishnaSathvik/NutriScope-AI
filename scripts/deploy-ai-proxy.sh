#!/usr/bin/env bash
# Deploy Nutriscope AI ai-proxy edge function to Supabase.
# Prerequisites: supabase login, OPENAI_API_KEY secret already set (see deploy-analyze-meal.sh).
#
# Usage:
#   ./scripts/deploy-ai-proxy.sh

set -euo pipefail

PROJECT_REF="iaplfsloucztzjihldod"
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

echo "==> Deploying ai-proxy to project ${PROJECT_REF}..."
supabase functions deploy ai-proxy --project-ref "$PROJECT_REF"

echo ""
echo "==> Smoke test (daily_tip via ai-proxy)..."

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  if [[ -f "$ROOT/NutriscopeAI/Resources/Backend.xcconfig" ]]; then
    SUPABASE_ANON_KEY=$(grep '^SUPABASE_ANON_KEY' "$ROOT/NutriscopeAI/Resources/Backend.xcconfig" | sed 's/.*= *//')
  fi
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "WARN: Set SUPABASE_ANON_KEY to run smoke test."
  echo "SUCCESS: ai-proxy deployed at ${SUPABASE_URL}/functions/v1/ai-proxy"
  exit 0
fi

TOKEN=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/signup" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{}' | jq -r '.access_token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "FAIL: Anonymous signup did not return a token."
  exit 1
fi

RESP=$(curl -s -w "\nHTTP:%{http_code}" -X POST "${SUPABASE_URL}/functions/v1/ai-proxy" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"action":"daily_tip","context":{"displayName":"Alex","proteinTarget":150,"proteinToday":80,"proteinRemaining":70,"calorieRemainingMin":400,"calorieRemainingMax":600,"mealsLoggedToday":2,"dietPreferences":[],"recentMealNames":[],"preferredCoachStyle":"Quick"}}')

HTTP=$(echo "$RESP" | grep HTTP | cut -d: -f2)
BODY=$(echo "$RESP" | sed '/HTTP:/d')

echo "HTTP $HTTP"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

if [[ "$HTTP" == "200" ]]; then
  echo ""
  echo "SUCCESS: ai-proxy is live at ${SUPABASE_URL}/functions/v1/ai-proxy"
else
  echo ""
  echo "Deploy finished but smoke test failed. Check Edge Functions logs in Supabase dashboard."
  exit 1
fi
