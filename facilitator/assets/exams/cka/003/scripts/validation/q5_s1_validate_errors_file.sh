#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/errors.log
[ -f "$F" ] || fail "$F not found"
EXPECTED=$(kubectl logs audit-app -n logging -c app 2>/dev/null | grep ERROR | sed 's/[[:space:]]*$//')
[ -n "$EXPECTED" ] || fail "Could not read logs of audit-app/app"
ACTUAL=$(grep -v '^[[:space:]]*$' "$F" | sed 's/[[:space:]]*$//')
[ "$EXPECTED" = "$ACTUAL" ] && pass "errors.log is correct" || fail "errors.log content does not match the ERROR lines of container app"
