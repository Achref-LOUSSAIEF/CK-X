# CKA 8 · Exam Simulation III: Solutions

> Original CKA Simulator exam. Every task covers a topic the other CKA Simulator exams do not test (or test differently). Node-level tasks (kubeadm upgrade, etcd backup, CNI install) are not part of it; practise them on a kubeadm cluster such as Killercoda.

---

## Question 1: StatefulSet partitioned rolling update

With `rollingUpdate.partition: N`, only Pods with an ordinal **≥ N** are updated when the template changes. Set the partition **before** changing the image, otherwise all Pods start rolling:

```bash
kubectl patch statefulset web -n stateful --type=merge \
  -p '{"spec":{"updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"partition":2}}}}'
kubectl set image statefulset/web -n stateful nginx=nginx:1.27
kubectl get pods -n stateful -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
```

To finish the rollout later: set `partition: 0`.

## Question 2: Immutable ConfigMap

An immutable ConfigMap cannot be edited: you create a new one with a new name and point the workload at it (this also triggers a rollout, which an in-place edit of an envFrom ConfigMap would not).

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config-v2
  namespace: frontend
immutable: true
data:
  LOG_LEVEL: debug
  THEME: dark
```

```bash
kubectl edit deployment frontend -n frontend     # envFrom[0].configMapRef.name: frontend-config-v2
kubectl rollout status deployment frontend -n frontend
kubectl logs -n frontend deploy/frontend         # LOG_LEVEL=debug
```

## Question 3: Downward API environment variables

`fieldRef` exposes Pod fields; `resourceFieldRef` exposes the container's requests/limits, and `divisor: 1Mi` converts bytes to mebibytes.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: meta-reporter
  namespace: telemetry
spec:
  containers:
  - name: reporter
    image: busybox:1.36
    command: ["sh", "-c", "env; sleep 3600"]
    resources:
      limits:
        memory: 64Mi
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: MEM_LIMIT_MI
      valueFrom:
        resourceFieldRef:
          containerName: reporter
          resource: limits.memory
          divisor: 1Mi
```

The docs page "Expose Pod Information to Containers Through Environment Variables" has this exact pattern.

## Question 4: Init container that never finishes

```bash
kubectl get pods -n startup                       # api-...  Init:0/1
kubectl logs -n startup deploy/api -c wait-db     # ** server can't find db.startup.svc.cluster.local: NXDOMAIN / waiting for db
kubectl get svc -n startup                        # the Service is called "database"
```

The init container looks up a Service name that does not exist. Fix the command in the Deployment:

```bash
kubectl edit deployment api -n startup
#  initContainers[0].command: until nslookup database.startup.svc.cluster.local; do ...; done
kubectl rollout status deployment api -n startup
```

`kubectl logs <pod> -c <init-container>` is the key command: the default container of a Pod stuck in Init has no logs yet.

## Question 5: ExternalName Service

```bash
kubectl create service externalname provider -n payments --external-name=api.payments-provider.example.com
kubectl get svc provider -n payments
```

An ExternalName Service has no ClusterIP, no selector logic and no endpoints: the cluster DNS answers `provider.payments.svc.cluster.local` with a CNAME to the external host.

## Question 6: Egress with ipBlock, except and a port range

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: crawler-egress
  namespace: crawler
spec:
  podSelector:
    matchLabels:
      app: crawler
  policyTypes: ["Egress"]
  egress:
  - to:
    - ipBlock:
        cidr: 10.20.0.0/16
        except: ["10.20.5.0/24"]
    ports:
    - protocol: TCP
      port: 8000
      endPort: 8100
  - ports:            # no "to": any destination
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

`policyTypes: ["Egress"]` only: listing `Ingress` without ingress rules would deny all incoming traffic. `endPort` turns `port` into the start of a range.

## Question 7: Headless Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cache-peers
  namespace: cache
spec:
  clusterIP: None
  selector:
    app: cache
  ports:
  - name: redis
    port: 6379
    targetPort: 6379
```

```bash
echo cache-peers.cache.svc.cluster.local > /tmp/exam/q7/fqdn.txt
kubectl run -it --rm dns-test -n cache --image=busybox:1.36 --restart=Never -- nslookup cache-peers   # 3 A records, one per Pod
```

## Question 8: No automount + projected token for an audience

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: builder
  namespace: ci
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: builder
  namespace: ci
spec:
  serviceAccountName: builder
  containers:
  - name: builder
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: vault-token
      mountPath: /var/run/secrets/vault
      readOnly: true
  volumes:
  - name: vault-token
    projected:
      sources:
      - serviceAccountToken:
          audience: vault
          expirationSeconds: 3600
          path: token
```

Because the ServiceAccount disables automounting, the Pod gets no `kube-api-access-*` volume; it only has the token you projected. (`automountServiceAccountToken: false` in the Pod spec would also work and takes precedence.)

## Question 9: Role restricted with resourceNames

```bash
kubectl create role app-settings-editor -n config --verb=get,update,patch \
  --resource=configmaps --resource-name=app-settings
kubectl create rolebinding jane-app-settings -n config --role=app-settings-editor --user=jane
kubectl auth can-i update configmap/app-settings -n config --as=jane     # yes
kubectl auth can-i get configmap/db-settings -n config --as=jane         # no
kubectl auth can-i list configmaps -n config --as=jane                   # no
```

`resourceNames` cannot restrict `list`, `watch` or `create` (the name is not known for those requests), so never add those verbs to such a rule.

## Question 10: Hardened securityContext

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hardened
  namespace: secure
spec:
  securityContext:          # Pod level: applies to all containers; fsGroup only exists here
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /work/log; sleep 10; done"]
    securityContext:        # container level: readOnlyRootFilesystem, capabilities, allowPrivilegeEscalation
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: work
      mountPath: /work
  volumes:
  - name: work
    emptyDir: {}
```

```bash
kubectl exec -n secure hardened -- id               # uid=1000 gid=3000 groups=2000
kubectl exec -n secure hardened -- touch /x         # Read-only file system
```

## Question 11: NoExecute tolerationSeconds

Kubernetes adds `node.kubernetes.io/not-ready` and `unreachable` tolerations with `tolerationSeconds: 300` to every Pod. Declaring them yourself with a shorter time overrides the default:

```yaml
spec:
  template:
    spec:
      tolerations:
      - key: node.kubernetes.io/unreachable
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
```

```bash
kubectl edit deployment edge-cache -n edge
kubectl get pod -n edge -l app=edge-cache -o jsonpath='{.items[0].spec.tolerations}'
```

## Question 12: Local PersistentVolume

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-ssd
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ssd-pv-1
spec:
  capacity:
    storage: 2Gi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-ssd
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:              # required for local volumes
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: ["k3d-cluster-agent-1"]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ssd-claim
  namespace: localdisk
spec:
  storageClassName: local-ssd
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
```

`WaitForFirstConsumer` delays the binding until a Pod is scheduled, so the scheduler can pick the node where the disk is. Unlike `hostPath`, a `local` PV makes the scheduler send the Pod to that node.

## Question 13: Roll back to a specific revision

```bash
kubectl rollout history deployment checkout -n checkout
kubectl rollout history deployment checkout -n checkout --revision=1 | grep Image   # nginx:1.25
echo 1 > /tmp/exam/q13/revision.txt
kubectl rollout undo deployment checkout -n checkout --to-revision=1
kubectl rollout status deployment checkout -n checkout
```

A plain `rollout undo` goes back only one revision (to nginx:1.27). After the undo, the old revision 1 becomes the newest revision (5).

## Question 14: Distinct images with jsonpath

```bash
kubectl get pods -n inventory -o jsonpath='{range .items[*]}{range .spec.initContainers[*]}{.image}{"\n"}{end}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' \
  | grep -v '^$' | sort -u > /tmp/exam/q14/images.txt
cat /tmp/exam/q14/images.txt
```

`{.items[*].spec.containers[*].image}` alone misses the init container (`alpine:3.20`) and prints everything on one line; `sort -u` sorts and removes the duplicates.

## Question 15: HTTPRoute header match

Rules with a more specific match win; a rule without `matches` matches every path (`PathPrefix /`) and is the default.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api
  namespace: gw-lab
spec:
  parentRefs:
  - name: public
  hostnames: ["api.example.local"]
  rules:
  - matches:
    - headers:
      - name: x-channel
        value: beta
    backendRefs:
    - name: api-beta
      port: 8080
  - backendRefs:
    - name: api-stable
      port: 8080
```

## Question 16: Service without endpoints

```bash
kubectl get endpointslices -n orders -l kubernetes.io/service-name=orders   # no endpoints
kubectl get svc orders -n orders -o yaml          # selector app=order, targetPort 8080
kubectl get pods -n orders --show-labels          # app=orders, tier=backend; container listens on 80
```

Two bugs: the selector has a typo, and `targetPort` points at a port nothing listens on.

```bash
kubectl patch service orders -n orders --type=merge \
  -p '{"spec":{"selector":{"app":"orders","tier":"backend"},"ports":[{"port":80,"targetPort":80}]}}'
kubectl get endpointslices -n orders -l kubernetes.io/service-name=orders
```

`targetPort: http` (the container port name) also works.
