#!/bin/bash
# Setup for Question 2
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 2"
exit 0
