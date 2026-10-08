#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
E=$(kubectl get ns privileged-apps -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null) || fail "Namespace privileged-apps not found"
[ "$E" = "baseline" ] || fail "privileged-apps enforce level is '$E'"
V=$(kubectl get pod privileged-pod -n privileged-apps -o jsonpath='{.spec.containers[0].image}|{.spec.securityContext.runAsUser}{.spec.containers[0].securityContext.runAsUser}|{.status.phase}' 2>/dev/null) || fail "Pod privileged-pod not found"
echo "$V" | grep -Eq '^nginx:1\.25\|00?\|Running$' && pass "privileged-pod runs as root" || fail "privileged-pod incorrect: $V"
