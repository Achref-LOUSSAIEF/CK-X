#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/crds.txt
[ -f "$F" ] || fail "$F not found"
EXP=$(kubectl get crd -o name | sed 's#.*/##' | grep 'cert-manager.io$' | sort)
ACT=$(awk '{print $1}' "$F" | sed 's#^customresourcedefinition.apiextensions.k8s.io/##' | grep -v '^NAME$' | grep -v '^[[:space:]]*$' | sort -u)
[ "$EXP" = "$ACT" ] && pass "All cert-manager CRDs listed" || fail "crds.txt does not match the cert-manager CRDs in the cluster"
