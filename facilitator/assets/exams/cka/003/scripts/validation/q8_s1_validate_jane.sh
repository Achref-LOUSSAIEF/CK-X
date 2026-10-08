#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
for r in nodes persistentvolumes; do
  for v in get list watch; do
    [ "$(kubectl auth can-i $v $r --as jane 2>/dev/null)" = "yes" ] || fail "jane cannot $v $r"
  done
done
[ "$(kubectl auth can-i delete nodes --as jane 2>/dev/null)" = "no" ] || fail "jane has too many permissions (can delete nodes)"
[ "$(kubectl auth can-i list pods -A --as jane 2>/dev/null)" = "no" ] || fail "jane has too many permissions (can list pods)"
pass "jane permissions correct"
