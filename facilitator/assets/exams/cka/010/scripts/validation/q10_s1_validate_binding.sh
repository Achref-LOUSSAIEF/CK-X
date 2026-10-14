#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get clusterrole node-reader >/dev/null 2>&1 || fail "ClusterRole node-reader not found"
B=$(kubectl get clusterrolebinding node-reader-dave -o json 2>/dev/null) || fail "ClusterRoleBinding node-reader-dave not found"
echo "$B" | jq -e '.roleRef.kind=="ClusterRole" and .roleRef.name=="node-reader" and ([.subjects[]? | select(.kind=="User" and .name=="dave")] | length == 1)' >/dev/null \
  && pass "Binding correct" || fail "node-reader-dave must bind ClusterRole node-reader to the User dave"
