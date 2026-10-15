#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q6/ledger.yaml
[ -f "$F" ] || fail "$F not found"
yq -e '.spec.initContainers | length > 0' "$F" >/dev/null 2>&1 || fail "The spec file has no init container"
yq -e '[.spec.initContainers[].volumeMounts[]? | select(.mountPath=="/workdir" and .name=="workdir")] | length > 0' "$F" >/dev/null 2>&1   && pass "Spec file updated" || fail "The init container in the spec file does not mount the workdir volume at /workdir"
