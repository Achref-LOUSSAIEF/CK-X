#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=complete job/log-cleanup-manual -n batch-lab --timeout=20s >/dev/null 2>&1
S=$(kubectl get job log-cleanup-manual -n batch-lab -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "${S:-0}" -ge 1 ] && pass "Job succeeded" || fail "Job has not completed successfully"
