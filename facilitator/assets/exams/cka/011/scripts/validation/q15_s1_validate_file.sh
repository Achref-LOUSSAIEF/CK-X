#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q15/pod-status.txt
[ -f "$F" ] || fail "$F not found"
HDR=$(head -1 "$F" | tr -s ' \t' ' ' | sed 's/ *$//')
[ "$HDR" = "POD_NAME POD_STATUS" ] || fail "The first line must be the header POD_NAME POD_STATUS (found: $HDR)"
EXP=$(kubectl get pods -n audit-lab -o json | jq -r '.items | sort_by(.metadata.name)[] | "\(.metadata.name) \(.status.phase)"')
GOT=$(tail -n +2 "$F" | tr -s ' \t' ' ' | sed 's/ *$//' | grep -v '^$')
[ "$GOT" = "$EXP" ] && pass "Pod report" || fail "The rows must list every Pod of audit-lab with its phase, sorted by name"
