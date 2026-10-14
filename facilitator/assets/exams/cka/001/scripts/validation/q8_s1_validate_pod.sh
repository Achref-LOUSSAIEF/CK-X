#!/bin/bash
# Validate if resource-constrained pod exists with correct configuration

NAMESPACE="monitoring"
POD_NAME="resource-pod"
EXPECTED_IMAGE="nginx"
EXPECTED_CPU_REQUEST="100m"
EXPECTED_MEMORY_REQUEST="128Mi"
EXPECTED_CPU_LIMIT="200m"
EXPECTED_MEMORY_LIMIT="256Mi"

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

# Check if correct image is used
POD_IMAGE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != "$EXPECTED_IMAGE" && "$POD_IMAGE" != "$EXPECTED_IMAGE":* ]]; then
    echo "❌ Pod '$POD_NAME' using incorrect image: $POD_IMAGE (expected: $EXPECTED_IMAGE)"
    exit 1
fi

# Check resource requests
CPU_REQUEST=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
MEMORY_REQUEST=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.requests.memory}')

if [ "$CPU_REQUEST" != "$EXPECTED_CPU_REQUEST" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect CPU request: $CPU_REQUEST (expected: $EXPECTED_CPU_REQUEST)"
    exit 1
fi

if [ "$MEMORY_REQUEST" != "$EXPECTED_MEMORY_REQUEST" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect memory request: $MEMORY_REQUEST (expected: $EXPECTED_MEMORY_REQUEST)"
    exit 1
fi

# Check resource limits
CPU_LIMIT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
MEMORY_LIMIT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.limits.memory}')

if [ "$CPU_LIMIT" != "$EXPECTED_CPU_LIMIT" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect CPU limit: $CPU_LIMIT (expected: $EXPECTED_CPU_LIMIT)"
    exit 1
fi

if [ "$MEMORY_LIMIT" != "$EXPECTED_MEMORY_LIMIT" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect memory limit: $MEMORY_LIMIT (expected: $EXPECTED_MEMORY_LIMIT)"
    exit 1
fi

echo "✅ Pod '$POD_NAME' exists with correct resource configuration"
exit 0 