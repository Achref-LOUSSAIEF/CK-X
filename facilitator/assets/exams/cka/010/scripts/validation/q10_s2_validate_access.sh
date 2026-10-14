#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
for v in get list watch; do
  [ "$(kubectl auth can-i $v nodes --as=dave 2>/dev/null)" = "yes" ] || fail "dave cannot $v nodes"
done
[ "$(kubectl auth can-i delete nodes --as=dave 2>/dev/null)" = "no" ] && pass "Access correct" || fail "dave must not be able to delete nodes"
