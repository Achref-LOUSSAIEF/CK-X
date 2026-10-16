#!/bin/bash
# Question 8, step 2: cache-db runs the redis chart with those values
chart=$(helm list -n default -f '^cache-db$' -o json 2>/dev/null | jq -r '.[0].chart // empty')
[ -n "$chart" ] || { echo "❌ Release 'cache-db' not found in namespace 'default'"; exit 1; }
case "$chart" in redis-*) ;; *) echo "❌ cache-db uses '$chart', not the redis chart"; exit 1 ;; esac
J=$(helm get values cache-db -n default -o json 2>/dev/null)
echo "$J" | jq -e '(.auth.password // .password) == "password123"' >/dev/null || { echo "❌ Password is not password123"; exit 1; }
echo "$J" | jq -e '(.master.persistence.enabled // .persistence.enabled) == true' >/dev/null || { echo "❌ Persistence is not enabled"; exit 1; }
echo "$J" | jq -e '(.master.resources.limits // .resources.limits) | .memory == "256Mi" and (.cpu == "100m" or .cpu == 0.1)' >/dev/null \
  && { echo "✅ cache-db installed with the values"; exit 0; } || { echo "❌ Resource limits not applied"; exit 1; }
