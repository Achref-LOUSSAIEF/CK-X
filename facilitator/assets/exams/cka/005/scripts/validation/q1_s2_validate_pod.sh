#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pod dns-test -n backend -o jsonpath='{.spec.containers[0].image}|{.status.phase}' 2>/dev/null) || fail "Pod dns-test not found"
[ "$V" = "busybox:1.36|Running" ] && pass "dns-test running" || fail "dns-test incorrect: $V"
