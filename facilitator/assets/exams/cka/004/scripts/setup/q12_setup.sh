#!/bin/bash
# Setup for Question 12
kubectl create namespace db-cluster --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 12"
exit 0
