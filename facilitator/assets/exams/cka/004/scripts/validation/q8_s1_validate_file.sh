#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q8/cm-access.txt
[ -f "$F" ] || fail "$F not found"
ACT=$(grep -v '^[[:space:]]*$' "$F" | sed 's#^system:serviceaccount:audit-lab:##; s#^audit-lab/##; s/[[:space:]]//g' | sort -u | tr '\n' ' ')
[ "$ACT" = "ci deployer " ] && pass "Correct ServiceAccounts" || fail "Wrong list: $ACT"
