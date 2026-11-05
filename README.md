# mizan-ansible

Ansible roles that prepare a [mizan-v2](https://github.com/rhorba/mizan-v2) node. They replace
the `runcmd` block of the Terraform cloud-init (Ubuntu 24.04 on OCI Ampere A1), so the node
setup becomes repeatable, reviewable and testable instead of a one-shot boot script.

| Role | What it does |
|------|--------------|
| `base` | Base packages, unattended security upgrades, host iptables opened (the VCN security list is the firewall), sshd hardening validated with `sshd -t` before it is applied |
| `users` | Operator accounts with locked passwords and key-only SSH (`exclusive` keys), offboarding with `state: absent`, scoped `NOPASSWD` sudo for one group, checked with `visudo` before it is applied |
| `docker` | Docker Engine from the official apt repo (deb822, arm64/amd64), optional users in the `docker` group |
| `k3s` | k3s pinned to `k3s_version` with secrets encryption; cluster token from Ansible Vault (kept out of logs); reinstalls only when the version differs, then waits for the node to be Ready |

## Run the lab

```bash
python3 -m venv .venv && . .venv/bin/activate   # or any venv
pip install "ansible-core>=2.16,<2.18" ansible-lint
ansible-galaxy collection install -r requirements.yml -p ./collections
ansible-lint                    # production profile
scripts/lab-up.sh               # Ubuntu 24.04 container target
scripts/idempotency.sh          # 2 runs; the second must report changed=0
molecule test                   # create, converge, idempotence, verify, destroy
```

## Secrets (Ansible Vault)

`k3s_token` is read from `vault_k3s_token` in an encrypted `group_vars/mizan_nodes/vault.yml`.

- **Lab:** `inventories/lab/group_vars/mizan_nodes/vault.yml` is encrypted with a throwaway,
  lab-only password committed as `inventories/lab/vault-pass.lab`, so CI and Molecule can
  exercise the full Vault path. It protects nothing real.
- **Real node:** create `inventories/oci/group_vars/mizan_nodes/vault.yml` with
  `ansible-vault create`, keep the password outside the repo (`--vault-password-file ~/.vault-pass`).
  Both the OCI vars and vault files are git-ignored.
- `scripts/check-vault-encrypted.sh` fails CI if any committed `vault.yml` is plain text.

## CI

GitHub Actions (`.github/workflows/ci.yml`) on every push and pull request:
1. **lint**: vault files encrypted, `yamllint`, `ansible-lint` production profile
2. **molecule**: Ubuntu 24.04 container, converge, a second run that must change nothing,
   then `verify.yml` (packages, pinned k3s version, operator account and group, offboarded
   account removed, a single authorized key, sudoers file valid and `0440`, Vault token loaded)

The container lab proves install and idempotency. Services (Docker, k3s, sshd, iptables)
only start on a real VM:

```bash
multipass launch 24.04 --name mizan-vm --cpus 2 --memory 4G --disk 15G
# copy the repo into the VM, then inside it:
scripts/vm-run.sh   # installs Ansible, run 1, run 2 (changed=0), playbooks/verify-services.yml
```

`verify-services.yml` checks what a container cannot: ssh (socket-activated on 24.04),
Docker and k3s running and enabled, the effective `sshd -T` settings, the k3s node
Ready, the Vault token in the k3s service environment, `docker run hello-world`, and
that `deploy` gets only the scoped sudo commands.

Last real-VM result (Ubuntu 24.04, Multipass/Hyper-V): run 1 `changed=14 failed=0`,
run 2 `changed=0`, verify `ok=14 failed=0`.

For the cloud node, copy `inventories/oci/hosts.yml.example` to `hosts.yml`.

## Roadmap

- [x] Part 1: base / docker / k3s roles, idempotent, ansible-lint production profile
- [x] Part 2: `users` role, Molecule scenario + GitHub Actions (lint, converge, idempotence, verify), Ansible Vault for the k3s token
- [x] Part 2b: real VM run (Multipass), services started and checked; `force_handlers` so a failed run cannot drop the iptables/ssh handlers
- [ ] Part 3: Rocky / Alma (RHEL family) support
