#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get deploy web -n frontend >/dev/null 2>&1 || fail "Deployment web not found in frontend"
kubectl rollout status deploy/web -n frontend --timeout=40s >/dev/null 2>&1
A=$(kubectl get deploy web -n frontend -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -eq 3 ] && pass "web: 3/3 available" || fail "web has ${A:-0}/3 available replicas"
