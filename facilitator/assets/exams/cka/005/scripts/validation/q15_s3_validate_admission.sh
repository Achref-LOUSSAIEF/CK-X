#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
BIG='{"apiVersion":"v1","kind":"Pod","metadata":{"name":"big","namespace":"batch-jobs"},"spec":{"containers":[{"name":"c","image":"busybox:1.36","resources":{"requests":{"cpu":"6"},"limits":{"cpu":"6"}}}]}}'
PLAIN='{"apiVersion":"v1","kind":"Pod","metadata":{"name":"plain","namespace":"batch-jobs"},"spec":{"containers":[{"name":"c","image":"busybox:1.36"}]}}'
echo "$BIG" | kubectl apply --dry-run=server -f - >/dev/null 2>&1 && fail "A 6 CPU Pod is still accepted"
echo "$PLAIN" | kubectl apply --dry-run=server -f - >/dev/null 2>&1 && pass "Admission works" || fail "A Pod without resources is rejected (defaults missing?)"
