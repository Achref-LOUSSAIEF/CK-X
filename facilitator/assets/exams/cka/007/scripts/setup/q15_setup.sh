#!/bin/bash
# Setup for Question 15
kubectl create namespace payments-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace payments-prod env=prod --overwrite
kubectl create namespace payments-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace payments-dev env=dev --overwrite

echo "Setup completed for Question 15"
exit 0
