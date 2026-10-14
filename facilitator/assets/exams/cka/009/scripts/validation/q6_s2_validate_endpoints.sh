#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/api -n backend --timeout=30s >/dev/null 2>&1
N=$(kubectl get endpointslices -n backend -l kubernetes.io/service-name=api-svc -o json | jq '[.items[].endpoints[]? | select(.conditions.ready)] | length')
[ "$N" -ge 1 ] && pass "$N ready endpoints" || fail "api-svc has no ready endpoints"
