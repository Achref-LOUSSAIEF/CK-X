#!/bin/bash
# Setup for Question 8
kubectl create namespace web --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io crd/httproutes.gateway.networking.k8s.io --timeout=60s
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: ckx-gateway
spec:
  controllerName: ckx.io/gateway-controller
EOF
TMP=$(mktemp -d)
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "/CN=web.example.local" -keyout $TMP/tls.key -out $TMP/tls.crt >/dev/null 2>&1
kubectl create secret tls web-tls -n web --cert=$TMP/tls.crt --key=$TMP/tls.key --dry-run=client -o yaml | kubectl apply -f -
rm -rf $TMP
kubectl create deployment web -n web --image=nginx:1.27 --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment web -n web --port=80 --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  namespace: web
spec:
  ingressClassName: traefik
  tls:
  - hosts: ["web.example.local"]
    secretName: web-tls
  rules:
  - host: web.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
EOF

echo "Setup completed for Question 8"
exit 0
