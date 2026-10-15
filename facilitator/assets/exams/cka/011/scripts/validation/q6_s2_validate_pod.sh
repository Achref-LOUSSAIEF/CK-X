#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod ledger -n init-lab -o json 2>/dev/null) || fail "Pod ledger not found"
echo "$P" | jq -e '(.spec.initContainers | length) > 0' >/dev/null || fail "Pod ledger has no init container"
kubectl wait --for=condition=Ready pod/ledger -n init-lab --timeout=30s >/dev/null 2>&1 || fail "Pod ledger is not Ready"
kubectl exec -n init-lab ledger -c app -- test -f /workdir/ready.flag || fail "/workdir/ready.flag does not exist in the app container"
echo "$P" | jq -e '.status.containerStatuses[] | select(.name=="app") | .restartCount == 0' >/dev/null   && pass "ledger runs after its init container" || fail "The app container restarted: it started without ready.flag"
