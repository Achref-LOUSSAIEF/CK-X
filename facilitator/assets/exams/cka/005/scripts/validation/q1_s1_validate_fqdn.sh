#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q1/dns-name.txt
[ -f "$F" ] || fail "$F not found"
V=$(tr -d '[:space:]' < "$F" | sed 's/\.$//; s/:3000$//')
[ "$V" = "web-ui.frontend.svc.cluster.local" ] && pass "FQDN correct" || fail "Wrong name: $V"
