#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
A="--as=jane -n config"
for c in "get configmap/app-settings" "update configmap/app-settings" "patch configmap/app-settings"; do
  [ "$(kubectl auth can-i $c $A 2>/dev/null)" = "yes" ] || fail "jane cannot: $c"
done
for c in "get configmap/db-settings" "update configmap/db-settings" "list configmaps" "create configmaps" "delete configmap/app-settings"; do
  [ "$(kubectl auth can-i $c $A 2>/dev/null)" = "no" ] || fail "jane should not be able to: $c"
done
pass "Access correct"
