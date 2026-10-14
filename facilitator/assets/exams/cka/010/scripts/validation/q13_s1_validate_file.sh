#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q13/license.txt
[ -f "$F" ] || fail "$F not found"
[ "$(tr -d '[:space:]' < "$F")" = "LIC-7731-EAST" ] && pass "Decoded" || fail "$F does not contain the decoded value"
