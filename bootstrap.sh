#!/bin/bash
# Runs on the VM (as root) once via the CSE: installs Docker and prepares
# the fixed authorized_keys path that docker-compose.yml bind-mounts.
#
# Container files (docker-compose.yml, Dockerfiles) are NOT shipped through
# this script. deploy.sh rsyncs them onto the VM and runs `docker compose up`
# over SSH after this finishes.

set -euo pipefail

# Azure provisions the admin user with UID 1000 on Ubuntu.
ADMIN_USERNAME=$(id -un 1000)

# `command -v` guard makes re-runs a no-op once Docker is installed.
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    usermod -aG docker "$ADMIN_USERNAME"
fi

# Fixed path means docker-compose.yml doesn't have to interpolate the admin
# user's name into the bind-mount source.
mkdir -p /var/lib/dev-vm
ln -sf "/home/$ADMIN_USERNAME/.ssh/authorized_keys" /var/lib/dev-vm/authorized_keys
