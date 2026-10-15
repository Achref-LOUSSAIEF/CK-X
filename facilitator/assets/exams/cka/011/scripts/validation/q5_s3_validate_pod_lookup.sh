#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/nginx-random.pod
[ -f "$F" ] || fail "$F not found"
for IP in $(kubectl get pods -n lookup -l app=nginx-random -o jsonpath='{.items[*].status.podIP}'); do
  D=$(echo "$IP" | tr . -)
  grep -q "$D\.lookup\.pod" "$F" && grep -Fq "$IP" "$F" && pass "Pod lookup saved"
done
fail "$F does not hold a lookup of a nginx-random Pod's DNS name (<ip-with-dashes>.lookup.pod.cluster.local)"
