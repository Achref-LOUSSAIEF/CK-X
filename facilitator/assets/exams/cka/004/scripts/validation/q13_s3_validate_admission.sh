#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
mk() { echo "{\"apiVersion\":\"v1\",\"kind\":\"Pod\",\"metadata\":{\"name\":\"$1\",\"namespace\":\"test\"},\"spec\":{\"containers\":[{\"name\":\"c\",\"image\":\"busybox:1.36\",\"resources\":{\"requests\":{\"cpu\":\"$2\",\"memory\":\"$3\"},\"limits\":{\"cpu\":\"$2\",\"memory\":\"$3\"}}}]}}"; }
mk big 2 2Gi | kubectl apply --dry-run=server -f - >/dev/null 2>&1 && fail "2 CPU / 2Gi Pod is still accepted"
mk small 200m 256Mi | kubectl apply --dry-run=server -f - >/dev/null 2>&1 && pass "Admission works" || fail "A 200m/256Mi Pod is rejected (limits too strict)"
