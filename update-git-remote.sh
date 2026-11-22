#!/bin/bash
set -euo pipefail

OLD_USERS=${OLD_USERS:-"ton-anywhere APonce911"}
NEW_USER=${NEW_USER:-tonanywhere}
GITHUB_HOSTS=${GITHUB_HOSTS:-github.com}

dry_run=false
if [ "${1:-}" == "--dry-run" ]; then
  dry_run=true
fi

rewrite_url() {
  local url=$1 host old_user
  shopt -s nocasematch
  for host in $GITHUB_HOSTS; do
    for old_user in $OLD_USERS; do
      if [[ $url =~ ^(.*${host//./\\.}[:/])${old_user}(/.*)$ ]]; then
        echo "${BASH_REMATCH[1]}${NEW_USER}${BASH_REMATCH[2]}"
        return
      fi
    done
  done
  echo "$url"
}

config_entries=$(git config --get-regexp '^remote\..*\.(url|pushurl)$' || true)

while read -r key url; do
  [ -z "$key" ] && continue
  [[ $url == DISABLE* ]] && continue

  new_url=$(rewrite_url "$url")
  [ "$new_url" == "$url" ] && continue

  remote=${key#remote.}
  remote=${remote%.*}
  echo "$remote: $url -> $new_url"

  if [ "$dry_run" == false ]; then
    git config --replace-all --fixed-value "$key" "$new_url" "$url"
  fi
done <<< "$config_entries"
