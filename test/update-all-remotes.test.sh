#!/bin/bash
set -u

SCRIPT="$(cd "$(dirname "$0")/.." >/dev/null && pwd)/update-all-remotes.sh"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT
failures=0

assert_eq() {
  local name=$1 expected=$2 actual=$3
  if [ "$expected" == "$actual" ]; then
    echo "PASS $name"
  else
    echo "FAIL $name"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    failures=$((failures + 1))
  fi
}

root_a="$TMP_ROOT/root-a"
root_b="$TMP_ROOT/root-b"
outside="$TMP_ROOT/outside"
mkdir -p "$root_a" "$root_b" "$outside"

git init -q "$root_a/normal"
git -C "$root_a/normal" remote add origin git@github.com:ton-anywhere/normal.git

git init -q "$root_a/no-remotes"

git init -q "$outside/main"
git -C "$outside/main" commit -q --allow-empty -m init
git -C "$outside/main" remote add origin git@github.com:ton-anywhere/main.git
git -C "$outside/main" worktree add -q "$root_b/linked-worktree" -b linked

mkdir "$root_b/not-a-repo"

git init -q "$root_b/broken"
echo "[broken" > "$root_b/broken/.git/config"

output=$(ROOTS="$root_a $root_b" bash "$SCRIPT" 2>&1)
status=$?

assert_eq normal_repo_rewritten git@github.com:tonanywhere/normal.git \
  "$(git -C "$root_a/normal" remote get-url origin)"
assert_eq worktree_rewritten git@github.com:tonanywhere/main.git \
  "$(git -C "$outside/main" remote get-url origin)"
assert_eq non_git_dir_skipped "" "$(echo "$output" | rg -- 'not-a-repo')"
assert_eq no_remotes_produces_no_output "--- no-remotes ---|--- normal ---" \
  "$(echo "$output" | rg -A1 -- '--- no-remotes ---' | paste -sd '|')"
assert_eq continues_after_failure "--- normal ---" "$(echo "$output" | rg -- '--- normal ---')"
assert_eq reports_failed_repo "FAILED broken" "$(echo "$output" | rg -o 'FAILED broken')"
assert_eq exits_non_zero_on_failure 1 "$status"

echo "$failures failure(s)"
[ "$failures" -eq 0 ]
