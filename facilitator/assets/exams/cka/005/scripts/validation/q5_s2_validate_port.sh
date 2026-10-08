#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/apiserver-port.txt
[ -f "$F" ] || fail "$F not found"
P=$(kubectl get endpointslices -n default -l kubernetes.io/service-name=kubernetes -o jsonpath='{.items[0].ports[0].port}')
[ "$(tr -d '[:space:]' < "$F")" = "$P" ] && pass "Port $P" || fail "Wrong port in $F"
