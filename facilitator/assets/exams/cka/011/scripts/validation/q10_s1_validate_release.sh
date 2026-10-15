#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
helm status edge -n edge >/dev/null 2>&1 || fail "Helm release edge not found in the namespace edge"
helm list -n edge -o json | jq -e '.[] | select(.name=="edge") | .status=="deployed" and (.chart | startswith("edge-proxy-"))' >/dev/null   && pass "Release edge of the chart edge-proxy is deployed" || fail "Release edge is not a deployed edge-proxy release"
