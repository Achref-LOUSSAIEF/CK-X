#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q12/high-cpu.txt
[ -f "$F" ] || fail "$F not found"
[ "$(tr -d '[:space:]' < "$F" | sed 's#^pod/##')" = "log-shipper" ] && pass "log-shipper" || fail "$F does not contain the name of the Pod using the most CPU"
