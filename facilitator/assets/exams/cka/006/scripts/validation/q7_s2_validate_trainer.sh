#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy trainer -n ml -o json 2>/dev/null) || fail "Deployment trainer not found"
echo "$D" | jq -e '[.spec.template.spec.tolerations[]? | select(.key=="dedicated" and ((.effect // "NoSchedule")=="NoSchedule") and (.operator=="Exists" or .value=="ml"))] | length > 0' >/dev/null || fail "trainer has no toleration for dedicated=ml:NoSchedule"
echo "$D" | jq -e '(.spec.template.spec.nodeSelector.dedicated=="ml") or ([.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[]?.matchExpressions[]? | select(.key=="dedicated" and (.values|index("ml")))] | length > 0)' >/dev/null || fail "trainer is not restricted to nodes labeled dedicated=ml"
kubectl rollout status deploy/trainer -n ml --timeout=30s >/dev/null 2>&1
N=$(kubectl get pods -n ml -l app=trainer --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c | awk '{print $2"="$1}')
[ "$N" = "k3d-cluster-agent-1=2" ] && pass "2 Pods on k3d-cluster-agent-1" || fail "Running Pods per node: ${N:-none}"
