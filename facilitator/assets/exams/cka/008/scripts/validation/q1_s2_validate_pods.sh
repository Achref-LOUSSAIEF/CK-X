#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
for _ in $(seq 1 15); do
  I2=$(kubectl get pod web-2 -n stateful -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
  R2=$(kubectl get pod web-2 -n stateful -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
  [ "$I2" = "nginx:1.27" ] && [ "$R2" = "true" ] && break; sleep 2
done
[ "$I2" = "nginx:1.27" ] && [ "$R2" = "true" ] || fail "web-2 is not running nginx:1.27 (image: $I2, ready: $R2)"
for p in web-0 web-1; do
  [ "$(kubectl get pod $p -n stateful -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)" = "nginx:1.25" ] || fail "$p must still run nginx:1.25"
done
pass "Only web-2 updated"
