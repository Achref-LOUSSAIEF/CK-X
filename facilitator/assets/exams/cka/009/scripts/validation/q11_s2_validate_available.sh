#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get deploy checkout -n shop >/dev/null 2>&1 || fail "Deployment checkout not found in shop"
kubectl rollout status deploy/checkout -n shop --timeout=40s >/dev/null 2>&1
A=$(kubectl get deploy checkout -n shop -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -eq 2 ] && pass "checkout: 2/2 available" || fail "checkout has ${A:-0}/2 available replicas"
