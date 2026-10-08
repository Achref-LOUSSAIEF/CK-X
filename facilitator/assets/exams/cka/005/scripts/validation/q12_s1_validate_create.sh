#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get databases.stable.example.com prod-db -n crd-db -o jsonpath='{.spec.engine}|{.spec.version}|{.spec.storageGB}' 2>/dev/null) || fail "Database prod-db not found"
[ "$V" = "postgres|16|20" ] && pass "prod-db correct" || fail "prod-db incorrect: $V"
