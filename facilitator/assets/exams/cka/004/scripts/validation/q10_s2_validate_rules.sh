#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get ingress api-ingress -n web-api -o json 2>/dev/null | jq -r '.spec.rules[]? | select(.host=="api.example.com") | .http.paths[] | "\(.path)|\(.pathType)|\(.backend.service.name)|\(.backend.service.port.number)"')
echo "$R" | grep -qx '/api|Prefix|api|80' || fail "Missing /api (Prefix) -> api:80"
echo "$R" | grep -qx '/health|Exact|api|80' && pass "Rules correct" || fail "Missing /health (Exact) -> api:80"
