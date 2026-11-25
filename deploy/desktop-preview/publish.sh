#!/usr/bin/env bash
set -euo pipefail
root=/var/www/crabsense-desktop-preview
[[ "$GITHUB_SHA" =~ ^[0-9a-f]{40}$ ]]
[[ "$GITHUB_RUN_ID" =~ ^[0-9]+$ && "$GITHUB_RUN_ATTEMPT" =~ ^[0-9]+$ ]]
[[ "$SSH_HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]]
[[ "$SSH_USER" =~ ^[a-z_][a-z0-9_-]*$ && "$SSH_USER" != root ]]
id="$GITHUB_SHA-$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"
destination="$SSH_USER@$SSH_HOST"
opts=(-i "$HOME/.ssh/desktop-preview-key" -o "UserKnownHostsFile=$HOME/.ssh/desktop-preview-known-hosts" -o StrictHostKeyChecking=yes -o BatchMode=yes -o ConnectTimeout=15)
main_sha() { gh api "repos/$GITHUB_REPOSITORY/git/ref/heads/main" --jq '.object.sha'; }
if [ "$(main_sha)" != "$GITHUB_SHA" ]; then
  echo 'Skipping stale main revision.'
  exit 0
fi
ssh "${opts[@]}" "$destination" "test -d '$root/incoming' && test -d '$root/releases' && { test ! -e '$root/current' || test -L '$root/current'; }"
scp "${opts[@]}" "$RUNNER_TEMP/preview-package/desktop-preview.tar.gz" "$destination:$root/incoming/$id.tar.gz"
if [ "$(main_sha)" != "$GITHUB_SHA" ]; then
  ssh "${opts[@]}" "$destination" "rm -f '$root/incoming/$id.tar.gz'"
  echo 'Skipping revision superseded during upload.'
  exit 0
fi
previous=$(ssh "${opts[@]}" "$destination" bash -s -- "$id" "$GITHUB_SHA" <<'REMOTE'
set -euo pipefail
root=/var/www/crabsense-desktop-preview
id=$1
sha=$2
archive="$root/incoming/$id.tar.gz"
release="$root/releases/$id"
trap 'rm -f -- "$archive"' EXIT
mkdir "$release"
tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$release"
test -s "$release/index.html"
test -s "$release/main.dart.js"
python3 - "$release/version.json" "$sha" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    assert json.load(f)['commit'] == sys.argv[2]
PY
chmod -R a+rX "$release"
previous=$(readlink "$root/current" || true)
ln -s "releases/$id" "$root/.current-$id"
mv -Tf "$root/.current-$id" "$root/current"
printf '%s' "$previous"
REMOTE
)
# Smoke-test the actual protected HTTPS site, not just the copied files.
if status=$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' "$ORIGIN/") &&
   [ "$status" = 401 ] &&
   curl -fsS --max-time 20 --user "$SMOKE_USER:$SMOKE_PASSWORD" "$ORIGIN/version.json" |
     python3 -c 'import json,os,sys; sys.exit(0 if json.load(sys.stdin).get("commit")==os.environ["GITHUB_SHA"] else 1)'; then
  echo "Deployed Desktop Preview revision $GITHUB_SHA to $ORIGIN"
else
  echo 'Smoke test failed. Restoring previous preview release.'
  # Only restore a symlink created by our release workflow.
  [[ -z "$previous" || "$previous" =~ ^releases/[0-9a-f]{40}-[0-9]+-[0-9]+$ ]]
  ssh "${opts[@]}" "$destination" bash -s -- "$id" "$previous" <<'REMOTE'
set -euo pipefail
root=/var/www/crabsense-desktop-preview
id=$1
previous=${2:-}
if [ "$(readlink "$root/current")" != "releases/$id" ]; then exit 1; fi
if [ -n "$previous" ]; then
  ln -s "$previous" "$root/.rollback-$id"
  mv -Tf "$root/.rollback-$id" "$root/current"
else
  rm "$root/current"
fi
REMOTE
  exit 1
fi
