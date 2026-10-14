#!/bin/bash
# Setup for Question 5
mkdir -p /tmp/exam/q5 && chmod 777 /tmp/exam /tmp/exam/q5

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.crds.yaml
kubectl wait --for=condition=Established crd/certificates.cert-manager.io --timeout=60s

echo "Setup completed for Question 5"
exit 0
