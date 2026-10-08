#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/batch-processor -n trbl-sched --timeout=20s >/dev/null 2>&1
A=$(kubectl get deploy batch-processor -n trbl-sched -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -eq 2 ] && pass "2/2 replicas available" || fail "Available replicas: ${A:-0}/2"
