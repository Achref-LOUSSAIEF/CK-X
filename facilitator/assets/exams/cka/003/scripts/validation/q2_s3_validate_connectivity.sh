#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
OUT=$(kubectl exec client -n trbl-svc -- wget -qO- -T 5 http://web-svc 2>/dev/null)
echo "$OUT" | grep -qi "nginx" && pass "client receives the nginx page" || fail "client cannot reach http://web-svc"
