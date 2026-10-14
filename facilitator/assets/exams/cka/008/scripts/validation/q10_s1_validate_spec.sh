#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod hardened -n secure -o json 2>/dev/null) || fail "Pod hardened not found"
echo "$P" | jq -e '(.spec.securityContext.fsGroup==2000) and ((.spec.containers[0].securityContext.runAsUser // .spec.securityContext.runAsUser)==1000) and ((.spec.containers[0].securityContext.runAsGroup // .spec.securityContext.runAsGroup)==3000)' >/dev/null || fail "runAsUser 1000, runAsGroup 3000 and Pod-level fsGroup 2000 are required"
echo "$P" | jq -e '.spec.containers[0].securityContext | .readOnlyRootFilesystem==true and .allowPrivilegeEscalation==false and (.capabilities.drop // [] | index("ALL"))' >/dev/null || fail "Container needs readOnlyRootFilesystem true, allowPrivilegeEscalation false and capabilities drop [ALL]"
VN=$(echo "$P" | jq -r '.spec.containers[0].volumeMounts[]? | select(.mountPath=="/work") | .name')
[ -n "$VN" ] || fail "No volume mounted at /work"
echo "$P" | jq -e --arg v "$VN" '.spec.volumes[] | select(.name==$v) | has("emptyDir")' >/dev/null && pass "securityContext correct" || fail "/work must be an emptyDir volume"
