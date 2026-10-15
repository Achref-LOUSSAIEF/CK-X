#!/bin/bash
# Setup for Question 2
mkdir -p /tmp/exam/q2 && chmod 777 /tmp/exam /tmp/exam/q2
kubectl taint node k3d-cluster-agent-0 maintenance=planned:NoSchedule --overwrite

echo "Setup completed for Question 2"
exit 0
