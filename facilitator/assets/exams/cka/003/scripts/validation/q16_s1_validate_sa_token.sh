#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get sa ci-bot -n ci >/dev/null 2>&1 || fail "ServiceAccount ci-bot not found"
V=$(kubectl get secret ci-bot-token -n ci -o jsonpath='{.type}|{.metadata.annotations.kubernetes\.io/service-account\.name}' 2>/dev/null) || fail "Secret ci-bot-token not found"
[ "$V" = "kubernetes.io/service-account-token|ci-bot" ] || fail "Secret ci-bot-token incorrect: $V"
T=$(kubectl get secret ci-bot-token -n ci -o jsonpath='{.data.token}')
[ -n "$T" ] && pass "Token secret populated" || fail "Token not populated in ci-bot-token"
