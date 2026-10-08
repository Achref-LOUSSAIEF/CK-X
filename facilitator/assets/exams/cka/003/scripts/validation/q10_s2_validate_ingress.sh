#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
I=$(kubectl get ingress shop-ingress -n ingress-lab -o json 2>/dev/null) || fail "Ingress shop-ingress not found"
CLS=$(echo "$I" | jq -r '.spec.ingressClassName // .metadata.annotations["kubernetes.io/ingress.class"] // ""')
[ "$CLS" = "traefik" ] || fail "Ingress class is '$CLS', expected traefik"
R=$(echo "$I" | jq -r '.spec.rules[] | select(.host=="shop.example.local") | .http.paths[] | "\(.path)|\(.pathType)|\(.backend.service.name)|\(.backend.service.port.number)"' | sort)
echo "$R" | grep -qx '/|Prefix|shop-svc|80' || fail "Missing rule / (Prefix) -> shop-svc:80"
echo "$R" | grep -qx '/api|Prefix|api-svc|8080' || fail "Missing rule /api (Prefix) -> api-svc:8080"
pass "Ingress rules correct"
