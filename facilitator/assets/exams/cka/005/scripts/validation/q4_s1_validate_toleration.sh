#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get ds monitoring-agent -n monitoring -o json 2>/dev/null) || fail "DaemonSet monitoring-agent not found"
echo "$D" | jq -e '.spec.template.spec.containers[] | select(.name=="agent") | .image=="busybox:1.36"' >/dev/null || fail "Container agent with busybox:1.36 required"
echo "$D" | jq -e '[.spec.template.spec.tolerations[]? | select(.key=="node-role.kubernetes.io/control-plane" and ((.effect // "NoSchedule")=="NoSchedule"))] | length > 0' >/dev/null \
  && pass "Toleration present" || fail "Toleration for node-role.kubernetes.io/control-plane:NoSchedule missing"
