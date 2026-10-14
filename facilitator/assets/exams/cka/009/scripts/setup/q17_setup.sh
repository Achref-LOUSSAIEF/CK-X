#!/bin/bash
# Setup for Question 17
kubectl create namespace team-a --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 17"
exit 0
