#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
U=$(helm repo list -o json 2>/dev/null | jq -r '.[] | select(.name=="argo") | .url')
[ "${U%/}" = "https://argoproj.github.io/argo-helm" ] && pass "Repo argo added" || fail "Helm repo 'argo' not found or wrong URL ('$U')"
