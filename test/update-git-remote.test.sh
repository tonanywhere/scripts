#!/bin/bash
set -u

SCRIPT="$(cd "$(dirname "$0")/.." >/dev/null && pwd)/update-git-remote.sh"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT
failures=0

new_repo() {
  local dir
  dir=$(mktemp -d -p "$TMP_ROOT")
  git -C "$dir" init -q
  echo "$dir"
}

run_script() {
  (cd "$1" >/dev/null && shift && bash "$SCRIPT" "$@")
}

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

check_rewrite() {
  local name=$1 old_url=$2 expected=$3 repo
  repo=$(new_repo)
  git -C "$repo" remote add origin "$old_url"
  run_script "$repo" >/dev/null
  assert_eq "$name" "$expected" "$(git -C "$repo" remote get-url origin)"
}

check_rewrite ssh_owner_rewritten \
  git@github.com:ton-anywhere/foo.git git@github.com:tonanywhere/foo.git
check_rewrite https_owner_rewritten \
  https://github.com/ton-anywhere/foo.git https://github.com/tonanywhere/foo.git
check_rewrite ssh_scheme_rewritten \
  ssh://git@github.com/ton-anywhere/foo ssh://git@github.com/tonanywhere/foo
check_rewrite mixed_case_owner_rewritten \
  git@github.com:Ton-Anywhere/foo.git git@github.com:tonanywhere/foo.git
check_rewrite same_name_repo_only_owner_changes \
  git@github.com:ton-anywhere/ton-anywhere.git git@github.com:tonanywhere/ton-anywhere.git
check_rewrite foreign_owner_untouched \
  git@github.com:can1357/oh-my-pi.git git@github.com:can1357/oh-my-pi.git
check_rewrite owner_prefix_untouched \
  git@github.com:ton-anywhere-labs/foo.git git@github.com:ton-anywhere-labs/foo.git

repo=$(new_repo)
git -C "$repo" remote add origin git@github-personal:ton-anywhere/foo.git
(cd "$repo" >/dev/null && GITHUB_HOSTS="github.com github-personal" bash "$SCRIPT" >/dev/null)
assert_eq host_alias_rewritten git@github-personal:tonanywhere/foo.git "$(git -C "$repo" remote get-url origin)"

repo=$(new_repo)
git -C "$repo" remote add template git@github.com:APonce911/rails_with_lgtm.git
run_script "$repo" >/dev/null
assert_eq legacy_owner_rewritten git@github.com:tonanywhere/rails_with_lgtm.git "$(git -C "$repo" remote get-url template)"

repo=$(new_repo)
git -C "$repo" remote add origin git@github.com:ton-anywhere/a.git
git -C "$repo" remote set-url --add origin https://github.com/ton-anywhere/b.git
git -C "$repo" remote set-url --add --push origin git@github.com:ton-anywhere/c.git
git -C "$repo" remote set-url --add --push origin https://github.com/ton-anywhere/d.git
run_script "$repo" >/dev/null
assert_eq multiple_urls_all_rewritten \
  "git@github.com:tonanywhere/a.git https://github.com/tonanywhere/b.git git@github.com:tonanywhere/c.git https://github.com/tonanywhere/d.git" \
  "$(echo $(git -C "$repo" remote get-url --all origin) $(git -C "$repo" remote get-url --all --push origin))"

repo=$(new_repo)
git -C "$repo" remote add upstream git@github.com:can1357/oh-my-pi.git
git -C "$repo" remote set-url --push upstream DISABLE
run_script "$repo" >/dev/null
assert_eq disabled_remote_untouched \
  "git@github.com:can1357/oh-my-pi.git DISABLE" \
  "$(git -C "$repo" remote get-url upstream) $(git -C "$repo" remote get-url --push upstream)"

repo=$(new_repo)
git -C "$repo" remote add origin git@github.com:ton-anywhere/foo.git
run_script "$repo" >/dev/null
second_output=$(run_script "$repo")
second_status=$?
assert_eq idempotent "0:" "$second_status:$second_output"

repo=$(new_repo)
git -C "$repo" remote add origin git@github.com:ton-anywhere/foo.git
dry_output=$(run_script "$repo" --dry-run)
assert_eq dry_run_prints_change \
  "origin: git@github.com:ton-anywhere/foo.git -> git@github.com:tonanywhere/foo.git" "$dry_output"
assert_eq dry_run_changes_nothing git@github.com:ton-anywhere/foo.git "$(git -C "$repo" remote get-url origin)"

echo "$failures failure(s)"
[ "$failures" -eq 0 ]
