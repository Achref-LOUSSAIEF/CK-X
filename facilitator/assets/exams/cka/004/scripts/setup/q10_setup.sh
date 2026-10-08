#!/bin/bash
# Setup for Question 10
kubectl create namespace web-api --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: web-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
EOF
kubectl expose deploy api -n web-api --port=80 --dry-run=client -o yaml | kubectl apply -f -
TMP=$(mktemp -d)
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "/CN=api.example.com" -keyout $TMP/tls.key -out $TMP/tls.crt >/dev/null 2>&1
kubectl create secret tls api-tls-cert -n web-api --cert=$TMP/tls.crt --key=$TMP/tls.key --dry-run=client -o yaml | kubectl apply -f -
rm -rf $TMP

echo "Setup completed for Question 10"
exit 0
