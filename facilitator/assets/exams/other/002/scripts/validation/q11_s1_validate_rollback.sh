#!/bin/bash
# Validate script for Question 11, Step 1: Check if release was rolled back

# Check if helm command is available
if ! command -v helm &> /dev/null; then
  echo "❌ Helm command not found in PATH"
  exit 1
fi

# Check if the release exists
release_info=$(helm list -n default -f "web-server" 2>&1)

if [ $? -ne 0 ] || ! echo "$release_info" | grep -q "web-server"; then
  echo "❌ Release 'web-server' not found in namespace 'default'"
  echo "Current releases:"
  helm list -n default
  exit 1
fi

# Check the history to see if a rollback occurred
history=$(helm history web-server -n default 2>&1)

if [ $? -ne 0 ]; then
  echo "❌ Failed to get history for release 'web-server'"
  echo "Error: $history"
  exit 1
fi

# Check if there was a rollback operation in the history
if ! echo "$history" | grep -qi "rollback"; then  # helm prints "Rollback to N"
  echo "❌ No rollback operation found in the release history"
  echo "Release history:"
  echo "$history"
  exit 1
fi

echo "✅ Release 'web-server' has been rolled back"
echo "Release history:"
echo "$history"
exit 0 