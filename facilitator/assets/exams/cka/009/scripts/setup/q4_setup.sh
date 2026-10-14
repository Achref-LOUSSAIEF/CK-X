#!/bin/bash
# Setup for Question 4
kubectl label node k3d-cluster-agent-0 disk=ssd --overwrite

echo "Setup completed for Question 4"
exit 0
