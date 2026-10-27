#!/usr/bin/env bash
# Install Envoy Gateway (Gateway API implementation) and the shared platform Gateway.
set -euo pipefail
cd "$(dirname "$0")/.."

EG_VERSION="${EG_VERSION:-v1.9.3}"   # v1.9: Gateway API v1.6.1, EOL 2027-02-14; check gateway.envoyproxy.io/news/releases/matrix/
GATEWAY_FILE="${GATEWAY_FILE:-platform/gateway/gateway.yaml}"

helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
  --version "$EG_VERSION" -n envoy-gateway-system --create-namespace --wait

kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
kubectl apply -f "$GATEWAY_FILE"
kubectl wait --timeout=3m -n envoy-gateway-system gateway/platform-gw --for=condition=Programmed
echo "Gateway programmed."
