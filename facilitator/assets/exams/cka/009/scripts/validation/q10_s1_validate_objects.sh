#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get sa deploy-bot -n apps >/dev/null 2>&1 || fail "ServiceAccount deploy-bot not found"
kubectl get role deploy-manager -n apps >/dev/null 2>&1 || fail "Role deploy-manager not found"
B=$(kubectl get rolebinding deploy-bot-binding -n apps -o jsonpath='{.roleRef.kind}/{.roleRef.name}|{.subjects[0].kind}/{.subjects[0].name}' 2>/dev/null) || fail "RoleBinding deploy-bot-binding not found"
[ "$B" = "Role/deploy-manager|ServiceAccount/deploy-bot" ] && pass "Linked" || fail "RoleBinding incorrect: $B"
