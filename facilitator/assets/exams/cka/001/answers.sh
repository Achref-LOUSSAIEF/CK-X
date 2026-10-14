#!/bin/bash
# Reference solution for cka-001 (CKA 1 · Warm-up: Core Concepts).

# Q1
kubectl create namespace app-team1
kubectl run nginx-pod -n app-team1 --image=nginx:1.19 --labels=run=nginx-pod

# Q2 - static Pod manifest (graded as a file; this machine is not a cluster node)
mkdir -p /etc/kubernetes/manifests
cat > /etc/kubernetes/manifests/static-web.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: static-web
spec:
  containers:
  - name: nginx
    image: nginx:1.19
    ports:
    - containerPort: 80
EOF

# Q3
kubectl create namespace storage --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Delete
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage
spec:
  storageClassName: fast-storage
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
EOF

# Q4
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: monitoring
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "while true; do echo \"$(date) - application log entry\" >> /var/log/app.log; sleep 5; done"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  - name: fluentd
    image: fluentd:v1.14
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  volumes:
  - name: log-volume
    emptyDir: {}
EOF

# Q5
kubectl create serviceaccount app-sa -n default
kubectl create role pod-reader -n default --verb=get,list --resource=pods
kubectl create rolebinding read-pods -n default --role=pod-reader --serviceaccount=default:app-sa

# Q6
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: networking
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 3306
EOF

# Q7
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  app: web-app
      containers:
      - name: nginx
        image: nginx:1.19
EOF
kubectl expose deployment web-app -n default --name=web-service --type=NodePort --port=80 --target-port=80

# Q8
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
  namespace: monitoring
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
EOF

# Q9
kubectl create configmap app-config -n default --from-literal=APP_COLOR=blue
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
EOF

# Q10
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: health-check
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
EOF
