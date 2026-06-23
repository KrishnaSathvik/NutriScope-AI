#!/usr/bin/env bash
# Deploy Nutriscope AI analyze-meal edge function to Supabase.
# Prerequisites:
#   1. supabase login (account that owns project iaplfsloucztzjihldod)
#   2. OPENAI_API_KEY in environment OR passed as first argument
#
# Usage:
#   ./scripts/deploy-analyze-meal.sh
#   ./scripts/deploy-analyze-meal.sh sk-your-openai-key
#   OPENAI_API_KEY=sk-... ./scripts/deploy-analyze-meal.sh

set -euo pipefail

PROJECT_REF="iaplfsloucztzjihldod"
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

echo "==> Checking Supabase CLI login..."
if ! supabase projects list 2>&1 | grep -q "$PROJECT_REF"; then
  echo ""
  echo "ERROR: Project $PROJECT_REF is not visible to your logged-in Supabase account."
  echo ""
  echo "Fix:"
  echo "  supabase logout"
  echo "  supabase login"
  echo "  # Sign in with the account that created the Nutriscope iOS project"
  echo ""
  exit 1
fi

echo "==> Linking project..."
supabase link --project-ref "$PROJECT_REF"

OPENAI_KEY="${1:-${OPENAI_API_KEY:-}}"
if [[ -z "$OPENAI_KEY" ]]; then
  echo ""
  read -rsp "Enter OPENAI_API_KEY (sk-...): " OPENAI_KEY
  echo ""
fi

if [[ -z "$OPENAI_KEY" ]]; then
  echo "ERROR: OPENAI_API_KEY is required."
  exit 1
fi

echo "==> Setting Supabase secret OPENAI_API_KEY..."
supabase secrets set "OPENAI_API_KEY=${OPENAI_KEY}"

echo "==> Deploying analyze-meal..."
supabase functions deploy analyze-meal

echo ""
echo "==> Smoke test (anonymous auth + analyze-meal)..."

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  if [[ -f "$ROOT/NutriscopeAI/Resources/Backend.xcconfig" ]]; then
    SUPABASE_ANON_KEY=$(grep '^SUPABASE_ANON_KEY' "$ROOT/NutriscopeAI/Resources/Backend.xcconfig" | sed 's/.*= *//')
  fi
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "WARN: Set SUPABASE_ANON_KEY env var to run smoke test, or check manually."
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

RESP=$(curl -s -w "\nHTTP:%{http_code}" -X POST "${SUPABASE_URL}/functions/v1/analyze-meal" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"mealDescription":"grilled chicken breast with rice","dailyProteinTarget":150}')

HTTP=$(echo "$RESP" | grep HTTP | cut -d: -f2)
BODY=$(echo "$RESP" | sed '/HTTP:/d')

echo "HTTP $HTTP"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

if [[ "$HTTP" == "200" ]]; then
  echo ""
  echo "SUCCESS: analyze-meal is live at ${SUPABASE_URL}/functions/v1/analyze-meal"
else
  echo ""
  echo "Deploy finished but smoke test failed. Check dashboard Edge Functions logs."
  exit 1
fi
