#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc provider -n payments -o json 2>/dev/null) || fail "Service provider not found"
echo "$S" | jq -e '.spec.type=="ExternalName" and .spec.externalName=="api.payments-provider.example.com"' >/dev/null \
  && pass "ExternalName Service correct" || fail "provider must be type ExternalName with externalName api.payments-provider.example.com"
