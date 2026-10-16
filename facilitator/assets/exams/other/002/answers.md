# Helm Basics Lab - Solutions

> From the original CK-X labs (`helm-001`) by [Sailor.sh](https://github.com/sailor-sh/CK-X), BSL 1.1.

## Question 1: Verify Helm Installation

Verify the Helm installation by running the version command and saving the output to a file:

```bash
# Check Helm version and save to file
helm version > /tmp/exam/q1/helm-version.txt

# Verify the file content
cat /tmp/exam/q1/helm-version.txt
```

This command displays both the client and server version information, confirming that Helm is correctly installed and connected to the Kubernetes cluster.

## Question 2: Add Bitnami Chart Repository

```bash
# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repo to fetch the latest chart information
helm repo update

# Verify by listing repositories
helm repo list
```

## Question 3: Search for Nginx Chart

```bash
# Search for nginx in the Bitnami repo
helm search repo bitnami/nginx

# Save the results to a file
helm search repo bitnami/nginx > /tmp/exam/q3/nginx-charts.txt
```

## Question 4: Install Nginx Chart with Custom Configuration

```bash
# Install nginx chart with custom service configuration
helm install web-server bitnami/nginx \
  --set service.type=NodePort \
  --set service.nodePorts.http=30080
```

## Question 5: List All Helm Releases

```bash
# List all releases across all namespaces
helm list -A > /tmp/exam/q5/releases.txt
```

## Question 6: Get Release Status and Manifests

```bash
# Get status of the web-server release
helm status web-server > /tmp/exam/q6/web-server-status.txt

# Get the manifests rendered by the chart
helm get manifest web-server > /tmp/exam/q6/web-server-manifests.txt
```

## Question 7: Upgrade Release with New Replica Count

```bash
# Upgrade the release to set 3 replicas
helm upgrade web-server bitnami/nginx --set replicaCount=3

# Verify the update
kubectl get pods -l app.kubernetes.io/instance=web-server
```

## Question 8: Create Custom Values File and Install Redis

First, create the values file for Redis:

The Bitnami Redis chart nests these settings; find the keys first:

```bash
helm show values bitnami/redis | grep -n -A3 -E "^auth:|^master:|persistence:|resources:"
```

```bash
cat > /tmp/exam/q8/redis-values.yaml << EOF
auth:
  password: "password123"
master:
  persistence:
    enabled: true
  resources:
    limits:
      memory: 256Mi
      cpu: 100m
EOF
```

Then install Redis using the values file:

```bash
helm install cache-db bitnami/redis -f /tmp/exam/q8/redis-values.yaml
```

## Question 9: Create a New Helm Chart

```bash
# Create a new chart
helm create webapp

# Modify the Chart.yaml file
cat > webapp/Chart.yaml << EOF
apiVersion: v2
name: webapp
description: A simple web application
type: application
version: 0.1.0
appVersion: "1.2.3"
EOF
```

## Question 10: Package Chart and Create Local Repository

```bash
# Package the chart
helm package webapp

# Create a charts directory
mkdir -p /tmp/exam/q10/charts

# Move the packaged chart
mv webapp-*.tgz /tmp/exam/q10/charts/

# Create an index file
helm repo index /tmp/exam/q10/charts/

# Serve the directory over HTTP (helm repo add does not accept a local path)
python3 -m http.server 8879 --directory /tmp/exam/q10/charts >/dev/null 2>&1 &

# Add the local repo and check it
helm repo add localrepo http://localhost:8879
helm search repo localrepo/webapp
```

## Question 11: Roll Back a Release

```bash
# Check the history
helm history web-server

# Roll back to revision 1
helm rollback web-server 1

# Verify the rollback
helm status web-server
kubectl get deployment -l app.kubernetes.io/instance=web-server
```

## Question 12: Debug a Problematic Release

First, diagnose the issue:

```bash
# Check the release status
helm status buggy-app

# Look at the pods
kubectl get pods -l app.kubernetes.io/instance=buggy-app

# Check why pods are failing
kubectl describe pod -l app.kubernetes.io/instance=buggy-app
```

Create a diagnosis file:

```bash
cat > /tmp/exam/q12/diagnosis.txt << EOF
The buggy-app release is failing because it's using a non-existent image tag "nonexistenttag".
The pods can't start because the container image "nginx:nonexistenttag" cannot be pulled.

Steps taken to diagnose:
1. Used "helm status buggy-app" to check the release status
2. Used "kubectl get pods" to see pod status (ImagePullBackOff or ErrImagePull)
3. Used "kubectl describe pod" to see detailed error messages
EOF
```

Fix the issue:

```bash
# Upgrade the release with a valid image tag, using the chart in /tmp/exam/q12/buggy-chart
helm upgrade buggy-app /tmp/exam/q12/buggy-chart -n default --reuse-values --set image.tag=1.27
kubectl get pods -l app.kubernetes.io/instance=buggy-app
```

Alternatively, if you don't have access to the original chart:

```bash
# Create a new values file to override the problematic values
cat > /tmp/fixed-values.yaml << EOF
image:
  tag: latest
EOF

# Upgrade using the new values file
helm upgrade buggy-app /tmp/exam/q12/buggy-chart -n default -f /tmp/fixed-values.yaml
``` 