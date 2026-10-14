#!/bin/bash
# Setup for Question 12
kubectl create namespace catalog --dry-run=client -o yaml | kubectl apply -f -

kubectl create deployment catalog -n catalog --image=nginx:1.27 --replicas=2 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 12"
exit 0
