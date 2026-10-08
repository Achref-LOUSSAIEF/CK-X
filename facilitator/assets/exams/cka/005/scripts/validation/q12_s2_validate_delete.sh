#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get crd databases.stable.example.com >/dev/null 2>&1 || fail "The CRD itself was deleted"
kubectl get databases.stable.example.com legacy-db -n crd-db >/dev/null 2>&1 && fail "legacy-db still exists"
pass "legacy-db deleted"
