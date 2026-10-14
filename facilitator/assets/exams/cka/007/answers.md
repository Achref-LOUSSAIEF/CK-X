# CKA 7 · Exam Simulation II: Solutions

> Original CK-X exam, written for CK-X. Every task covers a topic the other CK-X exams do not test (or test differently). Node-level tasks (kubeadm upgrade, etcd backup, CNI install) are not part of it; practise them on a kubeadm cluster such as Killercoda.

---

## Question 1: Node report with jsonpath

`range` loops over the nodes; the filter `?(@.type=="InternalIP")` selects one address:

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' \
  | sort > /tmp/exam/q1/nodes.txt
cat /tmp/exam/q1/nodes.txt
```

`-o custom-columns=NAME:.metadata.name,IP:.status.addresses[0].address --no-headers` also works on most clusters, but `addresses[0]` is not guaranteed to be the InternalIP; the filter is.

## Question 2: DNS blocked by a default-deny egress policy

A `default-deny-egress` policy blocks **everything** leaving the Pods, including DNS. NetworkPolicies are additive, so you keep the deny policy and add one that allows DNS. Both selectors in the **same** peer (`namespaceSelector` + `podSelector` without a second `-`) means "Pods labeled `k8s-app=kube-dns` in `kube-system`". Two separate list items would mean "any Pod in kube-system OR any kube-dns Pod anywhere".

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: sales
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

```bash
kubectl exec -n sales sales-client -- nslookup kubernetes.default
```

## Question 3: ResourceQuota blocks the Pods

The Deployment exists but the ReplicaSet cannot create Pods. The reason is in the ReplicaSet's events, not in the Deployment's:

```bash
kubectl get rs -n quota-lab
kubectl describe rs -n quota-lab -l app=inventory | tail
#  ... failed quota: compute: must specify limits.cpu for: api; limits.memory ...
```

A quota on `requests.*`/`limits.*` makes those fields mandatory for every Pod of the namespace (unless a LimitRange sets defaults):

```bash
kubectl set resources deployment inventory -n quota-lab \
  --requests=cpu=100m,memory=64Mi --limits=cpu=200m,memory=128Mi
kubectl rollout status deployment inventory -n quota-lab
```

## Question 4: Canary behind an existing Service

The Service selects only `app=shop`, so any Pod with that label receives traffic. 3 Pods of v1 + 1 Pod of v2 → v2 gets about 1/4 of the connections. The new Deployment's selector must include `version: v2`, otherwise the two Deployments would fight over each other's Pods.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v2
  namespace: shop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
      version: v2
  template:
    metadata:
      labels:
        app: shop
        version: v2
    spec:
      containers:
      - name: web
        image: nginx:1.27
```

```bash
kubectl get endpointslices -n shop -l kubernetes.io/service-name=shop
```

## Question 5: Service without a selector

Without a selector, Kubernetes does not manage the endpoints: you create them. The EndpointSlice is linked to the Service by the label `kubernetes.io/service-name`, and its port **name** must match the Service port name.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: legacy-db
  namespace: integrations
spec:
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: legacy-db-1
  namespace: integrations
  labels:
    kubernetes.io/service-name: legacy-db
addressType: IPv4
ports:
- name: postgres
  port: 5432
  protocol: TCP
endpoints:
- addresses: ["10.0.0.50"]
```

A legacy `Endpoints` object named `legacy-db` also works (it is deprecated since v1.33 but still mirrored into an EndpointSlice). For a DNS name instead of an IP you would use `type: ExternalName`.

## Question 6: Mount one Secret key as a file with a mode

`items` selects the keys to project (others are not mounted), `path` is the file name inside the mount directory, `mode` is the permission (YAML octal `0400` = decimal 256).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vault-agent
  namespace: vault
spec:
  containers:
  - name: agent
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: token
      mountPath: /etc/app
      readOnly: true
  volumes:
  - name: token
    secret:
      secretName: app-secrets
      items:
      - key: api-token
        path: token
        mode: 0400
```

```bash
kubectl exec -n vault vault-agent -- ls -l /etc/app/ /etc/app/token
```

(`subPath: token` with `mountPath: /etc/app/token` would also mount one file, but subPath mounts never receive Secret updates.)

## Question 7: Job with completions and parallelism

```bash
kubectl create job batch-import -n batch --image=busybox:1.36 --dry-run=client -o yaml \
  -- sh -c 'echo importing; sleep 2' > job.yaml
# add completions, parallelism, backoffLimit, ttlSecondsAfterFinished under spec:
```

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-import
  namespace: batch
spec:
  completions: 6
  parallelism: 2
  backoffLimit: 3
  ttlSecondsAfterFinished: 10800
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: import
        image: busybox:1.36
        command: ["sh", "-c", "echo importing; sleep 2"]
```

```bash
kubectl wait --for=condition=complete job/batch-import -n batch --timeout=120s
```

## Question 8: Aggregated ClusterRole

The controller-manager fills the `rules` of an aggregated ClusterRole with the rules of every ClusterRole matched by `aggregationRule` (that is how `admin`, `edit` and `view` are built). Anything you write in its `rules` is overwritten.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-aggregate
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.ckx.io/aggregate-to-monitoring: "true"
rules: []
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-pods
  labels:
    rbac.ckx.io/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-nodes
  labels:
    rbac.ckx.io/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
```

```bash
kubectl create clusterrolebinding prometheus-monitoring \
  --clusterrole=monitoring-aggregate --serviceaccount=monitoring:prometheus
kubectl get clusterrole monitoring-aggregate -o yaml        # rules filled in
kubectl auth can-i list pods -A --as=system:serviceaccount:monitoring:prometheus
```

## Question 9: Weighted HTTPRoute

Weights are relative: 90 and 10 → 90 % / 10 %. Both backends must be in the **same** rule; two rules would be two separate routes.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: store
  namespace: canary
spec:
  parentRefs:
  - name: edge
  hostnames: ["store.example.local"]
  rules:
  - backendRefs:
    - name: store-v1
      port: 80
      weight: 90
    - name: store-v2
      port: 80
      weight: 10
```

## Question 10: Kustomize overlay

```bash
mkdir -p /tmp/exam/q10/overlays/staging
cat > /tmp/exam/q10/overlays/staging/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
namespace: staging
namePrefix: staging-
labels:
- pairs:
    env: staging
images:
- name: nginx
  newTag: "1.27"
replicas:
- name: api
  count: 2
EOF
kubectl kustomize /tmp/exam/q10/overlays/staging     # check the output first
kubectl apply -k /tmp/exam/q10/overlays/staging
```

`replicas` and `images` refer to the **base** names (`api`, `nginx`), before the prefix is added. `commonLabels: {env: staging}` also works (it also adds the label to selectors; it is deprecated in favour of `labels`).

## Question 11: Helm install, upgrade and rollback

```bash
helm install webapp /tmp/exam/q11/webapp -n helm-apps --create-namespace -f /tmp/exam/q11/values-prod.yaml
helm upgrade webapp /tmp/exam/q11/webapp -n helm-apps --reuse-values --set image.tag=1.27
helm get values webapp -n helm-apps        # replicaCount 2, service.port 8080, image.tag 1.27
helm rollback webapp 1 -n helm-apps
helm history webapp -n helm-apps           # revision 3: "Rollback to 1"
```

Without `--reuse-values` (or `-f values-prod.yaml` again), `helm upgrade --set` starts from the chart defaults and silently drops the production values. `--reset-then-reuse-values` (Helm ≥ 3.14) is the safer variant when the chart's defaults changed.

## Question 12: Drain blocked by a PodDisruptionBudget

With `minAvailable: 2` and only 2 replicas, the eviction API refuses every eviction and `kubectl drain` retries forever ("Cannot evict pod as it would violate the pod's disruption budget"). Change the budget, do not delete it:

```bash
kubectl get pdb -n ledger        # ALLOWED DISRUPTIONS 0
kubectl patch pdb ledger-pdb -n ledger --type=json \
  -p='[{"op":"remove","path":"/spec/minAvailable"},{"op":"add","path":"/spec/maxUnavailable","value":1}]'
kubectl drain k3d-cluster-agent-0 --ignore-daemonsets --delete-emptydir-data
kubectl get pods -n ledger -o wide
```

`kubectl edit pdb ledger-pdb -n ledger` works too: delete the `minAvailable` line and add `maxUnavailable: 1` (a PDB cannot have both). Never use `--disable-eviction` or `--force` to get around a PDB in the exam.

## Question 13: CrashLoopBackOff

```bash
kubectl get pods -n reporting
kubectl logs -n reporting deploy/report-gen --previous      # logs of the crashed container
#  starting report generator
#  sh: sleeep: not found
kubectl logs -n reporting deploy/report-gen --previous | grep "not found" > /tmp/exam/q13/error.txt
kubectl edit deployment report-gen -n reporting
#  command: ["sh", "-c", "echo starting report generator; sleep 3600"]
kubectl rollout status deployment report-gen -n reporting
```

## Question 14: PVC with a missing StorageClass

```bash
kubectl describe pvc archive-data -n archive    # storageclass.storage.k8s.io "premium" not found
kubectl get sc                                  # local-path exists
```

`spec.storageClassName` of a PVC cannot be changed, and a PVC used by a Pod cannot be deleted until the Pod is gone. Save the Pod, delete both, recreate both:

```bash
kubectl get pod archive -n archive -o yaml > archive-pod.yaml
kubectl get pvc archive-data -n archive -o yaml > archive-pvc.yaml
kubectl delete pod archive -n archive
kubectl delete pvc archive-data -n archive
# archive-pvc.yaml: storageClassName: local-path, remove status/uid/resourceVersion/annotations
kubectl apply -f archive-pvc.yaml
# archive-pod.yaml: remove status, nodeName, uid, resourceVersion
kubectl apply -f archive-pod.yaml
kubectl get pvc,pod -n archive
```

`local-path` uses `WaitForFirstConsumer`: the PVC stays `Pending` until the Pod is scheduled. That is normal.

## Question 15: ValidatingAdmissionPolicy

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-two-replicas
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments"]
  validations:
  - expression: "object.spec.replicas >= 2"
    message: "production Deployments need at least 2 replicas"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-two-replicas-binding
spec:
  policyName: require-two-replicas
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        env: prod
```

```bash
kubectl create deployment t -n payments-prod --image=nginx --replicas=1 --dry-run=server   # denied
kubectl create deployment t -n payments-prod --image=nginx --replicas=2 --dry-run=server   # allowed
kubectl create deployment t -n payments-dev  --image=nginx --replicas=1 --dry-run=server   # allowed
```

The policy alone does nothing: only the binding enforces it, and its `matchResources` decides where.

## Question 16: Sort by creation time

```bash
kubectl get pods -n observability --sort-by=.metadata.creationTimestamp \
  -o custom-columns=NAME:.metadata.name --no-headers > /tmp/exam/q16/pods-by-age.txt
cat /tmp/exam/q16/pods-by-age.txt
```

`--sort-by` sorts ascending, so the oldest Pod is first. `-o name` would print `pod/<name>`; `custom-columns ... --no-headers` prints only the names.
