#!/bin/bash
# Setup for Question 9
kubectl create namespace config --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap app-settings -n config --from-literal=mode=standard --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap db-settings -n config --from-literal=pool=10 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 9"
exit 0
