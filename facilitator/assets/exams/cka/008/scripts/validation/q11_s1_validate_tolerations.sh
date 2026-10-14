#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
T=$(kubectl get deploy edge-cache -n edge -o json 2>/dev/null) || fail "Deployment edge-cache not found"
for k in node.kubernetes.io/unreachable node.kubernetes.io/not-ready; do
  echo "$T" | jq -e --arg k "$k" '[.spec.template.spec.tolerations[]? | select(.key==$k and .effect=="NoExecute" and (.operator // "Equal")=="Exists" and .tolerationSeconds==30)] | length == 1' >/dev/null \
    || fail "Missing toleration: key $k, operator Exists, effect NoExecute, tolerationSeconds 30"
done
pass "Tolerations correct"
