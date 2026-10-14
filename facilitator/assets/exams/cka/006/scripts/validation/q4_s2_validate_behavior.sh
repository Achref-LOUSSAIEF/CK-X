#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
W=$(kubectl get hpa.v2.autoscaling checkout-hpa -n checkout -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}' 2>/dev/null)
[ "$W" = "120" ] && pass "Stabilization window 120s" || fail "scaleDown.stabilizationWindowSeconds is '${W:-unset}'"
