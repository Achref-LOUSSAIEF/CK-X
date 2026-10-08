#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
chk() { # name tier fromTier port
  P=$(kubectl get netpol "$1" -n shop -o json 2>/dev/null) || fail "NetworkPolicy $1 not found"
  echo "$P" | jq -e --arg t "$2" '.spec.podSelector.matchLabels.tier == $t' >/dev/null || fail "$1 must select tier=$2"
  echo "$P" | jq -e --argjson p "$4" '[.spec.ingress[]?.ports[]? | select(.port==$p and ((.protocol // "TCP")=="TCP"))] | length > 0' >/dev/null || fail "$1 must allow TCP $4"
  echo "$P" | jq -e --argjson p "$4" '[.spec.ingress[]?.ports[]? | select(.port!=$p)] | length == 0' >/dev/null || fail "$1 allows extra ports"
  if [ -n "$3" ]; then
    echo "$P" | jq -e --arg f "$3" '[.spec.ingress[] | .from // [] ] | flatten | (length > 0 and all(.podSelector.matchLabels.tier == $f and .namespaceSelector == null and .ipBlock == null))' >/dev/null \
      || fail "$1 must only allow sources with tier=$3"
  fi
}
chk frontend-policy frontend "" 80
chk backend-policy backend frontend 3000
chk database-policy database backend 5432
pass "All three policies correct"
