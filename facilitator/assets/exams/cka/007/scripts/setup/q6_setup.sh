#!/bin/bash
# Setup for Question 6
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic app-secrets -n vault --from-literal=api-token=tok-7f3a9c --from-literal=db-password=S3cr3t --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 6"
exit 0
