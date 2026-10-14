#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/web -n web --timeout=60s >/dev/null 2>&1
N=$(kubectl get endpointslices -n web -l kubernetes.io/service-name=web -o json | jq '[.items[].endpoints[]? | select(.conditions.ready)] | length')
[ "$N" -eq 2 ] && pass "2 endpoints" || fail "web has $N ready endpoints, expected 2"
