# CKA 11 · Classic Exam Tasks: Solutions

> Original CKA Simulator exam. The topics were inspired by the practice questions and runbooks of [cloudhein/CKA](https://github.com/cloudhein/CKA): the classic exam tasks (log filtering, counting schedulable nodes, init containers from a spec file, Secrets as files and variables, Service and Pod DNS lookups, sorted and custom-column output) and its 2025 mock exams (CoreDNS repair and custom entries, a Helm install with a feature switched on by values, LimitRanges, a Retain StorageClass, Gateway API, sharing a node's resources between replicas). That repository has no license, so no text, scenario or script was copied: all scenarios, wording, setup and grading were written for CKA Simulator. Its tasks that need SSH to a node (kubelet and NotReady nodes, static Pods on a node, broken control-plane components, cri-dockerd and sysctl preparation, CNI installation) are not part of this exam.

---

## Question 1: Extract log lines to a file

```bash
kubectl logs bar -n web-logs | grep 'unable-to-access-website' > /tmp/exam/q1/bar-errors.log
cat /tmp/exam/q1/bar-errors.log
```

`kubectl logs` prints the container's stdout and stderr; `grep` keeps the matching lines, in order and with duplicates. Don't use `grep -c` (that only counts) and don't add `--timestamps` (the lines would no longer match the log). For a Pod with several containers, add `-c <container>`; for the previous instance of a restarted container, add `--previous`.

## Question 2: Count the schedulable nodes

```bash
kubectl get nodes                                         # STATUS column: Ready / NotReady
kubectl describe nodes | grep -E '^Name:|^Taints:'        # every node with its taints
```

Here all three nodes are `Ready`, and `k3d-cluster-agent-0` carries `maintenance=planned:NoSchedule`, so the answer is **2**:

```bash
echo 2 > /tmp/exam/q2/schedulable-nodes.txt
```

Don't forget the control-plane node: on a kubeadm cluster it carries `node-role.kubernetes.io/control-plane:NoSchedule` and is not counted, but this cluster's server node has no taint. A cordoned node counts as tainted too (it gets `node.kubernetes.io/unschedulable:NoSchedule`). A `PreferNoSchedule` taint doesn't make a node unschedulable. One command that does the whole check:

```bash
kubectl get nodes -o json | jq '[.items[]
  | select(any(.status.conditions[]; .type=="Ready" and .status=="True"))
  | select([.spec.taints[]? | select(.effect=="NoSchedule")] | length == 0)] | length'
```

## Question 3: Repair CoreDNS

Reproduce, then look at the configuration CoreDNS runs with:

```bash
kubectl exec -n dns-repair dns-client -- nslookup kubernetes.default   # works
kubectl exec -n dns-repair dns-client -- nslookup kubernetes.io        # times out
kubectl get configmap coredns -n kube-system -o yaml
kubectl logs -n kube-system -l k8s-app=kube-dns                        # i/o timeouts towards 192.0.2.53
```

The `kubernetes` plugin answers for `cluster.local`, so cluster names work. Every other name goes to the `forward` plugin, which sends it to `192.0.2.53`, an address where no DNS server runs (`192.0.2.0/24` is reserved for documentation). Point it back to the node's resolvers:

```bash
kubectl edit configmap coredns -n kube-system
#     forward . 192.0.2.53   ->   forward . /etc/resolv.conf
kubectl rollout restart deployment coredns -n kube-system   # or wait ~30 s for the reload plugin
kubectl exec -n dns-repair dns-client -- nslookup kubernetes.io
```

`forward . /etc/resolv.conf` uses the nameservers of the node CoreDNS runs on. That is the default in both kubeadm and k3s. The `reload` plugin picks up ConfigMap changes on its own, but the ConfigMap volume can take up to a minute to update in the Pod; restarting the Deployment is faster and shows syntax errors right away (in the CoreDNS logs).

## Question 4: Add a custom DNS entry to CoreDNS

Add a server block for the zone `myapp.internal` with the `hosts` plugin. On a kubeadm cluster (the real exam), edit the Corefile in the ConfigMap `coredns`:

```bash
kubectl edit configmap coredns -n kube-system
```

```
.:53 {
    ...                       # existing block, unchanged
}
myapp.internal:53 {
    hosts {
        10.10.10.10 myapp.internal
    }
}
```

```bash
kubectl rollout restart deployment coredns -n kube-system
kubectl exec -n dns-custom dns-client -- nslookup myapp.internal
```

Notes:

- A separate server block is the safest choice. The main block (`.:53`) may already use `hosts` (k3s does, for the node names), and CoreDNS refuses to load a block that uses the same plugin twice. If the main block has no `hosts` plugin, you can add one there instead, but then you must add `fallthrough`, otherwise every other name stops resolving.
- k3s also imports extra configuration from the optional ConfigMap `coredns-custom` (`*.server` keys are new server blocks, `*.override` keys go into the main block), and k3s updates leave it untouched. Either way is accepted here:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  myapp.server: |
    myapp.internal:53 {
        hosts {
            10.10.10.10 myapp.internal
        }
    }
```

## Question 5: Expose a Deployment and look up its DNS names

```bash
kubectl expose deployment nginx-random -n lookup --port=80
kubectl get svc,endpointslices -n lookup
```

A Service gets the name `<service>.<namespace>.svc.cluster.local`:

```bash
kubectl run tmp -n lookup --image=busybox:1.36 --restart=Never --rm -i -- \
  nslookup nginx-random.lookup.svc.cluster.local > /tmp/exam/q5/nginx-random.svc
```

A Pod gets `<ip-with-dashes>.<namespace>.pod.cluster.local`:

```bash
kubectl get pod -n lookup -l app=nginx-random -o wide          # e.g. IP 10.42.1.25
kubectl run tmp -n lookup --image=busybox:1.36 --restart=Never --rm -i -- \
  nslookup 10-42-1-25.lookup.pod.cluster.local > /tmp/exam/q5/nginx-random.pod
```

`--rm -i` attaches to the Pod, writes its output to your shell and deletes the Pod afterwards. Kubectl may add a line like `pod "tmp" deleted` at the end, which is fine (use `--quiet` to suppress it). Keep `-t` out when you redirect to a file.

## Question 6: Add an init container from a spec file

```bash
vim /tmp/exam/q6/ledger.yaml
```

```yaml
spec:
  initContainers:
  - name: prepare
    image: busybox:1.36
    command: ["sh", "-c", "touch /workdir/ready.flag"]
    volumeMounts:
    - name: workdir                 # the Pod's existing emptyDir volume
      mountPath: /workdir
  containers:
  - name: app
    ...
```

```bash
kubectl apply -f /tmp/exam/q6/ledger.yaml
kubectl get pod ledger -n init-lab -w          # Init:0/1 -> PodInitializing -> Running
kubectl logs ledger -n init-lab -c app         # ledger started
```

Init containers run one after another, each to completion, before the app containers start, and they share the Pod's volumes. Without the volume mount, the file would be created inside the init container's own filesystem and the app would never see it. If you created the Pod before fixing the file, delete it and apply again: you can't add init containers to a running Pod.

## Question 7: Use a Secret as files and as an environment variable

```bash
kubectl create secret generic app-secret -n secret-lab --from-literal=password=n0t-s0-s3cret
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-file
  namespace: secret-lab
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    volumeMounts:
    - name: secret
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: app-secret
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-env
  namespace: secret-lab
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    env:
    - name: APP_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: password
```

```bash
kubectl exec -n secret-lab secret-file -- cat /secrets/password
kubectl exec -n secret-lab secret-env -- printenv APP_PASSWORD
```

Each key of the Secret becomes a file in the mounted directory. Mounted Secrets are updated when the Secret changes; environment variables are only read when the container starts. Copying the value into `env[].value` is not the same: the password would then be stored in the Pod spec in plain text.

## Question 8: Share a node's resources between replicas

```bash
kubectl describe deployment cms -n blog          # requests: cpu 64, memory 256Gi
kubectl describe pod -n blog -l app=cms          # Insufficient cpu, Insufficient memory
kubectl describe node k3d-cluster-agent-1 | grep -A6 Allocatable
```

Take one third of the allocatable resources and leave some headroom, for example **25%** each. With `cpu: 16` and `memory: ~14.7Gi` allocatable, that is `4` CPUs and about `3680Mi` per Pod (your numbers depend on your machine). Set **the same values** on the init container and the `cms` container:

```bash
kubectl scale deployment cms -n blog --replicas=0
kubectl edit deployment cms -n blog
#   initContainers[0].resources.requests:  cpu: "4"  memory: 3680Mi
#   containers[0].resources.requests:      cpu: "4"  memory: 3680Mi
kubectl scale deployment cms -n blog --replicas=3
kubectl get pods -n blog -o wide
```

Why both? The scheduler uses the **effective** request of a Pod: the larger of the highest init container request and the sum of the app container requests. Forgetting the init container keeps the Pod unschedulable. Scaling to 0 first avoids a rolling update in which old and new Pods compete for the same node. If a Pod stays `Pending`, `kubectl describe node` shows what is already requested on the node (`Allocated resources`); lower your values a little.

## Question 9: Capture the output of a one-off Pod

```bash
kubectl run envdump -n oneoff --image=busybox:1.36 --restart=Never --rm -i --quiet -- env > /tmp/exam/q9/env.txt
cat /tmp/exam/q9/env.txt
kubectl get pod envdump -n oneoff          # NotFound
```

`--restart=Never` creates a plain Pod (not a Deployment), `--rm -i` waits for it, streams its output and deletes it afterwards, and everything after `--` is the container's command. Without `--rm` you would save the output with `kubectl logs envdump -n oneoff > /tmp/exam/q9/env.txt` and then `kubectl delete pod envdump -n oneoff`.

## Question 10: Install a Helm chart with a feature enabled by values

```bash
cat /tmp/exam/q10/edge-proxy/values.yaml          # providers.kubernetesGateway.enabled: false
helm show values /tmp/exam/q10/edge-proxy         # same, works for remote charts too
helm install edge /tmp/exam/q10/edge-proxy -n edge --create-namespace \
  --set providers.kubernetesGateway.enabled=true
helm get values edge -n edge
kubectl get deployment edge-edge-proxy -n edge -o jsonpath='{.spec.template.spec.containers[0].args}'
```

`--set` (or `-f my-values.yaml`) overrides chart defaults without touching the chart, and `helm get values` shows what you set. Real charts work the same way: the Traefik chart, for example, enables its Gateway API support with `--set providers.kubernetesGateway.enabled=true`. If you installed without the value, fix the release with `helm upgrade edge /tmp/exam/q10/edge-proxy -n edge --reuse-values --set providers.kubernetesGateway.enabled=true`.

## Question 11: LimitRange with defaults and a maximum

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: limits-lab
spec:
  limits:
  - type: Container
    defaultRequest:          # requests for containers that set none
      cpu: 100m
      memory: 50Mi
    default:                 # limits for containers that set none
      cpu: 200m
      memory: 100Mi
    max:
      memory: 500Mi
```

```bash
kubectl apply -f limitrange.yaml
kubectl run test -n limits-lab --image=nginx:1.27 --dry-run=server -o yaml | grep -A6 resources
kubectl run big -n limits-lab --image=nginx:1.27 --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"big","image":"nginx:1.27","resources":{"limits":{"memory":"600Mi"}}}]}}'
# Error: maximum memory usage per Container is 500Mi, but limit is 600Mi
```

The LimitRange admission plugin fills in the defaults and rejects Pods outside `min`/`max` when they are created; existing Pods are not changed. With a `max`, a container that sets no limit gets the `default` limit, so the default must not be above the maximum.

## Question 12: Sort PersistentVolumes by capacity

```bash
kubectl get pv -l team=storage-audit --sort-by=.spec.capacity.storage > /tmp/exam/q12/pv-by-size.txt
cat /tmp/exam/q12/pv-by-size.txt
```

`-l` filters by label, and `--sort-by` takes a JSONPath expression into each object. kubectl compares resource quantities by value, so `500Mi` comes before `1Gi` and `10Gi` comes last. Without `-l` the output also lists the cluster's other PVs.

## Question 13: Keep a volume with the Retain reclaim policy

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: keep-local
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: scratch
  namespace: retain-lab
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: keep-local
  resources:
    requests:
      storage: 64Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: writer
  namespace: retain-lab
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo 'hello from writer' > /data/hello.txt && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: scratch
```

```bash
kubectl apply -f retain.yaml
kubectl get pvc scratch -n retain-lab -w          # Pending until the Pod is scheduled, then Bound
kubectl exec -n retain-lab writer -- cat /data/hello.txt
kubectl delete pod writer -n retain-lab
kubectl delete pvc scratch -n retain-lab
kubectl get pv                                     # STATUS Released, CLAIM retain-lab/scratch
```

With `WaitForFirstConsumer` the volume is only provisioned once a Pod uses the claim, on that Pod's node. With `Retain`, deleting the claim leaves the PV and its data in place, in the `Released` state. It is not bound again automatically: to reuse it, an administrator removes its `claimRef` (see CKA 6), or copies the data and deletes the PV. With the default `Delete` policy, the PV and its data would be gone.

## Question 14: Attach a route from another namespace to a Gateway

```bash
kubectl label namespace web-app gateway-access=true
kubectl edit gateway shared-gw -n infra
```

```yaml
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            gateway-access: "true"
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: web-app
spec:
  parentRefs:
  - name: shared-gw
    namespace: infra            # required: the Gateway is in another namespace
    sectionName: http
  hostnames:
  - web.example.com
  rules:
  - backendRefs:
    - name: web-service
      port: 80
```

A route only attaches if **both** sides agree: the route names the Gateway in `parentRefs`, and the listener's `allowedRoutes` admits the route's namespace (`Same` by default, `All`, or `Selector`). `Selector` lets the platform team decide which namespaces may publish routes, which is safer than `All`. With a controller, `kubectl describe httproute web-route -n web-app` shows `Accepted: True` in the route's status; here no controller runs, so only the resources are graded. The backend is in the route's own namespace, so no ReferenceGrant is needed.

## Question 15: Report Pods with custom columns

```bash
kubectl get pods -n audit-lab --sort-by=.metadata.name \
  -o custom-columns=POD_NAME:.metadata.name,POD_STATUS:.status.phase > /tmp/exam/q15/pod-status.txt
cat /tmp/exam/q15/pod-status.txt
```

```
POD_NAME    POD_STATUS
analytics   Pending
cache       Running
importer    Failed
migrate     Succeeded
web         Running
```

`custom-columns` takes `HEADER:jsonpath` pairs separated by commas. `.status.phase` is the Pod's lifecycle phase (`Pending`, `Running`, `Succeeded`, `Failed`, `Unknown`). The `STATUS` column of the default output is computed by kubectl and shows more detail (`Completed`, `Error`, `CrashLoopBackOff`…). `kubectl get` already lists Pods by name, but `--sort-by=.metadata.name` makes the order explicit.
