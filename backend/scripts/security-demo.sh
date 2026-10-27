#!/usr/bin/env bash
# Demonstrates secure defaults: headers, validation, ownership (IDOR) and safe errors.
# Prints status codes and error bodies only — never token values.
set -u

BASE=${BASE:-http://localhost:3000/api/v1}
PASSWORD='a-long-local-test-password-for-this-exercise'

register() {
  curl -sS -X POST "$BASE/auth/register" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\"}" | jq -r .accessToken
}

echo "== Security headers (helmet, no x-powered-by) =="
curl -sS -D - -o /dev/null http://localhost:3000/health | grep -iE "^(HTTP|content-security-policy|strict-transport|x-content-type|x-frame|referrer-policy|cross-origin-opener|x-powered-by)" | cut -c1-110

echo
echo "== Validation (Zod) =="
printf 'register weak password -> '
curl -sS -X POST "$BASE/auth/register" -H 'Content-Type: application/json' \
  -d '{"email":"not-an-email","password":"short"}' | jq -c .

ALICE=$(register "alice-$RANDOM@example.test")
BOB=$(register "bob-$RANDOM@example.test")
printf 'limit=1000 (max 100)    -> '
curl -sS "$BASE/tasks?limit=1000" -H "Authorization: Bearer $ALICE" | jq -c .error.details

echo
echo "== Ownership / IDOR =="
TASK_ID=$(curl -sS -X POST "$BASE/tasks" -H "Authorization: Bearer $BOB" -H 'Content-Type: application/json' \
  -d '{"title":"Bob private task"}' | jq -r .item.id)
echo "Bob created task $TASK_ID"
printf 'Alice lists tasks        -> '
curl -sS "$BASE/tasks" -H "Authorization: Bearer $ALICE" | jq -c '{count: (.items|length)}'
printf 'Alice PATCH Bob task     -> '
curl -sS -X PATCH "$BASE/tasks/$TASK_ID" -H "Authorization: Bearer $ALICE" -H 'Content-Type: application/json' \
  -d '{"title":"hacked"}' -w " %{http_code}\n"
printf 'Alice DELETE Bob task    -> '
curl -sS -X DELETE "$BASE/tasks/$TASK_ID" -H "Authorization: Bearer $ALICE" -w " %{http_code}\n"
printf 'Spoofed ownerId ignored  -> '
curl -sS -X POST "$BASE/tasks" -H "Authorization: Bearer $ALICE" -H 'Content-Type: application/json' \
  -d '{"title":"x","ownerId":"someone-else"}' | jq -c '{ownerIdIsSomeoneElse: (.item.ownerId == "someone-else")}'

echo
echo "== Safe errors =="
printf 'Malformed task id        -> '
curl -sS -X DELETE "$BASE/tasks/'%20OR%201=1--" -H "Authorization: Bearer $ALICE" | jq -c .error.code
printf 'Forged bearer token      -> '
curl -sS "$BASE/tasks" -H "Authorization: Bearer forged.token.value" -w " %{http_code}\n"
printf 'Disallowed CORS origin   -> '
curl -sS "$BASE/tasks" -H "Origin: https://evil.example" -H "Authorization: Bearer $ALICE" -w " %{http_code}\n"
