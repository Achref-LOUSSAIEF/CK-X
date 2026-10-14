#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod east-pod -n default -o json 2>/dev/null) || fail "Pod east-pod not found"
echo "$P" | jq -e '(.spec.nodeSelector // {} | length == 0) and ([.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[]?.matchExpressions[]? | select(.key=="zone" and .operator=="In" and (.values|index("east")) and (.values|index("west")|not))] | length > 0)' >/dev/null \
  && pass "Affinity correct" || fail "east-pod needs requiredDuringScheduling node affinity zone In [east] and no nodeSelector"
