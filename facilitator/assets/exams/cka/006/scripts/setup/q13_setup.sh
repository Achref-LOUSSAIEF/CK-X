#!/bin/bash
# Setup for Question 13
kubectl create namespace secure-web --dry-run=client -o yaml | kubectl apply -f -

TMP=$(mktemp -d)
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "/CN=secure-web" -keyout $TMP/tls.key -out $TMP/tls.crt >/dev/null 2>&1
kubectl create secret tls secure-web-tls -n secure-web --cert=$TMP/tls.crt --key=$TMP/tls.key --dry-run=client -o yaml | kubectl apply -f -
rm -rf $TMP
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: secure-web-conf
  namespace: secure-web
data:
  default.conf: |
    server {
      listen 443 ssl;
      server_name secure-web;
      ssl_certificate /etc/nginx/tls/tls.crt;
      ssl_certificate_key /etc/nginx/tls/tls.key;
      ssl_protocols TLSv1.2 TLSv1.3;
      location / {
        return 200 "secure-web ok\n";
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-web
  namespace: secure-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-web
  template:
    metadata:
      labels:
        app: secure-web
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 443
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/conf.d
        - name: tls
          mountPath: /etc/nginx/tls
          readOnly: true
      volumes:
      - name: conf
        configMap:
          name: secure-web-conf
      - name: tls
        secret:
          secretName: secure-web-tls
---
apiVersion: v1
kind: Service
metadata:
  name: secure-web
  namespace: secure-web
spec:
  selector:
    app: secure-web
  ports:
  - port: 443
    targetPort: 443
---
apiVersion: v1
kind: Pod
metadata:
  name: tls-client
  namespace: secure-web
spec:
  containers:
  - name: curl
    image: curlimages/curl:8.11.1
    command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 13"
exit 0
