#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get httproute media-route -n media -o json 2>/dev/null) || fail "HTTPRoute media-route not found"
echo "$R" | jq -e '([.spec.parentRefs[] | select(.name=="main-gw")] | length > 0) and (.spec.hostnames | index("media.example.com")) and ([.spec.rules[].backendRefs[]? | select(.name=="media" and .port==80)] | length > 0)' >/dev/null \
  && pass "HTTPRoute correct" || fail "media-route must attach to main-gw, use host media.example.com and send to media:80"
