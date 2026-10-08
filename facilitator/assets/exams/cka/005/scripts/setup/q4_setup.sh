#!/bin/bash
# Setup for Question 4
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

kubectl taint node k3d-cluster-server-0 node-role.kubernetes.io/control-plane=:NoSchedule --overwrite

echo "Setup completed for Question 4"
exit 0
