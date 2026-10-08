#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q16/ci-bot.kubeconfig
[ -f "$F" ] || fail "$F not found"
K="kubectl --kubeconfig $F"
[ "$($K config current-context 2>/dev/null)" = "ci-context" ] || fail "current-context is not ci-context"
V=$($K config view --minify -o jsonpath='{.contexts[0].context.cluster}|{.contexts[0].context.user}|{.contexts[0].context.namespace}' 2>/dev/null)
[ "$V" = "ckx|ci-bot|ci" ] || fail "ci-context must use cluster ckx, user ci-bot, namespace ci (got $V)"
$K get pods >/dev/null 2>&1 || fail "'kubectl get pods' fails with this kubeconfig"
[ "$($K auth can-i list pods -n default 2>/dev/null)" = "no" ] || fail "ci-bot can list pods outside ci"
[ "$($K auth can-i create deployments 2>/dev/null)" = "no" ] || fail "ci-bot is not read-only"
pass "kubeconfig works and access is read-only"
