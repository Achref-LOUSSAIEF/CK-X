#!/bin/bash
# Setup for Question 11
kubectl create namespace edge --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment edge-cache -n edge --image=nginx:1.27 --replicas=2 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 11"
exit 0
