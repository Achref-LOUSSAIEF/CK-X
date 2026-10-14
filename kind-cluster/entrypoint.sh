#!/bin/sh

# ===============================================================================
#   KIND Cluster Setup Entrypoint Script
#   Purpose: Initialize Docker and create Kind cluster
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== INITIALIZATION STARTED ====="
echo "$(date '+%Y-%m-%d %H:%M:%S') | Executing container startup script..."

# Execute current entrypoint script
if [ -f /usr/local/bin/startup.sh ]; then
    sh /usr/local/bin/startup.sh &
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Default startup script not found at /usr/local/bin/startup.sh"
fi

# ===============================================================================
#   Docker Readiness Check
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | Checking Docker service status..."
DOCKER_CHECK_COUNT=0

# Wait for docker to be ready
while ! docker ps; do   
    DOCKER_CHECK_COUNT=$((DOCKER_CHECK_COUNT+1))
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [WAITING] Docker service not ready yet... (attempt $DOCKER_CHECK_COUNT)"
    sleep 5
done

echo "$(date '+%Y-%m-%d %H:%M:%S') | [SUCCESS] Docker service is ready and operational"

# Pre-pull the pinned k3s node image in the background so the first exam starts faster
K3S_IMAGE=$(sed -n 's/^K3S_IMAGE=\${K3S_IMAGE:-\(.*\)}$/\1/p' /usr/local/bin/env-setup)
if [ -n "$K3S_IMAGE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Pre-pulling $K3S_IMAGE in the background"
    (docker pull "$K3S_IMAGE" >/dev/null 2>&1 || true) &
fi

#add user for ssh access
adduser -S -D -H -s /sbin/nologin -G sshd sshd

#start ssh service
/usr/sbin/sshd -D &

#install k3d
echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Installing k3d"
TAG=v5.8.3 bash /usr/local/bin/k3d-install.sh

# env-setup runs over SSH and does not see this container's environment
echo "${CKX_IMAGE_CACHE:-true}" > /etc/ckx-image-cache

# Start the local Docker Hub cache and fill it with the lab images in the background
(/usr/local/bin/image-cache prewarm || true) &

sleep 10
touch /ready

# Keep container running
tail -f /dev/null