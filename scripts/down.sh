#!/usr/bin/env bash
# Back up the Sealed Secrets key, then destroy the cluster. Nothing keeps running afterwards.
# The cluster is shared with the Kubernetes learning track, so this asks before destroying it.
# Pass --stop-vm to also quit Docker Desktop and give its RAM back to macOS.
# Non-interactive: FORCE=1 scripts/down.sh
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER="$(terraform -chdir=infra/local output -raw cluster_name 2>/dev/null || echo "${KIND_CLUSTER:-k8s-learning}")"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "This destroys kind cluster '$CLUSTER', including any Kubernetes-track workloads in it:"
  kubectl --context "kind-$CLUSTER" get deploy,sts -A --no-headers 2>/dev/null \
    | grep -vE '^(kube-system|local-path-storage) ' | awk '{print "   " $1 "/" $2}' || true
  if [ "${FORCE:-0}" != "1" ]; then
    read -r -p "Type the cluster name to confirm: " answer
    [ "$answer" = "$CLUSTER" ] || { echo "Aborted; nothing destroyed."; exit 1; }
  fi
  scripts/sealing-key.sh backup || echo "   (no sealing key yet — fine before Lab 09)"
fi

terraform -chdir=infra/local destroy -auto-approve -input=false
echo "Remaining kind clusters: $(kind get clusters 2>/dev/null | wc -l | tr -d ' ')"

if [ "${1:-}" = "--stop-vm" ] && [ "$(uname -s)" = "Darwin" ]; then
  echo "==> Quitting Docker Desktop"
  osascript -e 'quit app "Docker"' || true
fi
