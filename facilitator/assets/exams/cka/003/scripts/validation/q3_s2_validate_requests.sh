#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
CPU=$(kubectl get deploy batch-processor -n trbl-sched -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
MEM=$(kubectl get deploy batch-processor -n trbl-sched -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
[ "$CPU" = "100m" ] || [ "$CPU" = "0.1" ] || fail "CPU request is '$CPU', expected 100m"
[ "$MEM" = "64Mi" ] && pass "requests cpu=$CPU memory=$MEM" || fail "Memory request is '$MEM', expected 64Mi"
