#!/bin/bash
# Setup for Question 13
kubectl create namespace restricted-apps --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace restricted-apps pod-security.kubernetes.io/enforce=restricted --overwrite

echo "Setup completed for Question 13"
exit 0
