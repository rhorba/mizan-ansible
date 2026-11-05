#!/usr/bin/env bash
# Run INSIDE a fresh Ubuntu 24.04 VM (e.g. `multipass launch 24.04 --name mizan-vm`):
# installs Ansible, lets the VM SSH to itself, applies site.yml twice (idempotence),
# then verifies the running services. Lab Vault password only.
set -euo pipefail
cd "$(dirname "$0")/.."
sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-venv >/dev/null
[ -d ~/ansible-venv ] || python3 -m venv ~/ansible-venv
. ~/ansible-venv/bin/activate
pip install -q "ansible-core>=2.16,<2.18"
ansible-galaxy collection install -r requirements.yml -p ./collections >/dev/null
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
grep -qf ~/.ssh/id_ed25519.pub ~/.ssh/authorized_keys || cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
ssh-keyscan 127.0.0.1 >> ~/.ssh/known_hosts 2>/dev/null || true
export ANSIBLE_VAULT_PASSWORD_FILE=inventories/lab/vault-pass.lab
export ANSIBLE_NOCOLOR=1
# Full logs go to ~/vm-logs; on failure the failing task is printed.
mkdir -p ~/vm-logs
run() {
  local name=$1; shift
  if ansible-playbook -l mizan-vm "$@" > ~/vm-logs/"$name".log 2>&1; then
    grep -A2 'PLAY RECAP' ~/vm-logs/"$name".log | tail -n 1
  else
    grep -B2 -A12 'fatal:' ~/vm-logs/"$name".log; exit 1
  fi
}
echo "== run 1"; run run1 site.yml
echo "== run 2 (must be changed=0)"; run run2 site.yml
grep -Eq 'changed=0 +unreachable=0 +failed=0' ~/vm-logs/run2.log || { echo "NOT idempotent"; exit 1; }
echo "== verify services"; run verify playbooks/verify-services.yml
