#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
T=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{range .spec.taints[?(@.key=="dedicated")]}{.value}:{.effect}{end}' 2>/dev/null)
[ "$T" = "ml:NoSchedule" ] || fail "Taint dedicated=ml:NoSchedule missing (got '$T')"
[ "$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.metadata.labels.dedicated}')" = "ml" ] && pass "Node tainted and labeled" || fail "Label dedicated=ml missing"
