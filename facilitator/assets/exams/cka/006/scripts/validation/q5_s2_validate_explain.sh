#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/subject.txt
[ -f "$F" ] || fail "$F not found"
grep -q "KIND: *Certificate" "$F" && grep -q "subject" "$F" && grep -q "organizations" "$F" \
  && pass "subject.txt correct" || fail "$F is not the kubectl explain output for certificate.spec.subject"
