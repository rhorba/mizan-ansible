#!/usr/bin/env bash
# Start a throwaway Ubuntu 24.04 target with Python for Ansible.
set -euo pipefail
docker rm -f mizan-lab >/dev/null 2>&1 || true
docker run -d --name mizan-lab ubuntu:24.04 sleep infinity >/dev/null
docker exec mizan-lab bash -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3 >/dev/null'
echo "mizan-lab ready"
