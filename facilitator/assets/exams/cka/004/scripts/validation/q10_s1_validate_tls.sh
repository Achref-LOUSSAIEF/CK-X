#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
I=$(kubectl get ingress api-ingress -n web-api -o json 2>/dev/null) || fail "Ingress api-ingress not found"
[ "$(echo "$I" | jq -r '.spec.ingressClassName // ""')" = "traefik" ] || fail "ingressClassName must be traefik"
echo "$I" | jq -e '[.spec.tls[]? | select(.secretName=="api-tls-cert" and (.hosts|index("api.example.com")))] | length > 0' >/dev/null \
  && pass "TLS configured" || fail "TLS for api.example.com with secret api-tls-cert missing"
