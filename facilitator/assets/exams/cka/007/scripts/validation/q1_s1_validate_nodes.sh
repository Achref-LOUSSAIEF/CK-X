#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q1/nodes.txt
[ -f "$F" ] || fail "$F not found"
EXP=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' | sed 's/[[:space:]]*$//' | sort)
ACT=$(grep -v '^[[:space:]]*$' "$F" | sed 's/[[:space:]]\+/ /g; s/ $//')
[ "$EXP" = "$ACT" ] && pass "nodes.txt correct" || fail "nodes.txt does not match '<name> <InternalIP>' sorted by name"
