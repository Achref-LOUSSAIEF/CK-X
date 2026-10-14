#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
I=$(kubectl get ingress store -n store -o json 2>/dev/null) || fail "Ingress store not found"
[ "$(echo "$I" | jq -r '.spec.ingressClassName // ""')" = "traefik" ] || fail "ingressClassName must stay traefik"
echo "$I" | jq -e '[.spec.rules[] | select(.host=="store.example.local") | .http.paths[] | select(.path=="/api" and .pathType=="Prefix"
  and .backend.service.name=="store-api" and ((.backend.service.port.number==8080) or (.backend.service.port.name=="http")))] | length > 0' >/dev/null \
  && pass "Ingress fixed" || fail "Ingress must route store.example.local /api (Prefix) to store-api on port 8080 (or port name http)"
