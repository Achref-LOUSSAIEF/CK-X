#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get deploy analytics -n analytics >/dev/null 2>&1 || fail "Deployment analytics not found in analytics"
kubectl rollout status deploy/analytics -n analytics --timeout=40s >/dev/null 2>&1
A=$(kubectl get deploy analytics -n analytics -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -ge 2 ] && pass "analytics: ${A} available" || fail "analytics has ${A:-0}/2 available replicas"
