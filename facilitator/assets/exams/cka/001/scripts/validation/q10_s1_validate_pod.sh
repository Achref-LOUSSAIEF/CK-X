#!/bin/bash
# Validate if pod with health checks exists with correct configuration

POD_NAME="health-check"
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

# Check if liveness probe is configured
LIVENESS_PROBE=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.path}')
if [ "$LIVENESS_PROBE" != "/" ]; then
    echo "❌ Pod '$POD_NAME' missing liveness probe or incorrect path"
    exit 1
fi

# Check if liveness probe port is correct
LIVENESS_PORT=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.port}')
if [ "$LIVENESS_PORT" != "80" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect liveness probe port: $LIVENESS_PORT (expected: 80)"
    exit 1
fi

# Check if readiness probe is configured
READINESS_PROBE=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].readinessProbe.httpGet.path}')
if [ "$READINESS_PROBE" != "/" ]; then
    echo "❌ Pod '$POD_NAME' missing readiness probe or incorrect path"
    exit 1
fi

# Check if readiness probe port is correct
READINESS_PORT=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].readinessProbe.httpGet.port}')
if [ "$READINESS_PORT" != "80" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect readiness probe port: $READINESS_PORT (expected: 80)"
    exit 1
fi

# Check if probes have correct initial delay
LIVENESS_DELAY=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].livenessProbe.initialDelaySeconds}')
READINESS_DELAY=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].readinessProbe.initialDelaySeconds}')

if [ "$LIVENESS_DELAY" != "5" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect liveness probe initial delay: $LIVENESS_DELAY (expected: 5)"
    exit 1
fi

if [ "$READINESS_DELAY" != "5" ]; then
    echo "❌ Pod '$POD_NAME' has incorrect readiness probe initial delay: $READINESS_DELAY (expected: 5)"
    exit 1
fi

echo "✅ Pod '$POD_NAME' exists with correct health check configuration"
exit 0 