#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
WANT=$(kubectl get ns maintenance -o jsonpath='{.metadata.annotations.ckx\.io/db-local-uid}')
V=$(kubectl get pod db-local -n maintenance -o jsonpath='{.metadata.uid}|{.spec.nodeName}|{.status.phase}' 2>/dev/null) || fail "Pod db-local was deleted"
[ "$V" = "$WANT|k3d-cluster-agent-1|Running" ] && pass "db-local untouched" || fail "db-local was recreated, moved or is not Running ($V)"
