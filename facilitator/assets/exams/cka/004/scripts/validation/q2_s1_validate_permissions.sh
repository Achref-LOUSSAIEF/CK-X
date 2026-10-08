#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
A="--as dev-user"
[ "$(kubectl auth can-i list pods -n staging $A 2>/dev/null)" = "yes" ] || fail "dev-user cannot list pods in staging"
[ "$(kubectl auth can-i list deployments.apps -n staging $A 2>/dev/null)" = "yes" ] || fail "dev-user cannot list deployments in staging"
[ "$(kubectl auth can-i list pods -n default $A 2>/dev/null)" = "no" ] || fail "dev-user can list pods outside staging"
[ "$(kubectl auth can-i delete pods -n staging $A 2>/dev/null)" = "no" ] || fail "dev-user can delete pods (too broad)"
pass "Permissions correct"
