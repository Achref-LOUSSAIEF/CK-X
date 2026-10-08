#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
K=$(kubectl get clusterrolebinding jane-node-viewer -o jsonpath='{.roleRef.name}/{.subjects[?(@.name=="jane")].kind}' 2>/dev/null)
[ "$K" = "node-viewer/User" ] || fail "ClusterRoleBinding jane-node-viewer incorrect ($K)"
K=$(kubectl get rolebinding developers-deploy-manager -n rbac-lab -o jsonpath='{.roleRef.kind}/{.roleRef.name}/{.subjects[?(@.name=="developers")].kind}' 2>/dev/null)
[ "$K" = "Role/deploy-manager/Group" ] && pass "Bindings correct" || fail "RoleBinding developers-deploy-manager incorrect ($K)"
