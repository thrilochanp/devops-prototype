#!/usr/bin/env bash
# Ship the working-tree changes through the protected main branch:
# branch -> commit -> push -> PR -> wait for required checks -> squash-merge -> back on main.
# Usage: scripts/ship.sh "feat(gitops): add kyverno"
set -euo pipefail

msg="${1:?Usage: scripts/ship.sh \"type(scope): message\"}"
branch="chg/$(date +%Y%m%d-%H%M%S)"

git switch -c "$branch"
git add -A
git commit -m "$msg"
git push -u origin "$branch"
gh pr create --fill
sleep 10                       # give GitHub a moment to register the checks
gh pr checks --watch --fail-fast
gh pr merge --squash --delete-branch
git switch main
git pull --ff-only
echo "Merged: $msg"
