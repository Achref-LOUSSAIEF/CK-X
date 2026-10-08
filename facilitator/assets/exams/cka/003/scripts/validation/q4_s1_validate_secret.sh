#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get secret order-db -n trbl-config -o jsonpath='{.data.password}' 2>/dev/null) || fail "Secret order-db not found"
[ "$(echo "$V" | base64 -d)" = 'Sup3rS3cret!' ] && pass "Secret value correct" || fail "Secret key 'password' has wrong value"
