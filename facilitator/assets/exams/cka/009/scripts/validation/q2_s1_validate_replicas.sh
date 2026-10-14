#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get deploy api -n backend -o jsonpath='{.spec.replicas}' 2>/dev/null) || fail "Deployment api not found"
[ "$R" = "5" ] && pass "replicas 5" || fail "api has spec.replicas=$R, expected 5"
