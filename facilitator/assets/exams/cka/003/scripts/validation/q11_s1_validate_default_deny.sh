#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get netpol default-deny-ingress -n np-db -o json 2>/dev/null) || fail "NetworkPolicy default-deny-ingress not found"
echo "$P" | jq -e '(.spec.podSelector | length == 0 or ((.matchLabels // {} | length == 0) and (.matchExpressions // [] | length == 0)))
  and (.spec.policyTypes | index("Ingress"))
  and ((.spec.ingress // []) | length == 0)' >/dev/null && pass "default deny correct" || fail "default-deny-ingress must select all Pods, have policyType Ingress and no ingress rules"
