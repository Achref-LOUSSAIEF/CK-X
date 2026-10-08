#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get sa deployer -n audit-lab >/dev/null 2>&1 || fail "ServiceAccount deployer was deleted"
[ "$(kubectl auth can-i get configmaps -n default --as system:serviceaccount:audit-lab:deployer 2>/dev/null)" = "no" ] || fail "deployer can still read ConfigMaps in default"
[ "$(kubectl auth can-i get configmaps -n default --as system:serviceaccount:audit-lab:ci 2>/dev/null)" = "yes" ] || fail "ci lost its access (should be unchanged)"
kubectl get clusterrole configmap-reader >/dev/null 2>&1 || fail "ClusterRole configmap-reader was deleted (it is still used by auditor)"
[ "$(kubectl auth can-i get configmaps -n kube-public --as system:serviceaccount:audit-lab:auditor 2>/dev/null)" = "yes" ] && pass "Access revoked only for deployer" || fail "auditor's access was changed"
