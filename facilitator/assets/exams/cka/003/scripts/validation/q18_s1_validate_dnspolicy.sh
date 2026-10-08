#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get deploy resolver -n trbl-dns -o jsonpath='{.spec.template.spec.dnsPolicy}' 2>/dev/null) || fail "Deployment resolver not found"
NSV=$(kubectl get deploy resolver -n trbl-dns -o jsonpath='{.spec.template.spec.dnsConfig.nameservers[*]}')
case "$P" in ClusterFirst|ClusterFirstWithHostNet) ;; *) fail "dnsPolicy is '$P'";; esac
[ -z "$NSV" ] && pass "dnsPolicy $P" || fail "Hard-coded nameservers still present: $NSV"
