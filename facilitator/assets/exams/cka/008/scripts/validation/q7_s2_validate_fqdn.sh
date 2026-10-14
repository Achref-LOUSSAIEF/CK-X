#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q7/fqdn.txt
[ -f "$F" ] || fail "$F not found"
V=$(tr -d '[:space:]' < "$F"); V=${V%.}
[ "$V" = "cache-peers.cache.svc.cluster.local" ] && pass "FQDN correct" || fail "$F does not contain the FQDN of cache-peers"
