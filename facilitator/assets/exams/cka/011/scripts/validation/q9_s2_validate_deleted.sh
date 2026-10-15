#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
grep -qs '^HOSTNAME=envdump' /tmp/exam/q9/env.txt || fail "The output of the Pod envdump was not saved"
kubectl get pod envdump -n oneoff >/dev/null 2>&1 && fail "The Pod envdump still exists"
pass "The Pod envdump was removed"
