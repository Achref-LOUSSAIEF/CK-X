#!/bin/bash
# Setup for Question 3
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 3"
exit 0
