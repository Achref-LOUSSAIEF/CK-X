#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
U=http://db.np-db.svc.cluster.local
kubectl exec api -n np-backend -- wget -qO- -T 4 $U >/dev/null 2>&1 || fail "np-backend/api cannot reach db (should be allowed)"
kubectl exec worker -n np-backend -- wget -qO- -T 4 $U >/dev/null 2>&1 && fail "np-backend/worker can reach db (should be denied)"
kubectl exec api -n np-other -- wget -qO- -T 4 $U >/dev/null 2>&1 && fail "np-other/api can reach db (should be denied)"
pass "NetworkPolicies enforced correctly"
