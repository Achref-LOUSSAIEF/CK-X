#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc nginx-random -n lookup -o json 2>/dev/null) || fail "Service nginx-random not found"
echo "$S" | jq -e '.spec.selector.app=="nginx-random" and any(.spec.ports[]; .port==80)' >/dev/null || fail "The Service must select the nginx-random Pods on port 80"
kubectl get endpointslices -n lookup -l kubernetes.io/service-name=nginx-random -o json | jq -e '[.items[].endpoints[]? | select(.conditions.ready)] | length > 0' >/dev/null   && pass "Service nginx-random has endpoints" || fail "Service nginx-random has no ready endpoints"
