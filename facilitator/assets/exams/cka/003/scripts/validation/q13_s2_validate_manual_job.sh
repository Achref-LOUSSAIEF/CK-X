#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
J=$(kubectl get job log-cleanup-manual -n batch-lab -o json 2>/dev/null) || fail "Job log-cleanup-manual not found"
echo "$J" | jq -e '(.metadata.ownerReferences // [] | map(select(.kind=="CronJob" and .name=="log-cleanup")) | length > 0)
  or (.metadata.annotations["cronjob.kubernetes.io/instantiate"] == "manual")' >/dev/null \
  && pass "Job created from CronJob" || fail "Job was not created from the CronJob (use kubectl create job --from=cronjob/log-cleanup)"
