#!/bin/bash
# Setup for Question 12
kubectl create namespace localdisk --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 12"
exit 0
