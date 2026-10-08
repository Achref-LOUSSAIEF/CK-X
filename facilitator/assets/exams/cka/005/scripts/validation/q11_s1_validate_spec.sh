#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pdb app-pdb -n pdb-lab -o jsonpath='{.spec.maxUnavailable}|{.spec.minAvailable}|{.spec.selector.matchLabels.app}' 2>/dev/null) || fail "PDB app-pdb not found"
[ "$V" = "2||web-app" ] && pass "PDB spec correct" || fail "PDB incorrect (maxUnavailable|minAvailable|selector): $V"
