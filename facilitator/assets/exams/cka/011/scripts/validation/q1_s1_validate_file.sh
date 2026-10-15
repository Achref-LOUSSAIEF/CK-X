#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q1/bar-errors.log
[ -f "$F" ] || fail "$F not found"
EXP=$(kubectl logs bar -n web-logs 2>/dev/null | grep 'unable-to-access-website')
[ -n "$EXP" ] || fail "Could not read the logs of the Pod bar"
GOT=$(tr -d '\r' < "$F" | sed 's/[[:space:]]*$//' | grep -v '^$')
[ "$GOT" = "$EXP" ] && pass "The file holds exactly the matching log lines" || fail "$F must contain exactly the log lines with unable-to-access-website, in order"
