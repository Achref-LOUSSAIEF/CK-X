#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get ds log-agent -n kube-system -o json 2>/dev/null) || fail "DaemonSet log-agent not found in kube-system"
echo "$D" | jq -e '.spec.template.spec.containers[0].image=="busybox:1.36"' >/dev/null || fail "log-agent must use busybox:1.36"
echo "$D" | jq -e '[.spec.template.spec.tolerations[]? | select((.key=="node-role.kubernetes.io/control-plane" or (.key==null and .operator=="Exists")) and ((.effect // "NoSchedule")=="NoSchedule"))] | length > 0' >/dev/null \
  && pass "Toleration present" || fail "log-agent needs a toleration for node-role.kubernetes.io/control-plane:NoSchedule"
