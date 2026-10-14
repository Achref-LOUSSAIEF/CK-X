#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get httproute api -n gw-lab -o json 2>/dev/null) || fail "HTTPRoute api not found"
echo "$R" | jq -e '[.spec.parentRefs[] | select(.name=="public")] | length > 0' >/dev/null || fail "api is not attached to the Gateway public"
echo "$R" | jq -e '.spec.hostnames | index("api.example.local")' >/dev/null || fail "Hostname api.example.local missing"
echo "$R" | jq -e '[.spec.rules[] | select([.matches[]?.headers[]? | select(.name=="x-channel" and .value=="beta" and (.type // "Exact")=="Exact")] | length > 0) | select([.backendRefs[]? | .name] == ["api-beta"]) | select([.backendRefs[]? | .port] == [8080])] | length == 1' >/dev/null || fail "No rule sending header x-channel: beta to api-beta:8080"
echo "$R" | jq -e '[.spec.rules[] | select([.matches[]?.headers[]?] | length == 0) | select([.backendRefs[]? | .name] == ["api-stable"]) | select([.backendRefs[]? | .port] == [8080])] | length == 1' >/dev/null \
  && pass "HTTPRoute correct" || fail "No default rule (without header match) sending traffic to api-stable:8080"
