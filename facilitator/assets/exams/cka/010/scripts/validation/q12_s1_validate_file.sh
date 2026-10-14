#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q12/node-ip.txt
[ -f "$F" ] || fail "$F not found"
IP=$(kubectl get node k3d-cluster-agent-0 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
[ -n "$IP" ] || fail "k3d-cluster-agent-0 has no InternalIP"
[ "$(tr -d '[:space:]' < "$F")" = "$IP" ] && pass "$IP" || fail "$F does not contain the InternalIP of k3d-cluster-agent-0"
