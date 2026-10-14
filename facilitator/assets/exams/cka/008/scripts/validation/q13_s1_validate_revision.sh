#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q13/revision.txt
[ -f "$F" ] || fail "$F not found"
[ "$(tr -d '[:space:]' < "$F")" = "1" ] && pass "Revision 1" || fail "$F does not contain the revision that ran nginx:1.25"
