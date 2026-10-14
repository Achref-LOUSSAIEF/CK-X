#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/orders -n shop --timeout=30s >/dev/null 2>&1
N=$(kubectl get endpointslices -n shop -l kubernetes.io/service-name=orders-svc -o json | jq '[.items[].endpoints[]? | select(.conditions.ready)] | length')
[ "$N" -eq 2 ] && pass "2 endpoints" || fail "orders-svc has $N ready endpoints, expected 2"
