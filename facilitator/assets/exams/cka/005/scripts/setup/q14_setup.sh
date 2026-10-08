#!/bin/bash
# Setup for Question 14
kubectl create namespace dyn-storage --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 14"
exit 0
