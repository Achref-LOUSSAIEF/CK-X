#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod app -n dev -o json 2>/dev/null) || fail "Pod app not found"
echo "$P" | jq -e '[.spec.containers[0].env[]? | select(.name=="APP_MODE" and .valueFrom.configMapKeyRef.name=="app-config" and .valueFrom.configMapKeyRef.key=="APP_MODE")] | length == 1' >/dev/null || fail "APP_MODE must come from configMapKeyRef app-config/APP_MODE"
echo "$P" | jq -e '[.spec.containers[0].env[]? | select(.name=="DB_PASS" and .valueFrom.secretKeyRef.name=="app-secret" and .valueFrom.secretKeyRef.key=="DB_PASS")] | length == 1' >/dev/null || fail "DB_PASS must come from secretKeyRef app-secret/DB_PASS"
kubectl wait --for=condition=Ready pod/app -n dev --timeout=30s >/dev/null 2>&1 && pass "app running" || fail "app is not Ready"
