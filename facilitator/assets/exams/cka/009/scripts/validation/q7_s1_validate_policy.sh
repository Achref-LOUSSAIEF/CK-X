#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get netpol allow-api-to-db -n db -o json 2>/dev/null) || fail "NetworkPolicy allow-api-to-db not found"
echo "$P" | jq -e '.spec.podSelector.matchLabels.app=="db" and (.spec.policyTypes | index("Ingress"))' >/dev/null || fail "The policy must select app=db and have policyType Ingress"
echo "$P" | jq -e '[.spec.ingress[]? | select([.from[]? | select(.podSelector.matchLabels.role=="api" and .namespaceSelector==null and .ipBlock==null)] | length > 0) | select([.ports[]? | select((.protocol // "TCP")=="TCP" and .port==6379)] | length > 0)] | length > 0' >/dev/null || fail "No ingress rule from role=api Pods on TCP 6379"
echo "$P" | jq -e '([.spec.ingress[]? | .from[]? | select(.podSelector.matchLabels.role!="api" or .namespaceSelector!=null or .ipBlock!=null)] | length == 0) and ([.spec.ingress[]? | select((.from // []) | length == 0)] | length == 0)' >/dev/null \
  && pass "Policy correct" || fail "The policy allows more than role=api Pods"
