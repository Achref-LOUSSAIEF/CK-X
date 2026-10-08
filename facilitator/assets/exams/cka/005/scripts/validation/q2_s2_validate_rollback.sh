#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
IMG=$(kubectl get deploy payment-service -n payments -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null) || fail "Deployment not found"
[ "$IMG" = "nginx:1.25" ] || fail "Image is $IMG (expected the last working version nginx:1.25)"
kubectl rollout status deploy/payment-service -n payments --timeout=20s >/dev/null 2>&1
R=$(kubectl get deploy payment-service -n payments -o jsonpath='{.status.readyReplicas}')
U=$(kubectl get deploy payment-service -n payments -o jsonpath='{.status.updatedReplicas}')
[ "${R:-0}" -eq 3 ] && [ "${U:-0}" -eq 3 ] && pass "Rolled back, 3/3 Ready" || fail "Ready ${R:-0}/3"
