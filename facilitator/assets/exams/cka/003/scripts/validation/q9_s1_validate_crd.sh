#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
J='{.spec.group}|{.spec.names.kind}|{.spec.names.plural}|{.spec.names.singular}|{.spec.names.shortNames[*]}|{.spec.scope}'
V=$(kubectl get crd backups.ops.example.com -o jsonpath="$J" 2>/dev/null) || fail "CRD backups.ops.example.com not found"
[ "$V" = "ops.example.com|Backup|backups|backup|bk|Namespaced" ] && pass "CRD names/scope correct" || fail "CRD definition incorrect: $V"
