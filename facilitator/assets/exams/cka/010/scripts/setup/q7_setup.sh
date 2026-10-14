#!/bin/bash
# Setup for Question 7
kubectl label node k3d-cluster-agent-0 zone=east --overwrite
kubectl label node k3d-cluster-server-0 zone=west --overwrite
kubectl label node k3d-cluster-agent-1 zone=west --overwrite

echo "Setup completed for Question 7"
exit 0
