#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get ns frontend >/dev/null 2>&1 || fail "Namespace frontend not found"
D=$(kubectl get deploy web -n frontend -o json 2>/dev/null) || fail "Deployment web not found in frontend"
echo "$D" | jq -e '.spec.replicas==3 and .spec.template.spec.containers[0].image=="nginx:1.27" and ([.spec.template.spec.containers[0].ports[]? | select(.containerPort==80)] | length == 1)' >/dev/null \
  && pass "web correct" || fail "web must have 3 replicas, image nginx:1.27 and containerPort 80"
