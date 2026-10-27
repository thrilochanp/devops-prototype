#!/usr/bin/env bash
# Print tool versions and, if a cluster exists, its health. Exits non-zero if a tool is missing.
# Works on macOS (bash 3.2) and Linux.
set -uo pipefail

CLUSTER="${KIND_CLUSTER:-k8s-learning}"
missing=0
check() {
  local name="$1"; shift
  if command -v "$name" >/dev/null 2>&1; then
    printf "  %-11s %s\n" "$name" "$("$@" 2>/dev/null | head -n1)"
  else
    printf "  %-11s MISSING\n" "$name"; missing=1
  fi
}

echo "Toolchain"
check docker    docker --version
check kind      kind version
check kubectl   kubectl version --client
check helm      helm version --short
check terraform terraform version
check ansible   ansible --version
check gh        gh --version
check argocd    argocd version --client --short
check kubeseal  kubeseal --version
check yq        yq --version
check jq        jq --version
check trivy     trivy --version
check gitleaks  gitleaks version
check tflint    tflint --version
check infracost infracost --version
check actionlint actionlint --version
check az        az version --query '"azure-cli"' -o tsv

echo
echo "Resources"
if [ "$(uname -s)" = "Darwin" ]; then
  printf "  %-11s %s\n" "host" "$(sw_vers -productName) $(sw_vers -productVersion), $(uname -m), $(( $(sysctl -n hw.memsize) / 1073741824 )) GB RAM, $(sysctl -n hw.ncpu) CPU"
fi
if docker info >/dev/null 2>&1; then
  printf "  %-11s %s\n" "docker VM" "$(docker info --format '{{.NCPU}} CPU, {{.MemTotal}} bytes RAM, {{.OperatingSystem}}' 2>/dev/null)"
  printf "  %-11s %s\n" "context" "$(docker context show 2>/dev/null)"
else
  printf "  %-11s %s\n" "docker" "engine NOT reachable (open Docker Desktop, or run scripts/docker-ready.sh)"; missing=1
fi

echo
echo "Cluster"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kubectl get nodes -o wide 2>/dev/null | sed 's/^/  /'
  echo
  kubectl get applications -n argocd 2>/dev/null | sed 's/^/  /' || true
else
  echo "  $CLUSTER not running (make up)"
fi

exit "$missing"
