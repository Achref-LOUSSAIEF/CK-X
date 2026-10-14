#!/bin/bash
# Validate if pod using ConfigMap exists with correct configuration

POD_NAME="config-pod"
CONFIGMAP_NAME="app-config"
EXPECTED_IMAGE="nginx"

# Check if pod exists
if ! kubectl get pod $POD_NAME &> /dev/null; then
    echo "❌ Pod '$POD_NAME' not found"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod $POD_NAME -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod '$POD_NAME' exists but is not running (status: $POD_STATUS)"
    exit 1
fi

# Check if correct image is used
POD_IMAGE=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != "$EXPECTED_IMAGE" && "$POD_IMAGE" != "$EXPECTED_IMAGE":* ]]; then
    echo "❌ Pod '$POD_NAME' using incorrect image: $POD_IMAGE (expected: $EXPECTED_IMAGE)"
    exit 1
fi

# Check if ConfigMap is mounted
CONFIGMAP_MOUNT=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.volumes[?(@.configMap.name=="app-config")].name}')
if [ -z "$CONFIGMAP_MOUNT" ]; then
    echo "❌ Pod '$POD_NAME' not mounting ConfigMap '$CONFIGMAP_NAME'"
    exit 1
fi

# Check if ConfigMap is mounted at correct path
MOUNT_PATH=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name=="config-volume")].mountPath}')
if [ "$MOUNT_PATH" != "/etc/config" ]; then
    echo "❌ Pod '$POD_NAME' mounting ConfigMap at incorrect path: $MOUNT_PATH (expected: /etc/config)"
    exit 1
fi

echo "✅ Pod '$POD_NAME' exists with correct ConfigMap configuration"
exit 0 