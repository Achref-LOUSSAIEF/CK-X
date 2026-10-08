#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get svc database-cluster -n db-cluster -o jsonpath='{.spec.clusterIP}|{.spec.ports[0].port}|{.spec.selector.app}' 2>/dev/null) || fail "Service database-cluster not found"
[ "$V" = "None|5432|database-cluster" ] && pass "Headless Service correct" || fail "Service incorrect: $V"
