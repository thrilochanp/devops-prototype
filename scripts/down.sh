#!/usr/bin/env bash
# Back up the Sealed Secrets key, then destroy the cluster. Nothing keeps running afterwards.
# Pass --stop-vm to also quit Docker Desktop and give its RAM back to macOS.
set -euo pipefail
cd "$(dirname "$0")/.."

if kind get clusters 2>/dev/null | grep -qx devops-proto; then
  scripts/sealing-key.sh backup || echo "   (no sealing key yet — fine before Lab 09)"
fi

terraform -chdir=infra/local destroy -auto-approve -input=false
echo "Remaining kind clusters: $(kind get clusters 2>/dev/null | wc -l | tr -d ' ')"

if [ "${1:-}" = "--stop-vm" ] && [ "$(uname -s)" = "Darwin" ]; then
  echo "==> Quitting Docker Desktop"
  osascript -e 'quit app "Docker"' || true
fi
