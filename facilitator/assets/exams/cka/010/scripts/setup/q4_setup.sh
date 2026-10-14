#!/bin/bash
# Setup for Question 4
kubectl create namespace media --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 4"
exit 0
