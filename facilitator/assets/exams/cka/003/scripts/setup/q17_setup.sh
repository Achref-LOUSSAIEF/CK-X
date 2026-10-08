#!/bin/bash
# Setup for Question 17
kubectl create namespace spread-lab --dry-run=client -o yaml | kubectl apply -f -

kubectl label node k3d-cluster-server-0 topology.ckx.io/zone=zone-a --overwrite
kubectl label node k3d-cluster-agent-1 topology.ckx.io/zone=zone-b --overwrite

echo "Setup completed for Question 17"
exit 0
