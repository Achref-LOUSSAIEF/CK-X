#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get rolebinding ci-bot-view -n ci -o jsonpath='{.roleRef.kind}/{.roleRef.name}|{.subjects[0].kind}/{.subjects[0].name}/{.subjects[0].namespace}' 2>/dev/null) || fail "RoleBinding ci-bot-view not found"
[ "$V" = "ClusterRole/view|ServiceAccount/ci-bot/ci" ] && pass "RoleBinding correct" || fail "RoleBinding incorrect: $V"
