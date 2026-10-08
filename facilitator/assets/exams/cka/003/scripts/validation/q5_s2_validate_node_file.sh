#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/node.txt
[ -f "$F" ] || fail "$F not found"
NODE=$(kubectl get pod audit-app -n logging -o jsonpath='{.spec.nodeName}')
[ "$(tr -d '[:space:]' < "$F")" = "$NODE" ] && pass "node.txt = $NODE" || fail "node.txt does not contain '$NODE'"
