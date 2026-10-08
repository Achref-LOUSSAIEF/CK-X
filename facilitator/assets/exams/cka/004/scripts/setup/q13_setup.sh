#!/bin/bash
# Setup for Question 13
kubectl create namespace test --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 13"
exit 0
