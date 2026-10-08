#!/bin/bash
# Setup for Question 8
kubectl create namespace rbac-lab --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 8"
exit 0
