#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc shop -n shop -o jsonpath='{.spec.selector}' 2>/dev/null) || fail "Service shop not found"
[ "$(echo "$S" | jq -cS .)" = '{"app":"shop"}' ] || fail "Service selector was changed ($S)"
[ "$(kubectl get deploy shop-v1 -n shop -o jsonpath='{.spec.replicas}')" = "3" ] || fail "shop-v1 was modified"
kubectl rollout status deploy/shop-v2 -n shop --timeout=30s >/dev/null 2>&1
N=$(kubectl get endpointslices -n shop -l kubernetes.io/service-name=shop -o json | jq '[.items[].endpoints[]? | select(.conditions.ready)] | length')
[ "$N" -eq 4 ] && pass "4 ready endpoints (3 v1 + 1 v2)" || fail "Service shop has $N ready endpoints, expected 4"
