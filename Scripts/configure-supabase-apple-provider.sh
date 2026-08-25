#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "Missing SUPABASE_ACCESS_TOKEN. Export it locally before running this script." >&2
  exit 1
fi

if [[ -z "${APPLE_CLIENT_SECRET:-}" ]]; then
  echo "Missing APPLE_CLIENT_SECRET. Generate it from Apple Team ID, Key ID, and the .p8 key first." >&2
  exit 1
fi

PROJECT_REF="${SUPABASE_PROJECT_REF:-lhcllwbwtbpztbzdduep}"
APPLE_CLIENT_IDS="${APPLE_CLIENT_IDS:-com.echopet.mvp}"

if [[ "$APPLE_CLIENT_IDS" == *\"* || "$APPLE_CLIENT_SECRET" == *\"* ]]; then
  echo "Client IDs and client secret must not contain double quotes." >&2
  exit 1
fi

curl --fail --silent --show-error \
  --request PATCH \
  --url "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  --header "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  --header "Content-Type: application/json" \
  --data "{
    \"external_apple_enabled\": true,
    \"external_apple_client_id\": \"${APPLE_CLIENT_IDS}\",
    \"external_apple_secret\": \"${APPLE_CLIENT_SECRET}\"
  }"

echo
echo "Supabase Apple provider configuration submitted for project ${PROJECT_REF}."
