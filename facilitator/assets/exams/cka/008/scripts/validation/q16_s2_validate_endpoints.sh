#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/orders -n orders --timeout=30s >/dev/null 2>&1
N=$(kubectl get endpointslices -n orders -l kubernetes.io/service-name=orders -o json | jq '[.items[] | select([.ports[]?.port] | index(80)) | .endpoints[]? | select(.conditions.ready)] | length')
[ "$N" -eq 2 ] && pass "2 ready endpoints" || fail "orders has $N ready endpoints on port 80, expected 2"
