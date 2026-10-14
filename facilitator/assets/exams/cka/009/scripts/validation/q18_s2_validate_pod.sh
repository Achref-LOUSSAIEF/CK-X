#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod compliant -n secure-apps -o json 2>/dev/null) || fail "Pod compliant not found"
echo "$P" | jq -e '((.spec.containers[0].securityContext.runAsUser // .spec.securityContext.runAsUser)==1000)' >/dev/null || fail "compliant must run as user 1000"
kubectl wait --for=condition=Ready pod/compliant -n secure-apps --timeout=30s >/dev/null 2>&1 && pass "compliant running" || fail "compliant is not Ready"
