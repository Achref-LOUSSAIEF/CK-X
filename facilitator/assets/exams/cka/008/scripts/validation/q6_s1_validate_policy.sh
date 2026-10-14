#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get netpol crawler-egress -n crawler -o json 2>/dev/null) || fail "NetworkPolicy crawler-egress not found"
echo "$P" | jq -e '.spec.podSelector.matchLabels.app=="crawler" and (.spec.policyTypes==["Egress"])' >/dev/null || fail "Policy must select app=crawler with policyTypes [Egress] only"
echo "$P" | jq -e '[.spec.egress[] | select(.to[]?.ipBlock | (.cidr=="10.20.0.0/16" and .except==["10.20.5.0/24"])) | select([.ports[]? | select((.protocol // "TCP")=="TCP" and .port==8000 and .endPort==8100)] | length == 1) | select((.ports|length)==1)] | length == 1' >/dev/null \
  || fail "Missing a rule to 10.20.0.0/16 except 10.20.5.0/24 on TCP 8000-8100 (port + endPort)"
echo "$P" | jq -e '[.spec.egress[] | select((.to // []) | length == 0) | [.ports[]? | "\(.protocol // "TCP")/\(.port)"] | sort] | any(. == ["TCP/53","UDP/53"])' >/dev/null || fail "Missing a rule allowing DNS (UDP+TCP 53) to any destination"
[ "$(echo "$P" | jq '.spec.egress | length')" -eq 2 ] && pass "crawler-egress correct" || fail "crawler-egress must contain exactly the two egress rules"
