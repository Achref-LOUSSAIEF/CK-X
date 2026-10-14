#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q14/images.txt
[ -f "$F" ] || fail "$F not found"
EXP=$(kubectl get pods -n inventory -o jsonpath='{range .items[*]}{range .spec.initContainers[*]}{.image}{"\n"}{end}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | grep -v '^$' | sort -u)
[ -n "$EXP" ] || fail "No Pods found in inventory"
ACT=$(grep -v '^[[:space:]]*$' "$F" | sed 's/[[:space:]]*$//')
[ "$EXP" = "$ACT" ] && pass "images.txt correct" || fail "images.txt must contain exactly the distinct images, sorted, one per line"
