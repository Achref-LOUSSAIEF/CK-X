#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get bk nightly -n crd-lab -o jsonpath='{.spec.schedule}|{.spec.retentionDays}' 2>/dev/null) || fail "Backup nightly not found via short name bk"
[ "$V" = "0 2 * * *|7" ] && pass "Backup nightly correct" || fail "Backup nightly has wrong values: $V"
