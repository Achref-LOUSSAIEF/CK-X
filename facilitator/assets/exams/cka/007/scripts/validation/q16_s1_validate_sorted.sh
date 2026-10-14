#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q16/pods-by-age.txt
[ -f "$F" ] || fail "$F not found"
EXP=$(kubectl get pods -n observability --sort-by=.metadata.creationTimestamp -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
ACT=$(grep -v '^[[:space:]]*$' "$F" | sed 's#^pod/##; s/[[:space:]]*$//')
[ "$EXP" = "$ACT" ] && pass "Sorted correctly" || fail "Order in $F does not match the creation times"
