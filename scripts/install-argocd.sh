#!/usr/bin/env bash
# Install Argo CD from the upstream stable manifests (server-side apply: the CRDs are large).
set -euo pipefail

ARGOCD_VERSION="${ARGOCD_VERSION:-stable}"   # or a tag such as v3.1.8 to pin
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
kubectl -n argocd rollout status deploy/argocd-server --timeout=5m
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=5m
echo "Argo CD ready."
