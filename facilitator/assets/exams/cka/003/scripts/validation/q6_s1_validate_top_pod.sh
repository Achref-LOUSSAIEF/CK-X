#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q6/top-pod.txt
[ -f "$F" ] || fail "$F not found"
[ "$(tr -d '[:space:]' < "$F")" = "analytics-2" ] && pass "Correct Pod identified" || fail "Wrong Pod name in $F"
