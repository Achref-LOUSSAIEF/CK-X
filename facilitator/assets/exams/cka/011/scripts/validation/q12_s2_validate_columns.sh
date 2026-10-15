#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q12/pv-by-size.txt
[ -f "$F" ] || fail "$F not found"
head -1 "$F" | grep -q 'NAME' && head -1 "$F" | grep -q 'CAPACITY' && grep -E '^pv-logs[[:space:]]' "$F" | grep -q '3Gi'   && pass "Default kubectl get columns" || fail "$F must hold the default kubectl get output (with the NAME and CAPACITY columns)"
