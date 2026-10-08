#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get resourcequota test-quota -n test -o jsonpath='{.spec.hard.requests\.cpu}|{.spec.hard.requests\.memory}' 2>/dev/null) || fail "ResourceQuota test-quota not found"
[ "$V" = "4|8Gi" ] && pass "Quota correct" || fail "Quota incorrect: $V"
