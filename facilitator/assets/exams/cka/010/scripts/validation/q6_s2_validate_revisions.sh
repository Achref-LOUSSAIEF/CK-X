#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q6/catalog-revisions.txt
[ -f "$F" ] || fail "$F not found"
N=$(kubectl rollout history deploy/catalog -n media 2>/dev/null | grep -cE '^[0-9]+')
[ "$(tr -d '[:space:]' < "$F")" = "$N" ] && pass "$N revisions" || fail "$F does not contain the number of revisions ($N)"
