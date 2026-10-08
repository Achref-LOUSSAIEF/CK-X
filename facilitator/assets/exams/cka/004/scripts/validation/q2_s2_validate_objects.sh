#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get rolebinding dev-user-binding -n staging -o jsonpath='{.roleRef.kind}/{.roleRef.name}|{.subjects[0].kind}/{.subjects[0].name}' 2>/dev/null) || fail "RoleBinding dev-user-binding not found"
[ "$V" = "Role/pod-deploy-lister|User/dev-user" ] && pass "RoleBinding correct" || fail "RoleBinding incorrect: $V"
