#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get deploy catalog -n catalog -o jsonpath='{.spec.template.spec.containers[0].ports[?(@.name=="http")].containerPort}' 2>/dev/null)
[ "$V" = "80" ] && pass "Port http=80 declared" || fail "Container port named http with 80 not found"
