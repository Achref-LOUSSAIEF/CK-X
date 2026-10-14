#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=complete job/pi -n dev --timeout=30s >/dev/null 2>&1
S=$(kubectl get job pi -n dev -o jsonpath='{.status.succeeded}')
[ "${S:-0}" -ge 2 ] && pass "Completed" || fail "pi succeeded ${S:-0}/2 times"
