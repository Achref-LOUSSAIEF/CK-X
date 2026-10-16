#!/bin/bash
# Validate script for Question 10, Step 2: Check if local repo is created and configured

# Check if helm command is available
if ! command -v helm &> /dev/null; then
  echo "❌ Helm command not found in PATH"
  exit 1
fi

# Check if the charts directory exists
if [ ! -d /tmp/exam/q10/charts ]; then
  echo "❌ Charts directory does not exist at /tmp/exam/q10/charts"
  exit 1
fi

# Check if the packaged chart exists in the directory
if ! ls /tmp/exam/q10/charts/webapp-*.tgz &>/dev/null; then
  echo "❌ Packaged chart not found in the charts directory"
  echo "Directory contents:"
  ls -la /tmp/exam/q10/charts
  exit 1
fi

# Check if the index.yaml file was created
if [ ! -f /tmp/exam/q10/charts/index.yaml ]; then
  echo "❌ Index file does not exist at /tmp/exam/q10/charts/index.yaml"
  exit 1
fi

# Check if the index file contains the webapp chart
if ! grep -q "webapp" /tmp/exam/q10/charts/index.yaml; then
  echo "❌ Index file does not contain the webapp chart"
  echo "Index file content:"
  cat /tmp/exam/q10/charts/index.yaml
  exit 1
fi

# Check if the local repository is added to Helm
repo_list=$(helm repo list 2>&1)
if ! echo "$repo_list" | grep -q "localrepo"; then
  echo "❌ Local repository 'localrepo' not found in Helm repositories"
  echo "Current repositories:"
  echo "$repo_list"
  exit 1
fi

# the repository must serve the webapp chart
if ! helm search repo localrepo/webapp 2>/dev/null | grep -q "localrepo/webapp"; then
  echo "❌ 'helm search repo localrepo/webapp' finds nothing (run helm repo update?)"
  exit 1
fi

echo "✅ Local chart repository is created and configured correctly"
echo "Repository content:"
ls -la /tmp/exam/q10/charts
echo "Repository list:"
echo "$repo_list"
exit 0 