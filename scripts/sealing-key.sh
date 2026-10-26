#!/usr/bin/env bash
# Back up / restore the Sealed Secrets controller key so a rebuilt cluster can decrypt
# the SealedSecrets already committed to Git. The key file never goes into Git.
# Usage: scripts/sealing-key.sh backup|restore
set -euo pipefail

KEY_FILE="${SEALING_KEY_FILE:-$HOME/.devops-proto/sealed-secrets-key.yaml}"
NS=kube-system
LABEL=sealedsecrets.bitnami.com/sealed-secrets-key

case "${1:-}" in
  backup)
    count=$(kubectl -n "$NS" get secret -l "$LABEL" -o name | wc -l)
    if [ "$count" -eq 0 ]; then echo "No sealing key in cluster"; exit 1; fi
    mkdir -p "$(dirname "$KEY_FILE")" && chmod 700 "$(dirname "$KEY_FILE")"
    kubectl -n "$NS" get secret -l "$LABEL" -o yaml \
      | yq 'del(.items[].metadata.resourceVersion, .items[].metadata.uid, .items[].metadata.creationTimestamp, .items[].metadata.managedFields)' \
      > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    echo "Backed up $count key(s) to $KEY_FILE"
    ;;
  restore)
    if [ ! -f "$KEY_FILE" ]; then echo "No backup at $KEY_FILE (first run is fine)"; exit 0; fi
    kubectl apply -f "$KEY_FILE"
    echo "Restored sealing key(s) from $KEY_FILE"
    ;;
  *)
    echo "Usage: $0 backup|restore"; exit 2
    ;;
esac
