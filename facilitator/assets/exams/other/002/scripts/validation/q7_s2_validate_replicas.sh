#!/bin/bash
# Question 7, step 2: an upgrade of web-server set the replica count to 3
# (task 11 later rolls back to revision 1, so the revisions are checked, not the live Deployment)
last=$(helm history web-server -n default -o json 2>/dev/null | jq -r '.[-1].revision // empty')
[ -n "$last" ] || { echo "❌ Release 'web-server' not found"; exit 1; }
for r in $(seq 2 "$last"); do
  n=$(helm get values web-server -n default --revision "$r" -o json 2>/dev/null | jq -r '.replicaCount // empty')
  [ "$n" = "3" ] && { echo "✅ Revision $r of web-server sets replicaCount 3"; exit 0; }
done
echo "❌ No upgrade of web-server sets replicaCount to 3"
exit 1
