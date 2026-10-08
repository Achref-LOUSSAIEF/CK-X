#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
B='{.spec.versions[?(@.name=="v1")]'
S=$(kubectl get crd backups.ops.example.com -o jsonpath="$B.schema.openAPIV3Schema.properties.spec.properties.schedule.type}")
R=$(kubectl get crd backups.ops.example.com -o jsonpath="$B.schema.openAPIV3Schema.properties.spec.properties.retentionDays.type}")
M=$(kubectl get crd backups.ops.example.com -o jsonpath="$B.schema.openAPIV3Schema.properties.spec.properties.retentionDays.minimum}")
Q=$(kubectl get crd backups.ops.example.com -o jsonpath="$B.schema.openAPIV3Schema.properties.spec.required[*]}")
ST=$(kubectl get crd backups.ops.example.com -o jsonpath="$B.served},$B.storage}")
[ "$ST" = "true,true" ] || fail "v1 must be served and storage"
[ "$S" = "string" ] && [ "$R" = "integer" ] && [ "$M" = "1" ] && echo "$Q" | grep -qw schedule \
  && pass "Schema correct" || fail "Schema incorrect (schedule=$S retentionDays=$R minimum=$M required=$Q)"
