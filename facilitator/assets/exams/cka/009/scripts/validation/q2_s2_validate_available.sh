#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get deploy api -n backend >/dev/null 2>&1 || fail "Deployment api not found in backend"
kubectl rollout status deploy/api -n backend --timeout=40s >/dev/null 2>&1
A=$(kubectl get deploy api -n backend -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -eq 5 ] && pass "api: 5/5 available" || fail "api has ${A:-0}/5 available replicas"
