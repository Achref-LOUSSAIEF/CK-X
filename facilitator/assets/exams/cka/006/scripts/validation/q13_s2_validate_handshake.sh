#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/secure-web -n secure-web --timeout=30s >/dev/null 2>&1 || fail "secure-web is not ready"
X="kubectl exec tls-client -n secure-web --"
$X curl -sk --max-time 5 --tlsv1.3 https://secure-web 2>/dev/null | grep -q "secure-web ok" || fail "TLS 1.3 request fails"
$X curl -sk --max-time 5 --tls-max 1.2 https://secure-web >/dev/null 2>&1 && fail "TLS 1.2 is still accepted (did the Pods reload the config?)"
pass "Only TLS 1.3 accepted"
