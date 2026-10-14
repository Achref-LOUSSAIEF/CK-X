# CKA 10 · mockctl Practice 2: Solutions

> Tasks 1–14 are adapted from **Unofficial CKA Practice Exam 2** of [ericsson-james/mockctl-exam-lab](https://github.com/ericsson-james/mockctl-exam-lab) (MIT License, © 2026 James Ericsson; the license text is at the end of this page). They were moved from mockctl's simulated cluster to a real one: node names, file paths and a few details changed, and the explanations below build on the original solutions. The three node-level tasks of that exam (API server down, kubelet not starting, scheduler fault) need SSH to the nodes and are not included; tasks 15–18 were written for CKA Simulator instead.

---

## Question 1: ConfigMap and Secret as environment variables

```bash
kubectl create configmap app-config -n dev --from-literal=APP_MODE=production
kubectl create secret generic app-secret -n dev --from-literal=DB_PASS=s3cret
kubectl run app -n dev --image=busybox:1.36 --dry-run=client -o yaml -- sleep 3600 > app.yaml
```

Add to the container in `app.yaml`:

```yaml
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
```

`kubectl apply -f app.yaml`, then `kubectl exec -n dev app -- env | grep -E 'APP_MODE|DB_PASS'`.

## Question 2: Job with parallel completions

`kubectl create job` has no flags for completions or parallelism: generate YAML and edit it.

```bash
kubectl create job pi -n dev --image=busybox:1.36 --dry-run=client -o yaml -- sh -c "echo 3.14159" > pi.yaml
# under spec: completions: 2, parallelism: 2, backoffLimit: 4
kubectl apply -f pi.yaml
kubectl wait --for=condition=complete job/pi -n dev
```

## Question 3: CronJob

```bash
kubectl create cronjob backup -n dev --image=busybox:1.36 --schedule="*/5 * * * *" --dry-run=client -o yaml -- sh -c "echo backup" > backup.yaml
# under spec: concurrencyPolicy: Forbid and successfulJobsHistoryLimit: 2
kubectl apply -f backup.yaml
```

## Question 4: StatefulSet with a headless Service

```yaml
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
```

StatefulSet Pods start one at a time (`db-1` once `db-0` is Ready), and the headless Service gives each a stable DNS name such as `db-0.db.media.svc.cluster.local`.

## Question 5: HorizontalPodAutoscaler

```bash
kubectl autoscale deployment gateway -n payments --min=2 --max=6 --cpu=70%
kubectl get hpa -n payments
```

(Older kubectl versions use `--cpu-percent=70`.) This creates an `autoscaling/v2` HPA with a CPU `Utilization` target; TARGETS shows `<unknown>` until metrics-server has samples. The Pods need CPU requests for a utilization target to work, which `gateway` has.

## Question 6: Rolling update and history

```bash
kubectl set image deployment/catalog -n media nginx=nginx:1.27
kubectl rollout status deployment catalog -n media
kubectl rollout history deployment catalog -n media     # REVISION 1 and 2
echo 2 > /tmp/exam/q6/catalog-revisions.txt
```

Each Pod-template change creates a new ReplicaSet and a new revision.

## Question 7: Node affinity

```yaml
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
```

`kubectl get nodes -L zone` shows which node is east; `kubectl get pod east-pod -o wide` confirms the placement.

## Question 8: Egress NetworkPolicy

```yaml
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
```

Without the DNS rule the Pod can no longer resolve Service names. Check: `kubectl exec -n dev restricted -- wget -qO- -T 2 <api-pod-ip>` works, the same against the `sink` Pod times out.

## Question 9: Dynamic provisioning

```yaml
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
```

With a dynamic StorageClass nobody creates the PV: the provisioner creates a `pvc-<uid>` volume. `local-dyn` uses `WaitForFirstConsumer`, so the claim stays `Pending` until `writer` is scheduled.

## Question 10: Cluster-wide RBAC for a user

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding node-reader-dave --clusterrole=node-reader --user=dave
kubectl auth can-i list nodes --as=dave      # yes
kubectl auth can-i delete nodes --as=dave    # no
```

Nodes are cluster-scoped, so a namespaced Role cannot grant access to them.

## Question 11: Gateway API

```yaml
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
```

Gateway API splits what Ingress bundled: the GatewayClass is the implementation, the Gateway is the listener, and HTTPRoutes attach to it through `parentRefs`.

## Question 12: jsonpath

```bash
kubectl get node k3d-cluster-agent-0 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' > /tmp/exam/q12/node-ip.txt
```

The filter `[?(@.type=="InternalIP")]` picks the matching entry of the addresses list. Look at the structure first with `kubectl get node k3d-cluster-agent-0 -o yaml`.

## Question 13: Decode a Secret

```bash
kubectl get secret license -n payments -o jsonpath='{.data.key}' | base64 -d > /tmp/exam/q13/license.txt
```

Secret data is base64-encoded, not encrypted.

## Question 14: Drain a node

```bash
kubectl drain k3d-cluster-agent-1 --ignore-daemonsets --delete-emptydir-data
kubectl get pods -A -o wide --field-selector spec.nodeName=k3d-cluster-agent-1
```

`drain` cordons the node, then evicts its Pods; their controllers recreate them elsewhere. The `legacy` Pods stay `Pending` because only this node is in the legacy pool, which is expected. A Pod that no controller manages makes `drain` refuse unless you add `--force`, which deletes it for good. `kubectl uncordon` would reopen the node; the task says to leave it cordoned.

## Question 15: Readiness probe on the wrong port

```bash
kubectl get pods -n web                         # 0/1 Running
kubectl describe pod -n web -l app=web | grep -A3 Readiness
#  Readiness probe failed: ... connect: connection refused   (port 8080; nginx listens on 80)
kubectl patch deployment web -n web --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
kubectl get endpointslices -n web -l kubernetes.io/service-name=web
```

A Pod that is not Ready is removed from the Service's endpoints, even though its container runs.

## Question 16: Pods Pending because of requests

```bash
kubectl describe pod -n analytics -l app=analytics | grep -A3 Events
#  0/3 nodes are available: 3 Insufficient cpu.
kubectl set resources deployment analytics -n analytics --requests=cpu=100m,memory=128Mi
kubectl rollout status deployment analytics -n analytics
```

The scheduler only places a Pod on a node whose free allocatable resources cover its requests; `64` CPUs fits nowhere.

## Question 17: Service with named ports

```yaml
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
```

A Service with more than one port must name each of them. `targetPort` can be the container port's name, so the Service keeps working if the container's port number changes.

## Question 18: Shared in-memory emptyDir

```yaml
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
```

```bash
kubectl logs log-pair -n logs -c reader
```

`medium: Memory` puts the volume on tmpfs (it counts against the containers' memory), and `sizeLimit` evicts the Pod if it grows beyond 64Mi.

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
