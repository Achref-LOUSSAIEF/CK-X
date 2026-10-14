#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
WANT=$(kubectl get ns reports -o jsonpath='{.metadata.annotations.ckx\.io/report-api-uid}')
D=$(kubectl get deploy report-api -n reports -o json 2>/dev/null) || fail "Deployment report-api not found"
[ "$(echo "$D" | jq -r '.metadata.uid')" = "$WANT" ] || fail "report-api was deleted and recreated"
echo "$D" | jq -e '.spec.template.spec.containers[0].resources | .requests.cpu=="250m" and .requests.memory=="256Mi" and .limits.cpu=="500m" and .limits.memory=="512Mi"' >/dev/null \
  && pass "Resources patched" || fail "Resources incorrect: $(echo "$D" | jq -c '.spec.template.spec.containers[0].resources')"
