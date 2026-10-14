#!/bin/bash
# Setup for Question 18
kubectl create namespace secure-apps --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 18"
exit 0
