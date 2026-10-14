#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get netpol restrict-egress -n dev -o json 2>/dev/null) || fail "NetworkPolicy restrict-egress not found"
echo "$P" | jq -e '.spec.podSelector.matchLabels.role=="restricted" and (.spec.policyTypes | index("Egress"))' >/dev/null || fail "restrict-egress must select role=restricted with policyType Egress"
echo "$P" | jq -e '[.spec.egress[]? | select([.to[]? | select(.podSelector.matchLabels.app=="api" and .namespaceSelector==null)] | length > 0) | select([.ports[]? | select((.protocol // "TCP")=="TCP" and .port==80)] | length > 0)] | length > 0' >/dev/null || fail "No egress rule to app=api Pods on TCP 80"
echo "$P" | jq -e '[.spec.egress[]? | select([.ports[]? | "\(.protocol // "TCP")/\(.port)"] | (index("UDP/53") and index("TCP/53")))] | length > 0' >/dev/null || fail "No egress rule for DNS (UDP and TCP 53)"
pass "Policy correct"
