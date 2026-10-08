#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy spread-web -n spread-lab -o json 2>/dev/null) || fail "Deployment spread-web not found"
echo "$D" | jq -e '.spec.replicas==4 and .spec.template.metadata.labels.app=="spread-web"' >/dev/null || fail "Need 4 replicas with label app=spread-web"
echo "$D" | jq -e '[.spec.template.spec.topologySpreadConstraints[]? | select(.maxSkew==1 and .topologyKey=="topology.ckx.io/zone" and .whenUnsatisfiable=="DoNotSchedule" and .labelSelector.matchLabels.app=="spread-web")] | length > 0' >/dev/null \
  && pass "Constraint correct" || fail "topologySpreadConstraints incorrect"
