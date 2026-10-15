#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q12/pv-by-size.txt
[ -f "$F" ] || fail "$F not found"
GOT=$(awk 'NF && $1 != "NAME" {print $1}' "$F" | tr '\n' ' ')
[ "$GOT" = "pv-scratch pv-media pv-cache pv-logs pv-backup " ] && pass "PVs listed by capacity" || fail "$F does not list only the 5 storage-audit PVs from smallest to largest (found: $GOT)"
