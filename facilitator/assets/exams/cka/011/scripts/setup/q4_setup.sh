#!/bin/bash
# Setup for Question 4
kubectl create namespace dns-custom --dry-run=client -o yaml | kubectl apply -f -
kubectl run dns-client -n dns-custom --image=busybox:1.36 --restart=Never --dry-run=client -o yaml -- sleep 36000 | kubectl apply -f -

echo "Setup completed for Question 4"
exit 0
