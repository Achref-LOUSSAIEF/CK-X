#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
I=$(kubectl get ingress www-ingress -n www -o json 2>/dev/null) || fail "Ingress www-ingress not found"
echo "$I" | jq -e '.spec.ingressClassName=="nginx" and ([.spec.rules[] | select(.host=="www.example.com") | .http.paths[] | select(.path=="/" and .pathType=="Prefix" and .backend.service.name=="www" and .backend.service.port.number==80)] | length == 1)' >/dev/null \
  && pass "Ingress correct" || fail "www-ingress must route www.example.com / (Prefix) to www:80 with ingressClassName nginx"
