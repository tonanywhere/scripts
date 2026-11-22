#!/bin/bash
set -u

ROOTS=${ROOTS:-"$HOME/code/ton-anywhere $HOME/code/open-source"}
SCRIPT="$(cd "$(dirname "$0")" >/dev/null && pwd)/update-git-remote.sh"

failed=()

for root in $ROOTS; do
  for dir in "$root"/*/; do
    [ -e "$dir/.git" ] || continue
    name=$(basename "$dir")
    echo "--- $name ---"
    if ! (cd "$dir" >/dev/null && bash "$SCRIPT" "$@"); then
      echo "FAILED $name"
      failed+=("$name")
    fi
  done
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed repos: ${failed[*]}"
  exit 1
fi
