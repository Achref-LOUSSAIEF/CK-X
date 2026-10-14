#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
H=$(helm history webapp -n helm-apps -o json 2>/dev/null) || fail "Release webapp not found in helm-apps"
echo "$H" | jq -e '(length >= 3) and (.[-1].status=="deployed") and (.[-1].description | test("Rollback to 1"))' >/dev/null || fail "The current revision is not a rollback to revision 1"
[ "$(kubectl get deploy webapp -n helm-apps -o jsonpath='{.spec.template.spec.containers[0].image}|{.spec.replicas}' 2>/dev/null)" = "nginx:1.25|2" ] || fail "Deployment webapp is not back to nginx:1.25 with 2 replicas"
[ "$(kubectl get svc webapp -n helm-apps -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)" = "8080" ] && pass "Rolled back to revision 1" || fail "Service webapp must use port 8080"
