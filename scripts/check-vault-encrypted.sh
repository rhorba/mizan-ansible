#!/usr/bin/env bash
# Fail if any vault.yml in the repo is committed in plain text.
set -euo pipefail
status=0
while IFS= read -r f; do
  if ! head -n 1 "$f" | grep -q '^\$ANSIBLE_VAULT;'; then
    echo "NOT ENCRYPTED: $f"; status=1
  fi
done < <(git ls-files '*vault.yml' '*vault.yaml')
[ "$status" -eq 0 ] && echo "all vault files encrypted"
exit "$status"
