#!/usr/bin/env bash
# Hands-on exercise 19a: refresh rotation, reuse detection, logout and logout-all.
# Prints only HTTP status codes and comparisons — never token values.
set -u

BASE=${BASE:-http://localhost:3000/api/v1}
EMAIL="student-$RANDOM@example.test"
PASSWORD='a-long-local-test-password-for-this-exercise'

echo "== Health =="
curl -sS http://localhost:3000/health; echo

echo "== Setup: register $EMAIL =="
REGISTER=$(curl -sS -X POST "$BASE/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
ACCESS=$(printf '%s' "$REGISTER" | jq -r .accessToken)
REFRESH=$(printf '%s' "$REGISTER" | jq -r .refreshToken)
unset REGISTER
[ -n "$ACCESS" ] && [ "$ACCESS" != null ] && echo "access token set (hidden)"
[ -n "$REFRESH" ] && [ "$REFRESH" != null ] && echo "refresh token set (hidden)"

echo "== Protected tasks routes =="
printf 'GET  /tasks without token -> '
curl -sS -o /dev/null -w "%{http_code}\n" "$BASE/tasks"
printf 'POST /tasks               -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/tasks" \
  -H "Authorization: Bearer $ACCESS" -H "Content-Type: application/json" \
  -d '{"title":"Review API security","description":"Check ownership and validation"}'
printf 'GET  /tasks?page=1&limit=20 -> '
curl -sS -H "Authorization: Bearer $ACCESS" "$BASE/tasks?page=1&limit=20" | jq -c '{count: (.items | length), page, limit, first: .items[0].title}'

echo "== Task 1: rotation =="
OLD_REFRESH=$REFRESH
ROTATED=$(curl -sS -X POST "$BASE/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$OLD_REFRESH\"}")
NEW_ACCESS=$(printf '%s' "$ROTATED" | jq -r .accessToken)
NEW_REFRESH=$(printf '%s' "$ROTATED" | jq -r .refreshToken)
[ "$NEW_REFRESH" != null ] && echo "refresh with valid token -> 200"
if [ "$NEW_REFRESH" != "$OLD_REFRESH" ]; then printf 'different\n'; else printf 'same\n'; fi
ACCESS=$NEW_ACCESS
REFRESH=$NEW_REFRESH
unset ROTATED NEW_ACCESS NEW_REFRESH

echo "== Task 2: reuse detection =="
printf 'old (rotated) token   -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$OLD_REFRESH\"}"
printf 'newest token (family) -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$REFRESH\"}"

echo "== Task 3: logout =="
LOGIN=$(curl -sS -X POST "$BASE/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
LOGOUT_REFRESH=$(printf '%s' "$LOGIN" | jq -r .refreshToken)
unset LOGIN
printf 'logout                -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/auth/logout" \
  -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$LOGOUT_REFRESH\"}"
printf 'refresh after logout  -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$LOGOUT_REFRESH\"}"

echo "== Task 4: logout-all =="
SESSION_ONE=$(curl -sS -X POST "$BASE/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
ACCESS_ONE=$(printf '%s' "$SESSION_ONE" | jq -r .accessToken)
REFRESH_ONE=$(printf '%s' "$SESSION_ONE" | jq -r .refreshToken)
unset SESSION_ONE
SESSION_TWO=$(curl -sS -X POST "$BASE/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
REFRESH_TWO=$(printf '%s' "$SESSION_TWO" | jq -r .refreshToken)
unset SESSION_TWO
printf 'logout-all            -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/auth/logout-all" \
  -H "Authorization: Bearer $ACCESS_ONE"
printf 'refresh session one   -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$REFRESH_ONE\"}"
printf 'refresh session two   -> '
curl -sS -o /dev/null -w "%{http_code}\n" -X POST "$BASE/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$REFRESH_TWO\"}"

echo "== Generic login failure =="
curl -sS -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"wrong-password-here\"}"; echo
