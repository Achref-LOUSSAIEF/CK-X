#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/report-generator -n sched-debug --timeout=20s >/dev/null 2>&1
R=$(kubectl get deploy report-generator -n sched-debug -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 2 ] && pass "2/2 Ready" || fail "Ready replicas: ${R:-0}/2"
