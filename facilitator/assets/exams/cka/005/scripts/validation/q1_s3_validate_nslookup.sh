#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q1/nslookup.txt
[ -f "$F" ] || fail "$F not found"
IP=$(kubectl get svc web-ui -n frontend -o jsonpath='{.spec.clusterIP}')
grep -q "web-ui.frontend.svc.cluster.local" "$F" && grep -q "$IP" "$F" && pass "nslookup output correct" || fail "nslookup.txt does not show web-ui resolving to $IP"
