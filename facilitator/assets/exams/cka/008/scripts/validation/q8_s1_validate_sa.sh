#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get sa builder -n ci -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null) || fail "ServiceAccount builder not found"
[ "$V" = "false" ] && pass "automountServiceAccountToken false" || fail "builder must set automountServiceAccountToken: false"
