#!/bin/bash
# Setup for Question 2
mkdir -p /tmp/exam/q2 && chmod 777 /tmp/exam /tmp/exam/q2
helm repo remove argo >/dev/null 2>&1 || true

echo "Setup completed for Question 2"
exit 0
