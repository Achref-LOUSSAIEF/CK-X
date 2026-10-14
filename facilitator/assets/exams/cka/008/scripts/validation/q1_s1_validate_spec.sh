#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get sts web -n stateful -o json 2>/dev/null) || fail "StatefulSet web not found"
echo "$S" | jq -e '.spec.replicas==3 and .spec.template.spec.containers[0].image=="nginx:1.27" and (.spec.updateStrategy.type // "RollingUpdate")=="RollingUpdate" and .spec.updateStrategy.rollingUpdate.partition==2' >/dev/null \
  && pass "Partitioned update configured" || fail "web must keep 3 replicas, use nginx:1.27 and rollingUpdate.partition 2 ($(echo "$S" | jq -c '{image:.spec.template.spec.containers[0].image,strategy:.spec.updateStrategy}'))"
