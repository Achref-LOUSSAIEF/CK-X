#!/bin/bash
# Setup for Question 10
kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 10"
exit 0
