#!/bin/bash
# Setup for Question 15
kubectl create namespace batch-jobs --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 15"
exit 0
