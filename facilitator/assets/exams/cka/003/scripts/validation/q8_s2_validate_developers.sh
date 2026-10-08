#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
A="--as dev-user --as-group developers"
for v in get list create update patch delete; do
  [ "$(kubectl auth can-i $v deployments.apps -n rbac-lab $A 2>/dev/null)" = "yes" ] || fail "developers cannot $v deployments in rbac-lab"
done
[ "$(kubectl auth can-i create deployments.apps -n default $A 2>/dev/null)" = "no" ] || fail "developers can create deployments outside rbac-lab"
[ "$(kubectl auth can-i delete pods -n rbac-lab $A 2>/dev/null)" = "no" ] || fail "developers can delete pods (too broad)"
pass "developers permissions correct"
