#!/bin/bash
# Question 8, step 1: the values file sets password, persistence and limits
F=/tmp/exam/q8/redis-values.yaml
[ -s "$F" ] || { echo "❌ $F not found or empty"; exit 1; }
J=$(yq -o=json '.' "$F" 2>/dev/null) || { echo "❌ $F is not valid YAML"; exit 1; }
echo "$J" | jq -e '(.auth.password // .password) == "password123"' >/dev/null || { echo "❌ Password is not password123 (auth.password)"; exit 1; }
echo "$J" | jq -e '(.master.persistence.enabled // .persistence.enabled) == true' >/dev/null || { echo "❌ Persistence is not enabled (master.persistence.enabled)"; exit 1; }
echo "$J" | jq -e '(.master.resources.limits // .resources.limits) | .memory == "256Mi" and (.cpu == "100m" or .cpu == 0.1)' >/dev/null \
  && { echo "✅ Values file correct"; exit 0; } || { echo "❌ Limits must be memory 256Mi and cpu 100m (master.resources.limits)"; exit 1; }
