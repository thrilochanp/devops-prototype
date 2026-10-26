#!/usr/bin/env bash
# Pin every third-party GitHub Action in .github/workflows to a full 40-character commit SHA,
# keeping the human-readable tag as a comment:  uses: actions/checkout@<sha> # v4
# Uses only the gh CLI (already installed and logged in) — no third-party pinning tool.
# Re-run after Dependabot or after adding a workflow; already-pinned lines are left alone.
set -euo pipefail
cd "$(dirname "$0")/.."

files=$(ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null || true)
if [ -z "$files" ]; then echo "No workflows found."; exit 0; fi

refs=$(grep -hoE 'uses:[[:space:]]*[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[A-Za-z0-9_.-]+' $files \
       | sed -E 's/uses:[[:space:]]*//' | sort -u)

for ref in $refs; do
  action="${ref%@*}"
  tag="${ref##*@}"
  if [[ "$tag" =~ ^[0-9a-f]{40}$ ]]; then
    continue                                   # already pinned
  fi
  repo="$(echo "$action" | cut -d/ -f1-2)"     # github/codeql-action/init -> github/codeql-action
  sha="$(gh api "repos/$repo/commits/$tag" --jq .sha)"
  if ! [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    echo "!! Could not resolve $action@$tag" >&2; exit 1
  fi
  echo "$action@$tag -> $sha"
  for f in $files; do
    perl -pi -e "s|uses:([ \t]*)\Q$action\E\@\Q$tag\E[ \t]*(#.*)?\$|uses:\${1}$action\@$sha # $tag|" "$f"
  done
done

left=$(grep -hE 'uses:[[:space:]]*[A-Za-z0-9_.-]+/' $files | grep -vE '@[0-9a-f]{40}' || true)
if [ -n "$left" ]; then
  echo "!! Still unpinned:"; echo "$left"; exit 1
fi
echo "Every action is pinned to a commit SHA."
