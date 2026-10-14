# CKA Assessment Answers

## Question 1: Namespace and Pod Creation

Create a namespace named `app-team1` and create a pod named `nginx-pod` with the following specifications:
- Image: nginx:1.19
- Namespace: app-team1
- Label: run=nginx-pod

```yaml
# Create namespace
kubectl create namespace app-team1

# Create pod
kubectl run nginx-pod --image=nginx:1.19 -n app-team1 --labels=run=nginx-pod
```

## Question 2: Static Pod Creation

Create a static pod named `static-web` on cka-q2 with the following specifications:
- Image: nginx:1.19
- Port: 80

```yaml
# Create static pod manifest
cat << EOF > /etc/kubernetes/manifests/static-web.yaml
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
```

## Question 3: Storage Setup

Create a StorageClass named `fast-storage` and a PVC named `data-pvc` with the following specifications:

StorageClass:
- Name: fast-storage
- Provisioner: kubernetes.io/no-provisioner
- Namespace: storage

PVC:
- Name: data-pvc
- StorageClass: fast-storage
- Size: 1Gi
- Namespace: storage
- Access Mode: ReadWriteOnce

```yaml
# Create storage namespace
kubectl create namespace storage

# Create StorageClass
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
EOF

# Create PVC
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage
spec:
  storageClassName: fast-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

## Question 4: Logging Setup

Create a pod named `logger` in the monitoring namespace with the following specifications:
- Container 1: busybox (writes logs to /var/log/app.log)
- Container 2: fluentd (reads logs from the same location)
- Use emptyDir volume to share logs between containers

```yaml
# Create monitoring namespace
kubectl create namespace monitoring

# Create pod
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: monitoring
spec:
  containers:
  - name: busybox
    image: busybox
    command: ['/bin/sh', '-c']
    args:
    - while true; do
        echo "$(date) - Application log entry" >> /var/log/app.log;
        sleep 10;
      done
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  - name: fluentd
    image: fluentd
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  volumes:
  - name: log-volume
    emptyDir: {}
EOF
```

## Question 5: RBAC Setup

Create a ServiceAccount named `app-sa` and configure RBAC to allow it to read pods in the default namespace.

```yaml
# Create ServiceAccount
kubectl create serviceaccount app-sa

# Create Role
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF

# Create RoleBinding
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
- kind: ServiceAccount
  name: app-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Question 6: Network Policy

Create a NetworkPolicy named `db-policy` in the networking namespace to allow only frontend pods to access the database pods on port 3306.

```yaml
# Create networking namespace
kubectl create namespace networking

# Create NetworkPolicy
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: networking
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 3306
EOF
```

## Question 7: Deployment and Service

Create a Deployment named `web-app` with 3 replicas and a NodePort Service named `web-service` with the following specifications:

Deployment:
- Name: web-app
- Image: nginx:1.19
- Replicas: 3

Service:
- Name: web-service
- Type: NodePort
- Port: 80
- Target Port: 80

```yaml
# Create Deployment
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
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
      containers:
      - name: nginx
        image: nginx:1.19
EOF

# Create Service
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: web-app
EOF
```

## Question 8: Resource Management

Create a pod named `resource-pod` in the monitoring namespace with the following resource specifications:
- CPU Request: 100m
- Memory Request: 128Mi
- CPU Limit: 200m
- Memory Limit: 256Mi

```yaml
# Create pod
cat << EOF | kubectl apply -f -
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
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
EOF
```

## Question 9: ConfigMap and Pod

Create a ConfigMap named `app-config` with a key `APP_COLOR` set to `blue` and create a pod named `config-pod` that mounts this ConfigMap at `/etc/config`.

```yaml
# Create ConfigMap
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: blue
EOF

# Create pod
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
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
```

## Question 10: Health Checks

Create a pod named `health-check` with the following health check specifications:
- Liveness Probe: HTTP GET / on port 80
- Readiness Probe: HTTP GET / on port 80
- Initial Delay: 5 seconds for both probes

```yaml
# Create pod
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: health-check
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
``` 