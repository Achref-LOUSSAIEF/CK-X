# CKA 9 · mockctl Practice 1: Solutions

> Tasks 1–15 are adapted from **Unofficial CKA Practice Exam 1** of [ericsson-james/mockctl-exam-lab](https://github.com/ericsson-james/mockctl-exam-lab) (MIT License, © 2026 James Ericsson; the license text is at the end of this page). They were moved from mockctl's simulated cluster to a real one: node names, file paths and a few details changed, and the explanations below build on the original solutions. The three node-level tasks of that exam (etcd backup, control-plane upgrade, NotReady node) need SSH to the nodes and are not included; tasks 16–18 were written for CKA Simulator instead.

---

## Question 1: Create a Deployment

Imperative commands are fastest:

```bash
kubectl create namespace frontend
kubectl create deployment web -n frontend --image=nginx:1.27 --replicas=3 --port=80
kubectl rollout status deployment web -n frontend
```

`--port` adds the `containerPort` to the Pod template. If you prefer YAML, add `--dry-run=client -o yaml > web.yaml`, edit, then `kubectl apply -f web.yaml`.

## Question 2: Scale a Deployment

```bash
kubectl scale deployment api -n backend --replicas=5
kubectl get deployment api -n backend
```

Scaling only changes `spec.replicas`; the ReplicaSet creates the extra Pods. `kubectl edit` works too.

## Question 3: Multi-container Pod

```bash
kubectl run multi --image=nginx:1.27 --dry-run=client -o yaml > multi.yaml
vim multi.yaml
```

```yaml
spec:
  containers:
  - name: web              # renamed from "multi"
    image: nginx:1.27
  - name: sidecar
    image: busybox:1.36
    command: ["sleep", "3600"]
```

`kubectl apply -f multi.yaml`, then `kubectl get pod multi` must show `2/2`.

## Question 4: Schedule with a node selector

```bash
kubectl get nodes -l disk=ssd
kubectl run ssd-pod --image=nginx:1.27 --dry-run=client -o yaml > ssd-pod.yaml
# add under spec:
#   nodeSelector:
#     disk: ssd
kubectl apply -f ssd-pod.yaml
kubectl get pod ssd-pod -o wide
```

`nodeSelector` is the simplest form of node affinity: only nodes with every listed label are considered.

## Question 5: Taints and tolerations

```bash
kubectl taint node k3d-cluster-agent-1 env=prod:NoSchedule
kubectl describe node k3d-cluster-agent-1 | grep -A2 Taints
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: prod-pod
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-agent-1   # or nodeName: k3d-cluster-agent-1
  tolerations:
  - key: env
    operator: Equal
    value: prod
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx:1.27
```

A toleration only *allows* the Pod on the tainted node; the `nodeSelector` (or `nodeName`) is what puts it there. Remove a taint with a trailing dash: `kubectl taint node k3d-cluster-agent-1 env=prod:NoSchedule-`.

## Question 6: Expose a Deployment

```bash
kubectl expose deployment api -n backend --name=api-svc --type=ClusterIP --port=8080 --target-port=80
kubectl get endpointslices -n backend -l kubernetes.io/service-name=api-svc
```

`expose` copies the Deployment's selector (`app=api`). Endpoints only appear for Pods that match the selector **and** are Ready.

## Question 7: NetworkPolicy

```yaml
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
```

Once a policy selects a Pod for Ingress, everything not explicitly allowed is denied; that is what blocks `intruder`.

```bash
kubectl exec -n db api-client -- nc -zv -w 3 db 6379   # open
kubectl exec -n db intruder   -- nc -zv -w 3 db 6379   # times out
```

## Question 8: PersistentVolume and claim

```yaml
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
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-data
  containers:
  - name: nginx
    image: nginx:1.27
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
```

A claim binds to a volume with the same `storageClassName`, compatible access modes and at least the requested capacity. Check with `kubectl get pv,pvc`.

## Question 9: StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
```

`provisioner`, `reclaimPolicy` and `volumeBindingMode` are top-level fields (there is no `spec`). `WaitForFirstConsumer` creates the volume only once a Pod using the claim is scheduled.

## Question 10: RBAC for a ServiceAccount

```bash
kubectl create serviceaccount deploy-bot -n apps
kubectl create role deploy-manager -n apps --verb=create,get,list,update --resource=deployments
kubectl create rolebinding deploy-bot-binding -n apps --role=deploy-manager --serviceaccount=apps:deploy-bot
kubectl auth can-i create deployments -n apps --as=system:serviceaccount:apps:deploy-bot   # yes
kubectl auth can-i delete deployments -n apps --as=system:serviceaccount:apps:deploy-bot   # no
```

## Question 11: Broken Deployment

```bash
kubectl get pods -n shop                           # ErrImagePull / ImagePullBackOff
kubectl describe pod -n shop -l app=checkout | tail # failed to pull image "nginx:1.27-alpien"
kubectl set image deployment/checkout -n shop web=nginx:1.27-alpine
kubectl rollout status deployment checkout -n shop
```

`set image` (or `kubectl edit`) changes the Pod template, which creates a new ReplicaSet; the Deployment itself is kept. `ImagePullBackOff` is almost always a typo in the image name or tag.

## Question 12: Find the busiest Pod

```bash
kubectl top pod -n monitoring --sort-by=cpu
echo log-shipper > /tmp/exam/q12/high-cpu.txt
```

`kubectl top` reads the Metrics API (metrics-server). Write only the name when a task asks for an answer file.

## Question 13: Service without endpoints

```bash
kubectl get svc orders-svc -n shop -o wide        # SELECTOR app=order
kubectl get pods -n shop --show-labels            # app=orders
kubectl patch svc orders-svc -n shop -p '{"spec":{"selector":{"app":"orders"}}}'
kubectl get endpointslices -n shop -l kubernetes.io/service-name=orders-svc
```

## Question 14: DaemonSet on every node

There is no `kubectl create daemonset`: generate a Deployment and edit it.

```bash
kubectl create deployment log-agent -n kube-system --image=busybox:1.36 --dry-run=client -o yaml -- sleep 3600 > ds.yaml
# kind: DaemonSet, delete replicas, strategy and status, add the toleration
```

```yaml
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
```

The control-plane node has a `NoSchedule` taint, so without the toleration the DaemonSet skips it. `kubectl get ds log-agent -n kube-system`: DESIRED must equal the number of nodes.

## Question 15: Ingress

```bash
kubectl create ingress www-ingress -n www --class=nginx --rule="www.example.com/*=www:80"
kubectl get ingress www-ingress -n www -o yaml
```

The `/*` in the rule gives `pathType: Prefix` (a plain `/` gives `Exact`). Equivalent YAML:

```yaml
spec:
  ingressClassName: nginx
  rules:
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: www
            port:
              number: 80
```

## Question 16: CreateContainerConfigError

```bash
kubectl get pod report -n reports                 # CreateContainerConfigError
kubectl describe pod report -n reports | tail     # couldn't find key LOG_LEVEL in ConfigMap reports/report-config
kubectl get cm report-config -n reports -o yaml   # the key is log_level (lower case)
kubectl patch cm report-config -n reports --type=merge -p '{"data":{"LOG_LEVEL":"info"}}'
kubectl get pod report -n reports -w             # the kubelet retries and the container starts
```

A Pod's `env` cannot be edited, so the fix is to provide the key it asks for. The kubelet keeps retrying a container in `CreateContainerConfigError`, so the Pod starts on its own once the key exists.

## Question 17: LimitRange and ResourceQuota

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: team-a
spec:
  limits:
  - type: Container
    defaultRequest:        # requests for containers that set none
      cpu: 100m
      memory: 128Mi
    default:               # limits for containers that set none
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
```

```bash
kubectl run test -n team-a --image=nginx:1.27 --dry-run=server -o yaml | grep -A6 resources
kubectl describe resourcequota team-quota -n team-a
```

The LimitRange is applied at admission, so the server-side dry run shows the defaults. A quota on `requests.*` makes requests mandatory in the namespace; the LimitRange is what provides them.

## Question 18: Pod Security Admission

```bash
kubectl label namespace secure-apps \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  pod-security.kubernetes.io/warn=restricted --overwrite
```

```yaml
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
```

The `restricted` level requires `runAsNonRoot`, `allowPrivilegeEscalation: false`, dropping `ALL` capabilities and a `RuntimeDefault` (or `Localhost`) seccomp profile. If a field is missing, the API server's error message lists exactly what to add.

---

## License of the adapted tasks

```
MIT License

Copyright (c) 2026 James Ericsson

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
