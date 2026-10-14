#!/bin/bash
# Reference solution for cka-006 (CKA Final Exam Simulation).

# Q1 - reuse a Released PV
kubectl patch pv orders-pv --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: orders-data
  namespace: orders
spec:
  storageClassName: manual
  volumeName: orders-pv
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 500Mi
EOF
# Edit the saved manifest: add the volume and the volumeMount
cat > /tmp/exam/q1/orders-db.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-db
  namespace: orders
spec:
  replicas: 1
  selector:
    matchLabels:
      app: orders-db
  template:
    metadata:
      labels:
        app: orders-db
    spec:
      containers:
      - name: mariadb
        image: mariadb:11
        env:
        - name: MARIADB_ALLOW_EMPTY_ROOT_PASSWORD
          value: "1"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: orders-data
EOF
kubectl apply -f /tmp/exam/q1/orders-db.yaml

# Q2 - render a chart without CRDs
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
kubectl create namespace argocd
helm template argocd argo/argo-cd --version 7.7.3 -n argocd --set crds.install=false > /tmp/exam/q2/argocd.yaml

# Q3 - native sidecar on an existing Deployment
kubectl patch deploy invoice-api -n billing --type=strategic -p '
spec:
  template:
    spec:
      volumes:
      - name: logs
        emptyDir: {}
      containers:
      - name: api
        volumeMounts:
        - name: logs
          mountPath: /var/log/invoice
      initContainers:
      - name: log-shipper
        image: busybox:1.36
        restartPolicy: Always
        command: ["sh", "-c", "tail -F /var/log/invoice/app.log"]
        volumeMounts:
        - name: logs
          mountPath: /var/log/invoice
'

# Q4 - HPA v2 with behavior
kubectl apply -f - <<'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: checkout-hpa
  namespace: checkout
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 120
EOF

# Q5 - CRDs and kubectl explain
kubectl get crd -o name | sed 's#.*/##' | grep 'cert-manager.io$' > /tmp/exam/q5/crds.txt
kubectl explain certificate.spec.subject > /tmp/exam/q5/subject.txt

# Q6 - PriorityClass one below the highest user-defined one
MAX=$(kubectl get priorityclass -o json | jq '[.items[] | select(.metadata.name | startswith("system-") | not) | .value] | max')
kubectl create priorityclass urgent --value=$((MAX - 1)) --description="one below the highest user-defined class"
kubectl patch deploy queue-worker -n jobs -p '{"spec":{"template":{"spec":{"priorityClassName":"urgent"}}}}'

# Q7 - dedicated node
kubectl taint node k3d-cluster-agent-1 dedicated=ml:NoSchedule
kubectl label node k3d-cluster-agent-1 dedicated=ml
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trainer
  namespace: ml
spec:
  replicas: 2
  selector:
    matchLabels:
      app: trainer
  template:
    metadata:
      labels:
        app: trainer
    spec:
      nodeSelector:
        dedicated: ml
      tolerations:
      - key: dedicated
        operator: Equal
        value: ml
        effect: NoSchedule
      containers:
      - name: trainer
        image: busybox:1.36
        command: ["sleep", "3600"]
EOF

# Q8 - Ingress -> Gateway API
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: web
spec:
  gatewayClassName: ckx-gateway
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    hostname: web.example.local
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: web-tls
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: web
spec:
  parentRefs:
  - name: web-gateway
  hostnames: ["web.example.local"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web
      port: 80
EOF
kubectl delete ingress web -n web

# Q9 - fix the Ingress (wrong pathType and wrong service port)
kubectl patch ingress store -n store --type=json -p='[
  {"op":"replace","path":"/spec/rules/0/http/paths/0/pathType","value":"Prefix"},
  {"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":8080}]'

# Q10 - least-permissive policy
kubectl apply -f /tmp/exam/q10/policy-3.yaml

# Q11 - default StorageClass
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-retain
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
for sc in $(kubectl get sc -o name | sed 's#.*/##' | grep -vx fast-retain); do
  kubectl annotate sc "$sc" storageclass.kubernetes.io/is-default-class=false --overwrite
done

# Q12 - named port + NodePort
kubectl patch deploy catalog -n catalog --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/ports","value":[{"name":"http","containerPort":80,"protocol":"TCP"}]}]'
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: catalog-np
  namespace: catalog
spec:
  type: NodePort
  selector:
    app: catalog
  ports:
  - port: 80
    targetPort: http
    nodePort: 30081
EOF

# Q13 - TLS 1.3 only
kubectl get cm secure-web-conf -n secure-web -o yaml | sed 's/ssl_protocols TLSv1.2 TLSv1.3;/ssl_protocols TLSv1.3;/' | kubectl apply -f -
kubectl rollout restart deploy/secure-web -n secure-web

# Q14 - patch resources
kubectl patch deploy report-api -n reports --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources","value":{"requests":{"cpu":"250m","memory":"256Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]'
