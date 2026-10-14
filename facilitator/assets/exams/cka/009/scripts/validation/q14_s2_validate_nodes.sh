#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status ds/log-agent -n kube-system --timeout=40s >/dev/null 2>&1
N=$(kubectl get nodes --no-headers | wc -l)
R=$(kubectl get ds log-agent -n kube-system -o jsonpath='{.status.numberReady}')
[ "${R:-0}" -eq "$N" ] && pass "$R/$N nodes" || fail "log-agent is ready on ${R:-0} of $N nodes"
