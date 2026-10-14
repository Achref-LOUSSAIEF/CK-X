#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
Qh=$(kubectl get resourcequota compute -n quota-lab -o jsonpath='{.spec.hard.requests\.cpu}|{.spec.hard.requests\.memory}|{.spec.hard.limits\.cpu}|{.spec.hard.limits\.memory}' 2>/dev/null) || fail "ResourceQuota compute was deleted"
[ "$Qh" = "1|1Gi|2|2Gi" ] || fail "ResourceQuota compute was changed ($Qh)"
R=$(kubectl get deploy inventory -n quota-lab -o json 2>/dev/null) || fail "Deployment inventory not found"
echo "$R" | jq -e '.spec.template.spec.containers[0].resources | .requests.cpu=="100m" and .requests.memory=="64Mi" and .limits.cpu=="200m" and .limits.memory=="128Mi"' >/dev/null \
  && pass "Resources set" || fail "Resources incorrect: $(echo "$R" | jq -c '.spec.template.spec.containers[0].resources')"
