#!/bin/bash
# safe-podman-clean.sh
# Cleans up stuck Podman/BuildKit build resources safely

echo "==> Cleaning up stuck build containers..."
podman container ls -a --filter "status=exited" --filter "name=buildkit" -q | xargs -r podman rm -f

echo "==> Pruning dangling images..."
podman image prune -f

echo "==> Pruning dangling volumes..."
podman volume prune -f

echo "==> Checking for leftover BuildKit tmp dirs..."
TMP_DIRS=$(find /var/tmp -maxdepth 1 -type d -name "buildah-*")
if [[ -n "$TMP_DIRS" ]]; then
    echo "Found leftover tmp dirs:"
    echo "$TMP_DIRS"
    echo "You can remove them manually if needed."
fi

echo "==> Done! Stuck memory/layers should be freed."
