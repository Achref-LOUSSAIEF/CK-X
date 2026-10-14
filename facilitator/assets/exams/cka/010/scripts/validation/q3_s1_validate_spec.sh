#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get cronjob backup -n dev -o json 2>/dev/null) || fail "CronJob backup not found"
echo "$C" | jq -e '.spec.schedule=="*/5 * * * *" and .spec.concurrencyPolicy=="Forbid" and .spec.successfulJobsHistoryLimit==2 and .spec.jobTemplate.spec.template.spec.containers[0].image=="busybox:1.36"' >/dev/null \
  && pass "CronJob correct" || fail "backup needs schedule */5 * * * *, concurrencyPolicy Forbid, successfulJobsHistoryLimit 2, image busybox:1.36"
