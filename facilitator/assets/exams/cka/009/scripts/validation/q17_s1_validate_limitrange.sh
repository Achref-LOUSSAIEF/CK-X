#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get limitrange defaults -n team-a >/dev/null 2>&1 || fail "LimitRange defaults not found"
R=$(kubectl run ckx-test -n team-a --image=nginx:1.27 --dry-run=server -o json 2>/dev/null) || fail "A test Pod cannot be created in team-a"
echo "$R" | jq -e '.spec.containers[0].resources | .requests.cpu=="100m" and .requests.memory=="128Mi" and .limits.cpu=="200m" and .limits.memory=="256Mi"' >/dev/null \
  && pass "Defaults applied" || fail "A Pod without resources gets $(echo "$R" | jq -c '.spec.containers[0].resources')"
