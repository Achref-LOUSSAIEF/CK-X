#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q10/john.crt
[ -f "$F" ] || fail "$F not found"
ISSUED=$(kubectl get csr john -o jsonpath='{.status.certificate}' | base64 -d)
[ "$(sed '/^$/d' "$F")" = "$(echo "$ISSUED" | sed '/^$/d')" ] || fail "$F does not match the issued certificate"
openssl x509 -in "$F" -noout -subject 2>/dev/null | grep -q "CN *= *john" && pass "Certificate saved" || fail "$F is not a valid certificate for CN=john"
