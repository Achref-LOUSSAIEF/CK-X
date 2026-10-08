#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get ds node-agent -n ds-lab -o json 2>/dev/null) || fail "DaemonSet node-agent not found"
C='.spec.template.spec.containers[] | select(.name=="agent")'
echo "$D" | jq -e '.spec.template.metadata.labels.app == "node-agent"' >/dev/null || fail "Pod label app=node-agent missing"
echo "$D" | jq -e "$C | .image == \"busybox:1.36\"" >/dev/null || fail "Container agent must use busybox:1.36"
echo "$D" | jq -e '.spec.template.spec.volumes[] | select(.name=="varlog") | .hostPath.path == "/var/log"' >/dev/null || fail "hostPath volume varlog -> /var/log missing"
echo "$D" | jq -e "$C | .volumeMounts[] | select(.name==\"varlog\") | .mountPath == \"/host/log\" and .readOnly == true" >/dev/null || fail "varlog must be mounted read-only at /host/log"
echo "$D" | jq -e "$C | .resources.requests.cpu == \"10m\" and .resources.requests.memory == \"16Mi\"" >/dev/null || fail "Requests must be cpu=10m memory=16Mi"
pass "DaemonSet spec correct"
