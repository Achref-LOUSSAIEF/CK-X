#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=complete job/batch-import -n batch --timeout=30s >/dev/null 2>&1
S=$(kubectl get job batch-import -n batch -o jsonpath='{.status.succeeded}')
[ "${S:-0}" -eq 6 ] && pass "6/6 succeeded" || fail "Succeeded: ${S:-0}/6"
