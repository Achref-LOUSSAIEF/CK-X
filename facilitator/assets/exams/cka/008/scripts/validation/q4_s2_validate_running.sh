#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/api -n startup --timeout=40s >/dev/null 2>&1
A=$(kubectl get deploy api -n startup -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -ge 1 ] && pass "api running" || fail "api has no available Pod"
