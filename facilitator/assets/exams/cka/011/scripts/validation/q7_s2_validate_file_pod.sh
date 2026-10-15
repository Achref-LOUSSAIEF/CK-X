#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod secret-file -n secret-lab -o json 2>/dev/null) || fail "Pod secret-file not found"
echo "$P" | jq -e '[.spec.volumes[]? | select(.secret.secretName=="app-secret") | .name] as $v | [.spec.containers[].volumeMounts[]? | select(.mountPath=="/secrets" and (.name as $n | $v | index($n)))] | length > 0' >/dev/null || fail "secret-file does not mount the Secret app-secret at /secrets"
kubectl wait --for=condition=Ready pod/secret-file -n secret-lab --timeout=30s >/dev/null 2>&1 || fail "Pod secret-file is not Ready"
[ "$(kubectl exec -n secret-lab secret-file -- cat /secrets/password 2>/dev/null)" = "n0t-s0-s3cret" ]   && pass "/secrets/password holds the password" || fail "/secrets/password does not hold the password"
