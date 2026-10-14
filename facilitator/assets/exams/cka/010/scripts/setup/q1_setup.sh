#!/bin/bash
# Setup for Question 1
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 1"
exit 0
