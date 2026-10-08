#!/bin/bash
# Setup for Question 7
kubectl create namespace priority-lab --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 7"
exit 0
