#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc db -n media -o json 2>/dev/null) || fail "Service db not found"
echo "$S" | jq -e '.spec.clusterIP=="None" and .spec.selector.app=="db" and .spec.ports[0].port==6379' >/dev/null \
  && pass "Headless Service correct" || fail "db must be headless, select app=db and use port 6379"
