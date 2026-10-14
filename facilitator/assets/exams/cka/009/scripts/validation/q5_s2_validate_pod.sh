#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod prod-pod -n default -o json 2>/dev/null) || fail "Pod prod-pod not found"
echo "$P" | jq -e '[.spec.tolerations[]? | select(.key=="env" and (.effect // "NoSchedule")=="NoSchedule" and ((.operator // "Equal")=="Exists" or .value=="prod"))] | length > 0' >/dev/null || fail "prod-pod needs a toleration for env=prod:NoSchedule"
kubectl wait --for=condition=Ready pod/prod-pod -n default --timeout=30s >/dev/null 2>&1 || fail "prod-pod is not Ready"
[ "$(kubectl get pod prod-pod -n default -o jsonpath='{.spec.nodeName}')" = "k3d-cluster-agent-1" ] && pass "prod-pod on k3d-cluster-agent-1" || fail "prod-pod does not run on k3d-cluster-agent-1"
