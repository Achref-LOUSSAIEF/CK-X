#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q7/runtimes.txt
[ -f "$F" ] || fail "$F not found"
EXP=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.nodeInfo.containerRuntimeVersion}{"\n"}{end}' | sort)
ACT=$(grep -v '^[[:space:]]*$' "$F" | awk '{print $1, $2}' | sort)
[ "$EXP" = "$ACT" ] && pass "runtimes.txt correct" || fail "runtimes.txt does not match the nodes' runtimes"
