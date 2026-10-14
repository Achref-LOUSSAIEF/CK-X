#!/bin/bash
# Validate if logging pod exists with correct configuration

NAMESPACE="monitoring"
POD_NAME="logger"
EXPECTED_CONTAINERS=2

# Check if pod exists
if ! kubectl get pod $POD_NAME -n $NAMESPACE &> /dev/null; then
    echo "❌ Pod '$POD_NAME' not found in namespace '$NAMESPACE'"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Pod '$POD_NAME' exists but is not running (status: $POD_STATUS)"
    exit 1
fi

# Check if pod has two containers
CONTAINER_COUNT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}' | wc -w)
if [ "$CONTAINER_COUNT" -ne "$EXPECTED_CONTAINERS" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect number of containers: $CONTAINER_COUNT (expected: $EXPECTED_CONTAINERS)"
    exit 1
fi

# Check if containers are using correct images
BUSYBOX_IMAGE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[?(@.name=="busybox")].image}')
BUSYBOX_CONTAINER=""; [[ "$BUSYBOX_IMAGE" == busybox || "$BUSYBOX_IMAGE" == busybox:* ]] && BUSYBOX_CONTAINER=busybox
FLUENTD_IMAGE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[?(@.name=="fluentd")].image}')
FLUENTD_CONTAINER=""; [[ "$FLUENTD_IMAGE" == fluentd || "$FLUENTD_IMAGE" == fluentd:* ]] && FLUENTD_CONTAINER=fluentd

if [ -z "$BUSYBOX_CONTAINER" ] || [ -z "$FLUENTD_CONTAINER" ]; then
    echo "❌ Pod '$POD_NAME' is missing required containers with correct images"
    exit 1
fi

# Check if volume mount is configured
LOG_MOUNT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[?(@.name=="busybox")].volumeMounts[?(@.mountPath=="/var/log")].mountPath}')
if [ -z "$LOG_MOUNT" ]; then
    echo "❌ Volume mount '/var/log' not configured in pod '$POD_NAME'"
    exit 1
fi

# Check if emptyDir volume is used
VOLUME_TYPE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.volumes[?(@.name=="log-volume")].emptyDir}')
if [ -z "$VOLUME_TYPE" ]; then
    echo "❌ Pod '$POD_NAME' is not using emptyDir volume type"
    exit 1
fi

echo "✅ Pod '$POD_NAME' exists with correct configuration and containers"
exit 0 