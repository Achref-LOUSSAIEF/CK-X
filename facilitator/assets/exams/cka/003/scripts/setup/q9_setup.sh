#!/bin/bash
# Setup for Question 9
kubectl create namespace crd-lab --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 9"
exit 0
