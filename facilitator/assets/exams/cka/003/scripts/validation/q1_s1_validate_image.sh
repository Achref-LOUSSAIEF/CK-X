#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
IMG=$(kubectl get deploy payment-api -n trbl-deploy -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null) || fail "Deployment payment-api not found"
[ "$IMG" = "nginx:1.25-alpine" ] && pass "Image is $IMG" || fail "Expected image nginx:1.25-alpine, got '$IMG'"
