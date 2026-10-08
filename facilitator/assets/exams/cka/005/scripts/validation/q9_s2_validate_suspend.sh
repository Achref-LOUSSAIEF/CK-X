#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get cronjob backup-job -n backups -o jsonpath='{.spec.suspend}' 2>/dev/null)" = "true" ] && pass "Suspended" || fail "CronJob is not suspended"
