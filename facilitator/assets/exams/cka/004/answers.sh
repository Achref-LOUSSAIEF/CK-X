#!/bin/bash
# Reference solution for CKA lab 004 (Mock Exam 01).
# Usage (in the exam terminal): bash answers.sh

# Q1 - ConfigMap mounted as a file; Pod volumes are immutable, so recreate the Pod
kubectl create configmap app-config -n production \
  --from-literal=config.yaml='database_host: postgres.production.svc.cluster.local'
kubectl get pod app-frontend -n production -o json \
  | jq 'del(.status, .metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.managedFields, .spec.nodeName)
        | .spec.volumes += [{"name":"config","configMap":{"name":"app-config"}}]
        | .spec.containers[0].volumeMounts += [{"name":"config","mountPath":"/etc/app"}]' > /tmp/app-frontend.json
kubectl replace --force -f /tmp/app-frontend.json

# Q2 - Role + RoleBinding
kubectl create role pod-deploy-lister -n staging --verb=get,list --resource=pods,deployments
kubectl create rolebinding dev-user-binding -n staging --role=pod-deploy-lister --user=dev-user

# Q3 - cordon, then move only the web-tier Pods (drain would evict db-local)
kubectl cordon k3d-cluster-agent-1
kubectl delete pod -n maintenance -l app=web-tier --field-selector spec.nodeName=k3d-cluster-agent-1

# Q4 - static provisioning
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: db-pv
spec:
  capacity:
    storage: 5Gi
  accessModes: ["ReadWriteMany"]
  storageClassName: fast-ssd
  hostPath:
    path: /mnt/db-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage
  namespace: databases
spec:
  accessModes: ["ReadWriteMany"]
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 5Gi
EOF
kubectl patch deploy db-app -n databases --type=json -p='[
  {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"data","persistentVolumeClaim":{"claimName":"db-storage"}}]},
  {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"data","mountPath":"/data"}]}]'

# Q5 - NetworkPolicies
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: shop
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes: ["Ingress"]
  ingress:
  - ports:
    - protocol: TCP
      port: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: shop
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 3000
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: shop
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF

# Q6 - Helm with value overrides
cat /tmp/exam/helm-charts/monitoring/values.yaml
helm install monitoring-stack /tmp/exam/helm-charts/monitoring -n monitoring --create-namespace \
  --set replica_count=3 --set storage_size=50Gi --set persistence.enabled=true

# Q7 - container runtime per node
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.nodeInfo.containerRuntimeVersion}{"\n"}{end}' > /tmp/exam/q7/runtimes.txt

# Q8 - who can read ConfigMaps in default?
for sa in $(kubectl get sa -n audit-lab -o jsonpath='{.items[*].metadata.name}'); do
  [ "$(kubectl auth can-i get configmaps -n default --as system:serviceaccount:audit-lab:$sa)" = "yes" ] && echo "$sa"
done > /tmp/exam/q8/cm-access.txt
kubectl get rolebindings -n default -o wide | grep audit-lab/deployer   # -> app-config-readers
kubectl delete rolebinding app-config-readers -n default

# Q9 - HPA
kubectl autoscale deploy web-app -n production --name=web-app-hpa --cpu-percent=70 --min=2 --max=10

# Q10 - Ingress with TLS
kubectl create ingress api-ingress -n web-api --class=traefik \
  --rule="api.example.com/api*=api:80,tls=api-tls-cert" \
  --rule="api.example.com/health=api:80"

# Q11 - Pods pending because no scheduler named custom-scheduler exists
kubectl patch deploy report-generator -n sched-debug --type=json \
  -p='[{"op":"remove","path":"/spec/template/spec/schedulerName"}]'

# Q12 - StatefulSet + headless Service
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: database-cluster
  namespace: db-cluster
spec:
  clusterIP: None
  selector:
    app: database-cluster
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database-cluster
  namespace: db-cluster
spec:
  serviceName: database-cluster
  replicas: 3
  selector:
    matchLabels:
      app: database-cluster
  template:
    metadata:
      labels:
        app: database-cluster
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: example
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: db-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: db-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
EOF

# Q13 - ResourceQuota + LimitRange
kubectl create quota test-quota -n test --hard=requests.cpu=4,requests.memory=8Gi
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: test-limits
  namespace: test
spec:
  limits:
  - type: Container
    min:
      cpu: 100m
      memory: 128Mi
    max:
      cpu: "1"
      memory: 1Gi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    default:
      cpu: 500m
      memory: 512Mi
EOF
kubectl run big -n test --image=busybox:1.36 --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"big","image":"busybox:1.36","resources":{"requests":{"cpu":"2","memory":"2Gi"},"limits":{"cpu":"2","memory":"2Gi"}}}]}}' || echo "rejected as expected"

# Q14 - Pod Security Admission
kubectl create namespace restricted
kubectl label namespace restricted pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/audit=baseline

# Q15 - sidecar logger
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: app-with-logger
  namespace: default
spec:
  volumes:
  - name: log-volume
    emptyDir: {}
  containers:
  - name: nginx
    image: nginx:1.25
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/nginx
  - name: logger
    image: busybox:1.36
    command: ["sh", "-c", "tail -F /logs/access.log"]
    volumeMounts:
    - name: log-volume
      mountPath: /logs
EOF
