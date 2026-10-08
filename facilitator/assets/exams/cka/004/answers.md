# CKA Mock Exam 01 (CK-X edition): Solutions

> Adapted for CK-X from **Mock Exam 01** of [theplatformlab/CKA-Certified-Kubernetes-Administrator](https://github.com/theplatformlab/CKA-Certified-Kubernetes-Administrator) (MIT License, © 2026 TECH WITH MOHAMED). Questions were made concrete and auto-gradeable. Q7 (CRI-dockerd), Q8 (API audit logs) and Q11 (kube-scheduler static Pod) need SSH access to the nodes, which CK-X does not provide, so they were replaced with the closest task that can be checked through the API. Notes on what the original task looks like on a kubeadm cluster are included below.

---

## Question 1: ConfigMap mounted as a file

```bash
kubectl create configmap app-config -n production \
  --from-literal=config.yaml='database_host: postgres.production.svc.cluster.local'

kubectl get pod app-frontend -n production -o yaml > app-frontend.yaml
# edit app-frontend.yaml: add the volume + volumeMount below, remove status
kubectl replace --force -f app-frontend.yaml
```

```yaml
spec:
  containers:
  - name: app
    volumeMounts:
    - name: config
      mountPath: /etc/app          # the key config.yaml becomes /etc/app/config.yaml
  volumes:
  - name: config
    configMap:
      name: app-config
```

A Pod's volumes are immutable, so the Pod has to be recreated (`replace --force` deletes and recreates it in one step).

## Question 2: Role and RoleBinding

```bash
kubectl create role pod-deploy-lister -n staging --verb=get,list --resource=pods,deployments
kubectl create rolebinding dev-user-binding -n staging --role=pod-deploy-lister --user=dev-user
kubectl auth can-i list pods -n staging --as dev-user      # yes
kubectl auth can-i list pods -n default --as dev-user      # no
```

## Question 3: Node maintenance without evicting db-local

```bash
kubectl cordon k3d-cluster-agent-1
kubectl delete pod -n maintenance -l app=web-tier --field-selector spec.nodeName=k3d-cluster-agent-1
kubectl get pods -n maintenance -o wide
```

`kubectl drain` refuses to continue because `db-local` is not managed by a controller; adding `--force` would **delete** it and its `emptyDir` data. Cordoning plus deleting only the Deployment's Pods moves `web-tier` (the ReplicaSet recreates them on other nodes) while `db-local` keeps running.

## Question 4: Static PV, PVC and Deployment volume

```yaml
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
```

```bash
kubectl edit deploy db-app -n databases
```

```yaml
    spec:
      containers:
      - name: app
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: db-storage
```

## Question 5: NetworkPolicies for a three-tier app

```yaml
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
  - ports:                    # no "from": any source, but only port 80
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
```

```bash
kubectl exec -n shop tester -- wget -qO- -T 3 http://$(kubectl get pod frontend -n shop -o jsonpath='{.status.podIP}')
```

## Question 6: Helm install with overrides

```bash
cat /tmp/exam/helm-charts/monitoring/values.yaml
helm install monitoring-stack /tmp/exam/helm-charts/monitoring -n monitoring --create-namespace \
  --set replica_count=3 --set storage_size=50Gi --set persistence.enabled=true
helm list -n monitoring
helm get values monitoring-stack -n monitoring
```

Nested values use dots (`persistence.enabled`). A values file (`-f my-values.yaml`) works just as well.

## Question 7: Container runtime per node

```bash
kubectl get nodes -o wide          # CONTAINER-RUNTIME column
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.nodeInfo.containerRuntimeVersion}{"\n"}{end}' \
  > /tmp/exam/q7/runtimes.txt
```

On a real kubeadm node, switching to cri-dockerd means pointing the kubelet at the new socket (`--container-runtime-endpoint=unix:///var/run/cri-dockerd.sock`, or the `kubeadm.alpha.kubernetes.io/cri-socket` node annotation), then `systemctl daemon-reload && systemctl restart kubelet`.

## Question 8: Who can read ConfigMaps?

```bash
for sa in $(kubectl get sa -n audit-lab -o name | cut -d/ -f2); do
  echo "$sa: $(kubectl auth can-i get configmaps -n default --as system:serviceaccount:audit-lab:$sa)"
done
# ci: yes (edit), deployer: yes (configmap-reader in default)
# auditor: no (its binding is in kube-public), reporter: no (view in audit-lab only)
printf 'ci\ndeployer\n' > /tmp/exam/q8/cm-access.txt

kubectl get rolebindings -n default -o wide | grep audit-lab/deployer    # app-config-readers
kubectl delete rolebinding app-config-readers -n default
```

Do not delete the ClusterRole `configmap-reader`: `auditor` still uses it. On a kubeadm cluster, audit logging is enabled with `--audit-policy-file` and `--audit-log-path` in `/etc/kubernetes/manifests/kube-apiserver.yaml` (plus hostPath mounts for both).

## Question 9: HorizontalPodAutoscaler

```bash
kubectl autoscale deploy web-app -n production --name=web-app-hpa --cpu-percent=70 --min=2 --max=10
kubectl get hpa -n production
```

CPU utilization is computed against the containers' CPU **requests**, so the target Deployment needs them.

## Question 10: Ingress with TLS

```bash
kubectl create ingress api-ingress -n web-api --class=traefik \
  --rule="api.example.com/api*=api:80,tls=api-tls-cert" \
  --rule="api.example.com/health=api:80"
```

```yaml
spec:
  ingressClassName: traefik
  tls:
  - hosts: ["api.example.com"]
    secretName: api-tls-cert
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend: {service: {name: api, port: {number: 80}}}
      - path: /health
        pathType: Exact
        backend: {service: {name: api, port: {number: 80}}}
```

## Question 11: Pods never scheduled

```bash
kubectl describe pod -n sched-debug -l app=report-generator   # no events at all
kubectl get deploy report-generator -n sched-debug -o jsonpath='{.spec.template.spec.schedulerName}'   # custom-scheduler
kubectl patch deploy report-generator -n sched-debug --type=json \
  -p='[{"op":"remove","path":"/spec/template/spec/schedulerName"}]'
```

Pending Pods with no events at all mean no scheduler picked them up. On kubeadm, the same symptom for every Pod means `kube-scheduler` is down: check `kubectl get pods -n kube-system`, then on the control-plane node `crictl ps -a | grep scheduler`, `journalctl -u kubelet` and the manifest `/etc/kubernetes/manifests/kube-scheduler.yaml`.

## Question 12: StatefulSet with headless Service

```yaml
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
```

Each replica gets its own PVC (`db-storage-database-cluster-0`, `-1`, `-2`) and a DNS name `database-cluster-N.database-cluster.db-cluster.svc.cluster.local`.

## Question 13: ResourceQuota and LimitRange

```bash
kubectl create quota test-quota -n test --hard=requests.cpu=4,requests.memory=8Gi
```

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: test-limits
  namespace: test
spec:
  limits:
  - type: Container
    min: {cpu: 100m, memory: 128Mi}
    max: {cpu: "1", memory: 1Gi}
    defaultRequest: {cpu: 100m, memory: 128Mi}
    default: {cpu: 500m, memory: 512Mi}
```

A Pod asking for 2 CPUs / 2Gi is rejected by the LimitRange (`maximum cpu usage per Container is 1`). The quota alone (4 CPU) would still admit it, which is why the per-container `max` is needed.

## Question 14: Pod Security Admission

```bash
kubectl create namespace restricted
kubectl label namespace restricted \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=baseline
kubectl run priv --image=busybox:1.36 -n restricted --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"priv","image":"busybox:1.36","securityContext":{"privileged":true}}]}}'
# Error from server (Forbidden): ... violates PodSecurity "restricted:latest"
```

## Question 15: Sidecar logger

```yaml
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
```

```bash
kubectl exec app-with-logger -c nginx -- curl -s localhost >/dev/null
kubectl logs app-with-logger -c logger
```

---

## License of the original questions

```text
MIT License

Copyright (c) 2026 TECH WITH MOHAMED

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
