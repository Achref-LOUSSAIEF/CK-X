#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
A=$(kubectl get clusterrole monitoring-aggregate -o json 2>/dev/null) || fail "ClusterRole monitoring-aggregate not found"
echo "$A" | jq -e '[.aggregationRule.clusterRoleSelectors[]?.matchLabels["rbac.ckx.io/aggregate-to-monitoring"]] | index("true")' >/dev/null || fail "aggregationRule must select rbac.ckx.io/aggregate-to-monitoring=true"
for r in monitoring-pods monitoring-nodes; do
  [ "$(kubectl get clusterrole $r -o jsonpath='{.metadata.labels.rbac\.ckx\.io/aggregate-to-monitoring}' 2>/dev/null)" = "true" ] || fail "ClusterRole $r is missing or not labeled for aggregation"
done
pass "Aggregation configured"
