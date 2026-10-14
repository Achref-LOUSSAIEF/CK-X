#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get ns argocd >/dev/null 2>&1 || fail "Namespace argocd not found"
[ -z "$(helm list -A -q 2>/dev/null | grep -x argocd)" ] || fail "A Helm release argocd is installed (it must only be rendered)"
kubectl get deploy argocd-server -n argocd >/dev/null 2>&1 && fail "argocd-server is deployed (it must only be rendered)"
pass "Rendered only, not installed"
