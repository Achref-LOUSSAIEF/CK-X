#!/bin/bash
# Question 4, step 1: the release web-server runs the Bitnami nginx chart
chart=$(helm list -n default -f '^web-server$' -o json 2>/dev/null | jq -r '.[0].chart // empty')
[ -n "$chart" ] || { echo "❌ Release 'web-server' not found in namespace 'default'"; exit 1; }
case "$chart" in
  nginx-*) echo "✅ Release 'web-server' uses the chart $chart"; exit 0 ;;
  *) echo "❌ Release 'web-server' uses the chart '$chart', not nginx"; exit 1 ;;
esac
