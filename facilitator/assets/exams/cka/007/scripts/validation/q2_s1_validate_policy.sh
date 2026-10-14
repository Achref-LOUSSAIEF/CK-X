#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get netpol default-deny-egress -n sales >/dev/null 2>&1 || fail "default-deny-egress was deleted"
P=$(kubectl get netpol allow-dns -n sales -o json 2>/dev/null) || fail "NetworkPolicy allow-dns not found"
echo "$P" | jq -e '(.spec.podSelector | (.matchLabels // {} | length == 0) and (.matchExpressions // [] | length == 0)) and (.spec.policyTypes | index("Egress"))' >/dev/null || fail "allow-dns must select all Pods and have policyType Egress"
echo "$P" | jq -e '[.spec.egress[]?.to[]? | select(.namespaceSelector.matchLabels["kubernetes.io/metadata.name"]=="kube-system" and .podSelector.matchLabels["k8s-app"]=="kube-dns")] | length > 0' >/dev/null || fail "allow-dns must target k8s-app=kube-dns Pods in kube-system (both selectors in one peer)"
echo "$P" | jq -e '[.spec.egress[]?.to[]? | select(.namespaceSelector == null or .podSelector == null or .ipBlock != null)] | length == 0' >/dev/null || fail "allow-dns allows more than the DNS Pods"
PORTS=$(echo "$P" | jq -r '[.spec.egress[]?.ports[]? | "\(.protocol // "TCP")/\(.port)"] | sort | unique | join(",")')
[ "$PORTS" = "TCP/53,UDP/53" ] && pass "allow-dns correct" || fail "allow-dns ports must be exactly UDP/53 and TCP/53 (got $PORTS)"
