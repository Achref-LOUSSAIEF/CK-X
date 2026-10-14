#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
E=$(kubectl get endpointslices -n integrations -l kubernetes.io/service-name=legacy-db -o json 2>/dev/null)
echo "$E" | jq -e '[.items[] | select([.ports[]?.port] | index(5432)) | .endpoints[]?.addresses[]? | select(.=="10.0.0.50")] | length > 0' >/dev/null \
  && pass "Endpoint 10.0.0.50:5432 set" || fail "No endpoint 10.0.0.50:5432 for legacy-db (create an EndpointSlice labeled kubernetes.io/service-name=legacy-db, or an Endpoints object)"
