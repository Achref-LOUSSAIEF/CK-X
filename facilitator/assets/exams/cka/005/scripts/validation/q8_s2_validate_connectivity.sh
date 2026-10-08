#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
NODEIP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
kubectl exec probe -n legacy -- wget -qO- -T 5 "http://$NODEIP:30808" 2>/dev/null | grep -q legacy-app \
  && pass "Reachable via $NODEIP:30808" || fail "Not reachable via $NODEIP:30808"
