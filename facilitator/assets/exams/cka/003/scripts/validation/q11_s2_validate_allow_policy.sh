#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get netpol allow-backend-api -n np-db -o json 2>/dev/null) || fail "NetworkPolicy allow-backend-api not found"
echo "$P" | jq -e '.spec.podSelector.matchLabels.app == "db"' >/dev/null || fail "Policy must select app=db"
echo "$P" | jq -e '[.spec.ingress[].from[]? | select(.namespaceSelector.matchLabels.team=="backend" and .podSelector.matchLabels.role=="api")] | length > 0' >/dev/null \
  || fail "Need a single 'from' entry with namespaceSelector team=backend AND podSelector role=api"
echo "$P" | jq -e '[.spec.ingress[].from[]? | select(.namespaceSelector == null or .podSelector == null)] | length == 0' >/dev/null \
  || fail "Policy has an extra peer that is too permissive"
echo "$P" | jq -e '[.spec.ingress[].ports[]? | select(.port==80 and ((.protocol // "TCP")=="TCP"))] | length > 0' >/dev/null \
  && pass "allow-backend-api correct" || fail "Policy must restrict to TCP port 80"
