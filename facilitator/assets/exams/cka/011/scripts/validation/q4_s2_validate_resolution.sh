#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/dns-client -n dns-custom --timeout=30s >/dev/null 2>&1 || fail "The Pod dns-client is not Ready"
for i in 1 2 3; do
  OUT=$(kubectl exec -n dns-custom dns-client -- nslookup myapp.internal. 2>/dev/null)
  echo "$OUT" | grep -A3 '^Name:' | grep -q '10\.10\.10\.10' && pass "myapp.internal resolves to 10.10.10.10"
  sleep 3
done
fail "myapp.internal does not resolve to 10.10.10.10 from Pods"
