#!/usr/bin/env bash
# Run site.yml twice; the second run must report changed=0.
set -euo pipefail
ansible-playbook site.yml
out=$(ansible-playbook site.yml)
echo "$out" | tail -n 4
echo "$out" | grep -Eq 'changed=0 +unreachable=0 +failed=0' || { echo "NOT idempotent"; exit 1; }
echo "idempotent: second run changed=0"
