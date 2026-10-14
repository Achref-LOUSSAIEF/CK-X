#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q13/error.txt
[ -f "$F" ] || fail "$F not found"
grep -q "sleeep: not found" "$F" && pass "Error captured" || fail "$F does not contain the error line from the logs"
