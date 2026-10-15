#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q9/env.txt
[ -f "$F" ] || fail "$F not found"
grep -q '^HOSTNAME=envdump' "$F" || fail "$F does not hold the environment of a Pod named envdump"
grep -q '^KUBERNETES_SERVICE_HOST=' "$F" && pass "Environment saved" || fail "$F does not hold the output of env"
