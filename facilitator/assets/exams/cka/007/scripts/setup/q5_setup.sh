#!/bin/bash
# Setup for Question 5
kubectl create namespace integrations --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 5"
exit 0
