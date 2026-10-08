#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get csr john -o json 2>/dev/null) || fail "CertificateSigningRequest john not found"
echo "$C" | jq -e '.spec.signerName=="kubernetes.io/kube-apiserver-client" and (.spec.usages|index("client auth")) and .spec.expirationSeconds==86400' >/dev/null || fail "signerName/usages/expirationSeconds incorrect"
REQ=$(echo "$C" | jq -r '.spec.request' | base64 -d 2>/dev/null)
[ "$REQ" = "$(cat /tmp/exam/q10/john.csr)" ] && pass "CSR correct" || fail "CSR request does not match /tmp/exam/q10/john.csr"
