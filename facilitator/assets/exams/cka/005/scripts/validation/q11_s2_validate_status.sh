#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get deploy web-app -n pdb-lab -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 10 ] || fail "web-app has ${R:-0}/10 Ready replicas"
A=$(kubectl get pdb app-pdb -n pdb-lab -o jsonpath='{.status.disruptionsAllowed}')
[ "$A" = "2" ] && pass "2 disruptions allowed" || fail "disruptionsAllowed is ${A:-unknown}"
