#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/vault-agent -n vault --timeout=20s >/dev/null 2>&1 || fail "vault-agent is not Ready"
[ "$(kubectl exec vault-agent -n vault -- cat /etc/app/token 2>/dev/null)" = "tok-7f3a9c" ] || fail "/etc/app/token does not contain the api-token"
kubectl exec vault-agent -n vault -- sh -c 'ls -A /etc/app' 2>/dev/null | grep -q "db-password" && fail "db-password is visible in /etc/app"
pass "Only the token is mounted"
