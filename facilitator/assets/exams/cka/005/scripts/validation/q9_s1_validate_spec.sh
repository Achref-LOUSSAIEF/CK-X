#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get cronjob backup-job -n backups -o json 2>/dev/null) || fail "CronJob backup-job not found"
echo "$C" | jq -e '.spec.schedule=="0 2 * * *"' >/dev/null || fail "Schedule must be 0 2 * * *"
echo "$C" | jq -e '.spec.successfulJobsHistoryLimit==3' >/dev/null || fail "successfulJobsHistoryLimit must be 3"
echo "$C" | jq -e '.spec.jobTemplate.spec.template.spec.containers[] | select(.name=="backup") | .image=="busybox:1.36"' >/dev/null \
  && pass "CronJob spec correct" || fail "Container backup with busybox:1.36 missing"
