# mizan-ansible

Ansible roles that prepare a [mizan-v2](https://github.com/rhorba/mizan-v2) node. They replace
the `runcmd` block of the Terraform cloud-init (Ubuntu 24.04 on OCI Ampere A1), so the node
setup becomes repeatable, reviewable and testable instead of a one-shot boot script.

| Role | What it does |
|------|--------------|
| `base` | Base packages, unattended security upgrades, host iptables opened (the VCN security list is the firewall), sshd hardening validated with `sshd -t` before it is applied |
| `docker` | Docker Engine from the official apt repo (deb822, arm64/amd64), optional users in the `docker` group |
| `k3s` | k3s pinned to `k3s_version` with secrets encryption; reinstalls only when the version differs, then waits for the node to be Ready |

## Run the lab

```bash
python3 -m venv .venv && . .venv/bin/activate   # or any venv
pip install "ansible-core>=2.16,<2.18" ansible-lint
ansible-galaxy collection install -r requirements.yml -p ./collections
ansible-lint                    # production profile
scripts/lab-up.sh               # Ubuntu 24.04 container target
scripts/idempotency.sh          # 2 runs; the second must report changed=0
```

The container lab proves install and idempotency. Services (Docker, k3s, sshd, iptables)
only start on a real VM: copy `inventories/oci/hosts.yml.example` to `hosts.yml`.

## Roadmap

- [x] Part 1: base / docker / k3s roles, idempotent, ansible-lint production profile
- [ ] Part 2: Molecule scenario + GitHub Actions (lint + converge + idempotence), Ansible Vault for secrets
- [ ] Part 3: Rocky / Alma (RHEL family) support
