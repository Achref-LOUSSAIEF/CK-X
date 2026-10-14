#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
try() { kubectl create deployment vap-test -n "$1" --image=nginx:1.27 --replicas="$2" --dry-run=server -o name >/dev/null 2>&1; }
for _ in 1 2 3 4 5; do try payments-prod 1 || break; sleep 2; done
try payments-prod 1 && fail "A 1-replica Deployment is still accepted in payments-prod"
try payments-prod 2 || fail "A 2-replica Deployment is rejected in payments-prod"
try payments-dev 1 || fail "The policy also blocks payments-dev (it must only apply to env=prod)"
pass "Policy enforced only in prod"
