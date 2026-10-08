#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
get() { kubectl exec "$1" -n shop -- wget -qO- -T 4 "http://$2" >/dev/null 2>&1; }
IP() { kubectl get pod "$1" -n shop -o jsonpath='{.status.podIP}'; }
FE=$(IP frontend); BE=$(IP backend); DB=$(IP database)
get tester "$FE:80"     || fail "tester cannot reach frontend:80"
get frontend "$BE:3000" || fail "frontend cannot reach backend:3000"
get backend "$DB:5432"  || fail "backend cannot reach database:5432"
get tester "$BE:3000"   && fail "tester can reach backend (should be denied)"
get frontend "$DB:5432" && fail "frontend can reach database (should be denied)"
get tester "$DB:5432"   && fail "tester can reach database (should be denied)"
pass "Traffic flow enforced"
