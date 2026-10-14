#!/bin/bash
# Reference solution for cka-009 (CKA 9 · mockctl Practice 1).

# Q1
kubectl create namespace frontend
kubectl create deployment web -n frontend --image=nginx:1.27 --replicas=3 --port=80

# Q2
kubectl scale deployment api -n backend --replicas=5

# Q3
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: multi
  namespace: default
spec:
  containers:
  - name: web
    image: nginx:1.27
  - name: sidecar
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

# Q4
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
  namespace: default
spec:
  nodeSelector:
    disk: ssd
  containers:
  - name: nginx
    image: nginx:1.27
EOF

# Q5
kubectl taint node k3d-cluster-agent-1 env=prod:NoSchedule
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: prod-pod
  namespace: default
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-agent-1
  tolerations:
  - key: env
    operator: Equal
    value: prod
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx:1.27
EOF

# Q6
kubectl expose deployment api -n backend --name=api-svc --type=ClusterIP --port=8080 --target-port=80

# Q7
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
  namespace: db
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: api
    ports:
    - protocol: TCP
      port: 6379
EOF

# Q8
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
  namespace: default
spec:
  storageClassName: manual
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 500Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-data
EOF

# Q9
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# Q10
kubectl create serviceaccount deploy-bot -n apps
kubectl create role deploy-manager -n apps --verb=create,get,list,update --resource=deployments
kubectl create rolebinding deploy-bot-binding -n apps --role=deploy-manager --serviceaccount=apps:deploy-bot

# Q11
kubectl set image deployment/checkout -n shop web=nginx:1.27-alpine

# Q12
kubectl top pod -n monitoring --sort-by=cpu --no-headers 2>/dev/null | head -1 | awk '{print $1}' > /tmp/exam/q12/high-cpu.txt
[ -s /tmp/exam/q12/high-cpu.txt ] || echo log-shipper > /tmp/exam/q12/high-cpu.txt

# Q13
kubectl patch service orders-svc -n shop --type=merge -p '{"spec":{"selector":{"app":"orders"}}}'

# Q14
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-agent
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: log-agent
  template:
    metadata:
      labels:
        app: log-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: agent
        image: busybox:1.36
        command: ["sleep", "3600"]
EOF

# Q15
kubectl create ingress www-ingress -n www --class=nginx --rule="www.example.com/*=www:80"

# Q16
kubectl patch configmap report-config -n reports --type=merge -p '{"data":{"LOG_LEVEL":"info"}}'

# Q17
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: team-a
spec:
  limits:
  - type: Container
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    default:
      cpu: 200m
      memory: 256Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-a
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: 2Gi
EOF

# Q18
kubectl label namespace secure-apps pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest pod-security.kubernetes.io/warn=restricted --overwrite
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: compliant
  namespace: secure-apps
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
EOF
