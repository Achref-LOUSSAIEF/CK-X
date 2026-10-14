#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
A="--as=system:serviceaccount:apps:deploy-bot -n apps"
for v in create get list update; do
  [ "$(kubectl auth can-i $v deployments.apps $A 2>/dev/null)" = "yes" ] || fail "deploy-bot cannot $v deployments"
done
[ "$(kubectl auth can-i delete deployments.apps $A 2>/dev/null)" = "no" ] || fail "deploy-bot must not delete deployments"
[ "$(kubectl auth can-i create pods $A 2>/dev/null)" = "no" ] || fail "deploy-bot must not create pods"
pass "Permissions correct"
