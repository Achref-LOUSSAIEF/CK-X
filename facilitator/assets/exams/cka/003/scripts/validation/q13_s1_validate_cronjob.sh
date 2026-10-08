#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get cronjob log-cleanup -n batch-lab -o json 2>/dev/null) || fail "CronJob log-cleanup not found"
echo "$C" | jq -e '.spec.schedule | test("^\\*/15 \\* \\* \\* \\*$|^0,15,30,45 \\* \\* \\* \\*$")' >/dev/null || fail "Schedule must run every 15 minutes"
echo "$C" | jq -e '.spec.concurrencyPolicy=="Forbid" and .spec.successfulJobsHistoryLimit==2 and .spec.failedJobsHistoryLimit==1' >/dev/null || fail "concurrencyPolicy/history limits incorrect"
echo "$C" | jq -e '.spec.jobTemplate.spec.backoffLimit==2 and .spec.jobTemplate.spec.activeDeadlineSeconds==60' >/dev/null || fail "backoffLimit/activeDeadlineSeconds incorrect"
echo "$C" | jq -e '.spec.jobTemplate.spec.template.spec.restartPolicy=="Never"' >/dev/null || fail "restartPolicy must be Never"
echo "$C" | jq -e '.spec.jobTemplate.spec.template.spec.containers[] | select(.name=="cleanup") | .image=="busybox:1.36"' >/dev/null || fail "Container cleanup with busybox:1.36 missing"
pass "CronJob correct"
