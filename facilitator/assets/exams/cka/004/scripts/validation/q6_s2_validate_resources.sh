#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get deploy monitoring-stack -n monitoring -o jsonpath='{.spec.replicas}' 2>/dev/null) || fail "Deployment monitoring-stack not found"
[ "$R" = "3" ] || fail "Deployment has $R replicas"
S=$(kubectl get pvc monitoring-stack-data -n monitoring -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null) || fail "PVC monitoring-stack-data not found (persistence not enabled?)"
[ "$S" = "50Gi" ] && pass "Deployment and PVC correct" || fail "PVC size is $S"
