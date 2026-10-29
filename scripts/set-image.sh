#!/usr/bin/env bash
# Points one environment at an image tag and pushes the change. Argo CD then
# rolls it out. Used by the app pipeline; works the same by hand:
#   scripts/set-image.sh prod 59d32ea
set -euo pipefail
cd "$(dirname "$0")/.."

env=${1:?usage: set-image.sh <env> <tag>}
tag=${2:?usage: set-image.sh <env> <tag>}
file="envs/$env/values.yaml"

[ -f "$file" ] || { echo "No such environment: $env" >&2; exit 1; }
[[ $tag =~ ^[0-9a-f]{7,40}$ ]] || { echo "Tag must be a git commit SHA, got: $tag" >&2; exit 1; }

sed -i.bak -E "s/^(  tag: )\"[^\"]*\"/\1\"$tag\"/" "$file" && rm -f "$file.bak"
grep -q "tag: \"$tag\"" "$file" || { echo "Could not update the tag in $file" >&2; exit 1; }

if git diff --quiet -- "$file"; then
  echo "$env is already on $tag."
  exit 0
fi

git add "$file"
git commit -q -m "release($env): shopflow $tag"
# Dev and prod releases can race; rebase and retry instead of failing.
for attempt in 1 2 3; do
  if git pull -q --rebase && git push -q; then
    echo "$env now points at $tag ($(git rev-parse --short HEAD))."
    exit 0
  fi
  sleep $((attempt * 2))
done
echo "Could not push the release commit." >&2
exit 1
