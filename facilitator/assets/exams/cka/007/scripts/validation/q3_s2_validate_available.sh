#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/inventory -n quota-lab --timeout=30s >/dev/null 2>&1
A=$(kubectl get deploy inventory -n quota-lab -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -eq 2 ] && pass "2/2 available" || fail "Available replicas: ${A:-0}/2"
