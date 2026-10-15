#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get httproute web-route -n web-app -o json 2>/dev/null) || fail "HTTPRoute web-route not found in web-app"
echo "$R" | jq -e 'any(.spec.parentRefs[]; .name=="shared-gw" and .namespace=="infra")' >/dev/null || fail "web-route must reference the Gateway shared-gw in the namespace infra"
echo "$R" | jq -e '.spec.hostnames | index("web.example.com")' >/dev/null || fail "web-route must match the host web.example.com"
echo "$R" | jq -e 'any(.spec.rules[].backendRefs[]?; .name=="web-service" and .port==80 and ((.namespace // "web-app")=="web-app"))' >/dev/null   && pass "HTTPRoute web-route" || fail "web-route must send traffic to web-service on port 80"
