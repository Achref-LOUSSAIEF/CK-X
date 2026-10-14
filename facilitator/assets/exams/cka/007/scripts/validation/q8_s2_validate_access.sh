#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
B=$(kubectl get clusterrolebinding prometheus-monitoring -o jsonpath='{.roleRef.name}|{.subjects[0].kind}/{.subjects[0].namespace}/{.subjects[0].name}' 2>/dev/null) || fail "ClusterRoleBinding prometheus-monitoring not found"
[ "$B" = "monitoring-aggregate|ServiceAccount/monitoring/prometheus" ] || fail "Binding incorrect: $B"
AS="--as=system:serviceaccount:monitoring:prometheus"
for c in "list pods -A" "watch services -A" "get nodes" "list nodes"; do
  [ "$(kubectl auth can-i $c $AS 2>/dev/null)" = "yes" ] || fail "prometheus cannot: $c"
done
for c in "delete pods -A" "list secrets -A" "watch nodes"; do
  [ "$(kubectl auth can-i $c $AS 2>/dev/null)" = "no" ] || fail "prometheus should not be able to: $c"
done
pass "Permissions correct"
