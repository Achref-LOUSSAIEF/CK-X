#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q2/bad-revision.txt
[ -f "$F" ] || fail "$F not found"
[ "$(tr -d '[:space:]' < "$F")" = "3" ] && pass "Revision 3 identified" || fail "Wrong revision in $F"
