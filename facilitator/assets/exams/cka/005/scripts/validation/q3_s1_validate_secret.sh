#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
for kv in username=dbuser password=secret123 database=appdb; do
  k=${kv%%=*}; v=${kv#*=}
  G=$(kubectl get secret db-creds -n app-secrets -o jsonpath="{.data.$k}" 2>/dev/null | base64 -d 2>/dev/null)
  [ "$G" = "$v" ] || fail "Secret db-creds key $k is wrong or missing"
done
pass "Secret correct"
