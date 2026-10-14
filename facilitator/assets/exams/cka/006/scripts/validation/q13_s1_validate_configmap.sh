#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get cm secure-web-conf -n secure-web -o jsonpath='{.data.default\.conf}' 2>/dev/null) || fail "ConfigMap secure-web-conf not found"
L=$(echo "$C" | grep -E '^\s*ssl_protocols' | sed 's/;//' | xargs)
[ "$L" = "ssl_protocols TLSv1.3" ] && pass "ssl_protocols TLSv1.3" || fail "ssl_protocols line is '$L'"
