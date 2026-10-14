#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pdb ledger-pdb -n ledger -o jsonpath='{.spec.maxUnavailable}|{.spec.minAvailable}|{.spec.selector.matchLabels.app}' 2>/dev/null) || fail "PDB ledger-pdb was deleted"
[ "$V" = "1||ledger" ] && pass "PDB updated" || fail "ledger-pdb incorrect (maxUnavailable|minAvailable|selector): $V"
