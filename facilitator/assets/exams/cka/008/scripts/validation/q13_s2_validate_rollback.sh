#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy checkout -n checkout -o json 2>/dev/null) || fail "Deployment checkout not found"
echo "$D" | jq -e '.spec.template.spec.containers[0].image=="nginx:1.25"' >/dev/null || fail "checkout does not run nginx:1.25"
R=$(echo "$D" | jq -r '.metadata.annotations["deployment.kubernetes.io/revision"]')
[ "${R:-0}" -ge 5 ] || fail "checkout was not rolled back (use kubectl rollout undo --to-revision)"
kubectl get rs -n checkout -o json | jq -e '[.items[] | select(.spec.template.spec.containers[0].image=="nginx:1.25")] | length == 1' >/dev/null \
  && pass "Rolled back to nginx:1.25" || fail "The original ReplicaSet was not reused"
