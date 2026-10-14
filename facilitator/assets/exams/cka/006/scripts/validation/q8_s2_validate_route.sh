#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get httproute web-route -n web -o json 2>/dev/null) || fail "HTTPRoute web-route not found"
echo "$R" | jq -e '[.spec.parentRefs[] | select(.name=="web-gateway")] | length > 0' >/dev/null || fail "web-route is not attached to web-gateway"
echo "$R" | jq -e '.spec.hostnames | index("web.example.local")' >/dev/null || fail "web-route must use hostname web.example.local"
echo "$R" | jq -e '[.spec.rules[] | select((.matches // [{"path":{"type":"PathPrefix","value":"/"}}]) | any(.path.type=="PathPrefix" and .path.value=="/"))
  | .backendRefs[] | select(.name=="web" and .port==80)] | length > 0' >/dev/null \
  && pass "HTTPRoute correct" || fail "Rule PathPrefix / -> web:80 missing"
