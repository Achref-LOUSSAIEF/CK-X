#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
PV=$(kubectl get pv -o json | jq -r '[.items[] | select(.spec.storageClassName=="keep-local" and .spec.claimRef.namespace=="retain-lab" and .spec.claimRef.name=="scratch")][0] | .metadata.name // empty')
[ -n "$PV" ] || fail "No PV that belonged to retain-lab/scratch"
kubectl get pv "$PV" -o json | jq -e '(.spec.hostPath.path // .spec.local.path) != null' >/dev/null || fail "Unexpected PV type"
# the file was written by the Pod writer: local-path keeps the directory of a Retain PV
DIR=$(kubectl get pv "$PV" -o json | jq -r '.spec.hostPath.path // .spec.local.path')
NODE=$(kubectl get pv "$PV" -o json | jq -r '.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]')
OUT=$(kubectl run pvcheck-$$ -n retain-lab --image=busybox:1.36 --restart=Never --rm -i --quiet --overrides="{\"spec\":{\"nodeName\":\"$NODE\",\"volumes\":[{\"name\":\"d\",\"hostPath\":{\"path\":\"$DIR\"}}],\"containers\":[{\"name\":\"c\",\"image\":\"busybox:1.36\",\"command\":[\"cat\",\"/d/hello.txt\"],\"volumeMounts\":[{\"name\":\"d\",\"mountPath\":\"/d\"}]}]}}" 2>/dev/null)
echo "$OUT" | grep -q 'hello from writer' && pass "The data written by writer is still on the volume" || fail "hello.txt with 'hello from writer' was not found on the retained volume"
