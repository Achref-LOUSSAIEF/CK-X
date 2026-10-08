#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get csr john -o jsonpath='{.status.conditions[*].type}' 2>/dev/null | grep -qw Approved || fail "CSR john is not approved"
[ -n "$(kubectl get csr john -o jsonpath='{.status.certificate}')" ] && pass "Certificate issued" || fail "No certificate issued yet"
