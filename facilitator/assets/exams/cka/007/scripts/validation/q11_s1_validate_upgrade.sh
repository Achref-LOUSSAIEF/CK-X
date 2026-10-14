#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(helm get values webapp -n helm-apps --revision 2 -o json 2>/dev/null) || fail "Release webapp has no revision 2"
echo "$V" | jq -e '.image.tag=="1.27" and .replicaCount==2 and .service.port==8080' >/dev/null \
  && pass "Revision 2 correct" || fail "Revision 2 must have image.tag=1.27 and keep replicaCount 2 / service.port 8080 (got $(echo "$V" | jq -c .))"
