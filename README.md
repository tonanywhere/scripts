- Create syslink on ~/.local/ for all scrips

```
ln -sfn <full_script_path> ~/.local/<script_name>
chmod +x <script name> 
```

## Daily AI tools updater

See [ai-tools/README.md](ai-tools/README.md).

## GitHub owner rewrite

`update-git-remote.sh [--dry-run]` rewrites the GitHub owner in every remote URL of the current repo; `update-all-remotes.sh [--dry-run]` runs it in every repo under `ROOTS` (default `~/code/ton-anywhere ~/code/open-source`). Env: `OLD_USERS` (default `"ton-anywhere APonce911"`), `NEW_USER` (default `tonanywhere`), `GITHUB_HOSTS` (default `github.com`, add SSH host aliases). Tests: `bash test/update-git-remote.test.sh`, `bash test/update-all-remotes.test.sh`.
