#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
G=$(kubectl get gateway shared-gw -n infra -o json 2>/dev/null) || fail "Gateway shared-gw not found"
echo "$G" | jq -e '[.spec.listeners[] | select(.name=="http")][0].allowedRoutes.namespaces | .from=="Selector" and .selector.matchLabels["gateway-access"]=="true"' >/dev/null || fail "Listener http must accept routes from namespaces labeled gateway-access=true (from: Selector)"
echo "$G" | jq -e '[.spec.listeners[] | select(.name=="http")][0] | .port==80 and .protocol=="HTTP"' >/dev/null || fail "Listener http must stay HTTP on port 80"
[ "$(kubectl get ns web-app -o jsonpath='{.metadata.labels.gateway-access}')" = "true" ] && pass "web-app may attach routes to shared-gw" || fail "The namespace web-app is not labeled gateway-access=true"
