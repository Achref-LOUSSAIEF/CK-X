#!/bin/bash
# Setup for Question 11
kubectl create namespace limits-lab --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 11"
exit 0
