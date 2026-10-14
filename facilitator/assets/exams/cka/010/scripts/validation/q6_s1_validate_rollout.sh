#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get deploy catalog -n media -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)" = "nginx:1.27" ] || fail "catalog does not use nginx:1.27"
kubectl rollout status deploy/catalog -n media --timeout=40s >/dev/null 2>&1 && pass "Rolled out" || fail "catalog is not fully rolled out"
