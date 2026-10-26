#!/usr/bin/env bash
# Recreate the whole platform from Git. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Docker Desktop"
scripts/docker-ready.sh

echo "==> kind cluster (Terraform)"
terraform -chdir=infra/local init -input=false >/dev/null
terraform -chdir=infra/local apply -auto-approve -input=false
kind export kubeconfig --name devops-proto
kubectl wait --for=condition=Ready nodes --all --timeout=180s

echo "==> restore Sealed Secrets key (so committed SealedSecrets still decrypt)"
scripts/sealing-key.sh restore

echo "==> Envoy Gateway"
scripts/install-gateway.sh

echo "==> Argo CD"
scripts/install-argocd.sh

if grep -q thrilochanp gitops/root-app.yaml; then
  echo "!! gitops/root-app.yaml still contains thrilochanp — finish Lab 02 step 3 first."; exit 1
fi

echo "==> GitOps root application"
kubectl apply -f gitops/root-app.yaml

echo
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "UI: kubectl -n argocd port-forward svc/argocd-server 8443:443  ->  https://localhost:8443"
