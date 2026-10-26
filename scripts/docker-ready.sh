#!/usr/bin/env bash
# Make sure Docker Desktop is running, big enough for the platform, and tuned for kind.
# Used by `make up` and the Lab 01 playbook. Safe to run any time (bash 3.2 compatible).
set -euo pipefail

MIN_CPU=4
MIN_MEM_GIB=9          # Settings > Resources > Memory: 10 GB recommended
WAIT_SECONDS=180

# 1. Start Docker Desktop if the engine is not answering.
if ! docker info >/dev/null 2>&1; then
  if [ "$(uname -s)" = "Darwin" ] && [ -d /Applications/Docker.app ]; then
    echo "==> Starting Docker Desktop"
    open -ga Docker
  else
    echo "!! Docker engine not reachable and Docker Desktop not found in /Applications." >&2
    exit 1
  fi
  waited=0
  until docker info >/dev/null 2>&1; do
    if [ "$waited" -ge "$WAIT_SECONDS" ]; then
      echo "!! Docker Desktop did not become ready within ${WAIT_SECONDS}s. Open it and check for errors." >&2
      exit 1
    fi
    sleep 3; waited=$((waited + 3))
  done
fi

# 2. Make sure the CLI talks to Docker Desktop, not a leftover context.
ctx="$(docker context show 2>/dev/null || echo default)"
if [ "$ctx" != "desktop-linux" ] && docker context inspect desktop-linux >/dev/null 2>&1; then
  echo "==> Switching docker context from '$ctx' to desktop-linux"
  docker context use desktop-linux >/dev/null
fi

# 3. Check the VM is sized for the platform.
cpu="$(docker info --format '{{.NCPU}}')"
mem_bytes="$(docker info --format '{{.MemTotal}}')"
mem_gib=$((mem_bytes / 1073741824))
echo "==> Docker Desktop VM: ${cpu} CPU, ${mem_gib} GiB RAM, $(docker info --format '{{.Architecture}}')"
if [ "$cpu" -lt "$MIN_CPU" ] || [ "$mem_gib" -lt "$MIN_MEM_GIB" ]; then
  echo "!! Too small for the full platform. Docker Desktop > Settings > Resources:" >&2
  echo "!!   CPU limit 6, Memory limit 10 GB, Virtual disk limit 60 GB, then Apply & restart." >&2
  [ "${ALLOW_SMALL_VM:-0}" = "1" ] || exit 1
fi

# 4. Raise inotify limits inside the VM (kind runs many pods that watch files).
#    A privileged container writes the VM kernel's settings; they reset when Docker Desktop restarts.
docker run --rm --privileged alpine:3.20 \
  sysctl -q -w fs.inotify.max_user_watches=524288 fs.inotify.max_user_instances=512 >/dev/null
echo "==> inotify: $(docker run --rm alpine:3.20 cat /proc/sys/fs/inotify/max_user_instances) instances"
