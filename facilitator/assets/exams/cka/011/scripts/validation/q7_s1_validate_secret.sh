#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get secret app-secret -n secret-lab -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)
[ "$V" = "n0t-s0-s3cret" ] && pass "Secret app-secret" || fail "Secret app-secret with password=n0t-s0-s3cret not found"
