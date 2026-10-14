#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
U=$(kubectl get svc database -n startup -o jsonpath='{.metadata.uid}' 2>/dev/null) || fail "Service database was deleted"
[ "$U" = "$(kubectl get ns startup -o jsonpath='{.metadata.annotations.ckx\.io/database-svc-uid}')" ] || fail "Service database was recreated"
[ "$(kubectl get svc database -n startup -o jsonpath='{.spec.selector.app}|{.spec.ports[0].port}')" = "database|5432" ] || fail "Service database was changed"
C=$(kubectl get deploy api -n startup -o jsonpath='{.spec.template.spec.initContainers[0].command[*]} {.spec.template.spec.initContainers[0].args[*]}' 2>/dev/null) || fail "Deployment api not found"
echo "$C" | grep -q "nslookup" || fail "The init container must still wait with nslookup"
echo "$C" | grep -qE "nslookup database([. ;]|$)" && pass "Init container fixed" || fail "The init container does not look up the Service database"
