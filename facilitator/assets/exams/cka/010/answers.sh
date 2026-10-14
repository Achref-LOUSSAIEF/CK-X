#!/bin/bash
# Reference solution for cka-010 (CKA 10 · mockctl Practice 2).

# Q1
kubectl create configmap app-config -n dev --from-literal=APP_MODE=production
kubectl create secret generic app-secret -n dev --from-literal=DB_PASS=s3cret
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: dev
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    env:
    - name: APP_MODE
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_MODE
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: DB_PASS
EOF

# Q2
kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
  namespace: dev
spec:
  completions: 2
  parallelism: 2
  backoffLimit: 4
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: pi
        image: busybox:1.36
        command: ["sh", "-c", "echo 3.14159"]
EOF

# Q3
kubectl create cronjob backup -n dev --image=busybox:1.36 --schedule="*/5 * * * *" --dry-run=client -o yaml -- sh -c "echo backup" \
  | sed 's/^spec:$/spec:\n  concurrencyPolicy: Forbid\n  successfulJobsHistoryLimit: 2/' | kubectl apply -f -

# Q4
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: media
spec:
  clusterIP: None
  selector:
    app: db
  ports:
  - port: 6379
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
  namespace: media
spec:
  serviceName: db
  replicas: 2
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: redis
        image: redis:7.2
        ports:
        - containerPort: 6379
EOF

# Q5
kubectl autoscale deployment gateway -n payments --min=2 --max=6 --cpu=70%

# Q6
kubectl set image deployment/catalog -n media nginx=nginx:1.27
kubectl rollout status deployment/catalog -n media --timeout=120s
kubectl rollout history deployment/catalog -n media | grep -cE '^[0-9]+' > /tmp/exam/q6/catalog-revisions.txt

# Q7
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: east-pod
  namespace: default
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: zone
            operator: In
            values: ["east"]
  containers:
  - name: nginx
    image: nginx:1.27
EOF

# Q8
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-egress
  namespace: dev
spec:
  podSelector:
    matchLabels:
      role: restricted
  policyTypes: ["Egress"]
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 80
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

# Q9
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-dyn
  namespace: payments
spec:
  storageClassName: local-dyn
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: writer
  namespace: payments
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-dyn
EOF

# Q10
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding node-reader-dave --clusterrole=node-reader --user=dave

# Q11
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gw
  namespace: media
spec:
  gatewayClassName: nginx-gc
  listeners:
  - name: http
    protocol: HTTP
    port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: media-route
  namespace: media
spec:
  parentRefs:
  - name: main-gw
  hostnames: ["media.example.com"]
  rules:
  - backendRefs:
    - name: media
      port: 80
EOF

# Q12
kubectl get node k3d-cluster-agent-0 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' > /tmp/exam/q12/node-ip.txt

# Q13
kubectl get secret license -n payments -o jsonpath='{.data.key}' | base64 -d > /tmp/exam/q13/license.txt

# Q14
kubectl drain k3d-cluster-agent-1 --ignore-daemonsets --delete-emptydir-data --timeout=120s

# Q15
kubectl patch deployment web -n web --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'

# Q16
kubectl set resources deployment analytics -n analytics --requests=cpu=100m,memory=128Mi

# Q17
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: exporter
  namespace: metrics
spec:
  selector:
    app: exporter
  ports:
  - name: http
    port: 80
    targetPort: http
  - name: metrics
    port: 9100
    targetPort: metrics
EOF

# Q18
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: log-pair
  namespace: logs
spec:
  volumes:
  - name: shared
    emptyDir:
      medium: Memory
      sizeLimit: 64Mi
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /var/log/app/app.log; sleep 5; done"]
    volumeMounts:
    - name: shared
      mountPath: /var/log/app
  - name: reader
    image: busybox:1.36
    command: ["sh", "-c", "tail -F /logs/app.log"]
    volumeMounts:
    - name: shared
      mountPath: /logs
      readOnly: true
EOF
