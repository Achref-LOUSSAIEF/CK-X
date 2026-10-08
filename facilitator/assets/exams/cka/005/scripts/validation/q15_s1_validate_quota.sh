#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get resourcequota batch-jobs-quota -n batch-jobs -o jsonpath='{.spec.hard.limits\.cpu}|{.spec.hard.limits\.memory}' 2>/dev/null) || fail "ResourceQuota batch-jobs-quota not found"
[ "$V" = "10|20Gi" ] && pass "Quota correct" || fail "Quota incorrect: $V"
