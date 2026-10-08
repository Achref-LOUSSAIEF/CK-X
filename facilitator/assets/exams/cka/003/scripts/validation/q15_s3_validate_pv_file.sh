#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q15/pv-name.txt
[ -f "$F" ] || fail "$F not found"
PV=$(kubectl get pvc ledger-data -n storage-ops -o jsonpath='{.spec.volumeName}' 2>/dev/null)
[ -n "$PV" ] && [ "$(tr -d '[:space:]' < "$F")" = "$PV" ] && pass "pv-name.txt correct" || fail "pv-name.txt does not contain '$PV'"
