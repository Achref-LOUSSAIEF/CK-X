#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc cache-peers -n cache -o json 2>/dev/null) || fail "Service cache-peers not found"
echo "$S" | jq -e '.spec.clusterIP=="None" and .spec.selector.app=="cache" and ([.spec.ports[] | select(.name=="redis" and .port==6379)] | length == 1)' >/dev/null || fail "cache-peers must be headless (clusterIP None), select app=cache and expose port redis/6379"
kubectl rollout status deploy/cache -n cache --timeout=30s >/dev/null 2>&1
N=$(kubectl get endpointslices -n cache -l kubernetes.io/service-name=cache-peers -o json | jq '[.items[].endpoints[]?.addresses[]?] | length')
[ "$N" -eq 3 ] && pass "Headless Service with 3 endpoints" || fail "cache-peers has $N endpoint addresses, expected 3"
