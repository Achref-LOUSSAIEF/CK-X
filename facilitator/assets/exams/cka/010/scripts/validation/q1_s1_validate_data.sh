#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get cm app-config -n dev -o jsonpath='{.data.APP_MODE}' 2>/dev/null)" = "production" ] || fail "ConfigMap app-config must hold APP_MODE=production"
[ "$(kubectl get secret app-secret -n dev -o jsonpath='{.data.DB_PASS}' 2>/dev/null | base64 -d)" = "s3cret" ] && pass "Data correct" || fail "Secret app-secret must hold DB_PASS=s3cret"
