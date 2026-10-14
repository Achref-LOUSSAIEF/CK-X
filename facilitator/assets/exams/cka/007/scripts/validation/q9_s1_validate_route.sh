#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get httproute store -n canary -o json 2>/dev/null) || fail "HTTPRoute store not found"
echo "$R" | jq -e '[.spec.parentRefs[] | select(.name=="edge")] | length > 0' >/dev/null || fail "store is not attached to the Gateway edge"
echo "$R" | jq -e '.spec.hostnames | index("store.example.local")' >/dev/null || fail "Hostname store.example.local missing"
W=$(echo "$R" | jq -r '[.spec.rules[0].backendRefs[] | "\(.name):\(.port):\(.weight // 1)"] | sort | join(",")')
[ "$W" = "store-v1:80:90,store-v2:80:10" ] && pass "Weights 90/10" || fail "Backends/weights are '$W', expected store-v1:80:90,store-v2:80:10 in one rule"
