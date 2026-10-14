#!/bin/bash
# Setup for Question 6
kubectl create namespace crawler --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 6"
exit 0
