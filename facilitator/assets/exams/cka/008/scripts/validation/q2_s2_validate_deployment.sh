#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy frontend -n frontend -o json 2>/dev/null) || fail "Deployment frontend not found"
REFS=$(echo "$D" | jq -r '[.spec.template.spec.containers[0] | (.envFrom[]?.configMapRef.name), (.env[]?.valueFrom.configMapKeyRef.name)] | map(select(.!=null)) | unique | join(",")')
[ "$REFS" = "frontend-config-v2" ] || fail "frontend must reference only frontend-config-v2 (references: $REFS)"
kubectl rollout status deploy/frontend -n frontend --timeout=40s >/dev/null 2>&1
kubectl logs deploy/frontend -n frontend 2>/dev/null | grep -q "LOG_LEVEL=debug" && pass "frontend logs LOG_LEVEL=debug" || fail "The running frontend Pod does not print LOG_LEVEL=debug"
