#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
L=$(kubectl get ns secure-apps -o json 2>/dev/null | jq -r '.metadata.labels | [.["pod-security.kubernetes.io/enforce"], .["pod-security.kubernetes.io/warn"], (.["pod-security.kubernetes.io/enforce-version"] // "latest")] | join("|")')
[ "$L" = "restricted|restricted|latest" ] && pass "PSA labels set" || fail "secure-apps labels (enforce|warn|version): $L"
kubectl run ckx-bad -n secure-apps --image=busybox:1.36 --dry-run=server -- sleep 1 >/dev/null 2>&1 && fail "A non-compliant Pod is still accepted"
true
