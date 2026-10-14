#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
U=$(kubectl get pod report -n reports -o jsonpath='{.metadata.uid}' 2>/dev/null) || fail "Pod report not found"
[ "$U" = "$(kubectl get ns reports -o jsonpath='{.metadata.annotations.ckx\.io/report-uid}')" ] || fail "The Pod report was deleted and recreated"
[ "$(kubectl get cm report-config -n reports -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null)" = "info" ] && pass "Key added" || fail "The ConfigMap report-config has no key LOG_LEVEL=info"
