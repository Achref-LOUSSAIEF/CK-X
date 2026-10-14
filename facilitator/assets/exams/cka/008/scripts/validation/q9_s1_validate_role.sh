#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get role app-settings-editor -n config -o json 2>/dev/null) || fail "Role app-settings-editor not found"
echo "$R" | jq -e '[.rules[] | select(.resources|index("configmaps"))] | length > 0 and all(.resourceNames == ["app-settings"])' >/dev/null || fail "Every configmaps rule must be limited with resourceNames: [app-settings]"
B=$(kubectl get rolebinding jane-app-settings -n config -o jsonpath='{.roleRef.kind}/{.roleRef.name}|{.subjects[0].kind}/{.subjects[0].name}' 2>/dev/null) || fail "RoleBinding jane-app-settings not found"
[ "$B" = "Role/app-settings-editor|User/jane" ] && pass "Role and binding correct" || fail "RoleBinding incorrect: $B"
