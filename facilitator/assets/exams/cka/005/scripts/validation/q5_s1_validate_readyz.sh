#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/readyz.txt
[ -f "$F" ] || fail "$F not found"
grep -q "readyz check passed" "$F" && grep -q "\[+\]" "$F" && pass "Verbose readyz output saved" || fail "$F is not the output of /readyz?verbose"
