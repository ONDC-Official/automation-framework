#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Health-check all running services on the local Docker stack.
# Exits non-zero if any check fails.
# ──────────────────────────────────────────────────────────────────────────────
set -uo pipefail

# Format: "Display Name|URL"
SERVICES=(
  "ui-frontend|http://localhost:3000/health"
  "ui-backend|http://localhost:3007/health"
  "config-service|http://localhost:3001/health"
  "db-service|http://localhost:3002/health"
  "form-service|http://localhost:3003/health"
  "recorder-service|http://localhost:3004/health"
  "report-service|http://localhost:3006/health"
  "mock-playground|http://localhost:3010/health"
)

PASS=0
FAIL=0

for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name url <<< "$entry"
  if curl -sf --max-time 5 "$url" >/dev/null 2>&1; then
    printf "  \033[32mOK  \033[0m %-20s %s\n" "$name" "$url"
    PASS=$((PASS + 1))
  else
    printf "  \033[31mFAIL\033[0m %-20s %s\n" "$name" "$url"
    FAIL=$((FAIL + 1))
  fi
done

echo
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] || exit 1
