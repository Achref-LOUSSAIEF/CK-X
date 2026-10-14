#!/bin/bash
# Setup for Question 14
kubectl taint node k3d-cluster-server-0 node-role.kubernetes.io/control-plane=:NoSchedule --overwrite

echo "Setup completed for Question 14"
exit 0
