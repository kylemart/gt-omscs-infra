#!/bin/bash
# Provision (or update) the OMSCS dev VM via az + Bicep, then sync containers/
# onto it and bring services up. Run `az login` first if you haven't. See
# README for env-var overrides.

set -euo pipefail

require() { command -v "$1" >/dev/null || { echo "error: $1 not installed ($2)" >&2; exit 1; }; }
require brew  "see https://brew.sh"
require az    "brew install azure-cli"
require yq    "brew install yq"
require rsync "brew install rsync"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Sourced before defaults so uncommented values win; CLI inline overrides
# (`RG=foo ./deploy.sh`) only work for keys NOT in .env.
[[ -f "$SCRIPT_DIR/.env" ]] && source "$SCRIPT_DIR/.env"

# Defaults live here so the Bicep template stays values-free.
LOCATION="${LOCATION:-eastus2}"
RG="${RG:-rg-omscs-$LOCATION}"
VM_NAME="${VM_NAME:-omscs-dev-vm-$LOCATION}"
VM_SIZE="${VM_SIZE:-Standard_B2s}"
DNS_LABEL="${DNS_LABEL:-$VM_NAME}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519.pub}"
SSH_SOURCE_ADDRESS_PREFIX="${SSH_SOURCE_ADDRESS_PREFIX:-*}"
AUTO_SHUTDOWN_ENABLED="${AUTO_SHUTDOWN_ENABLED:-true}"
AUTO_SHUTDOWN_TIME="${AUTO_SHUTDOWN_TIME:-1900}"
AUTO_SHUTDOWN_TIME_ZONE="${AUTO_SHUTDOWN_TIME_ZONE:-UTC}"
AUTO_SHUTDOWN_EMAIL="${AUTO_SHUTDOWN_EMAIL:-}"

# Must match main.bicep's `adminUsername` var.
ADMIN_USERNAME="omscs"

# Compose is the source of truth: each "<port>:22" becomes an NSG rule.
CONTAINER_SSH_PORTS=$(yq -o=json -I=0 \
    '[.services[].ports[] | select(test(":22$")) | sub(":.*", "")]' \
    "$SCRIPT_DIR/containers/docker-compose.yml")

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

az group create --name "$RG" --location "$LOCATION" -o none

echo "==> Provisioning VM in $RG..."
VM_HOST=$(az deployment group create \
    --resource-group "$RG" \
    --name "omscs-vm-$(date +%Y%m%d-%H%M%S)" \
    --template-file "$SCRIPT_DIR/main.bicep" \
    --parameters \
        vmName="$VM_NAME" \
        location="$LOCATION" \
        vmSize="$VM_SIZE" \
        dnsLabel="$DNS_LABEL" \
        sshPublicKey="$(cat "$SSH_KEY")" \
        sshSourceAddressPrefix="$SSH_SOURCE_ADDRESS_PREFIX" \
        containerSshPorts="$CONTAINER_SSH_PORTS" \
        autoShutdownEnabled="$AUTO_SHUTDOWN_ENABLED" \
        autoShutdownTime="$AUTO_SHUTDOWN_TIME" \
        autoShutdownTimeZone="$AUTO_SHUTDOWN_TIME_ZONE" \
        autoShutdownEmail="$AUTO_SHUTDOWN_EMAIL" \
    --query 'properties.outputs.fqdn.value' -o tsv)

echo "==> Syncing containers/ to $VM_HOST..."
rsync -az --delete -e "ssh $SSH_OPTS" \
    "$SCRIPT_DIR/containers/" "$ADMIN_USERNAME@$VM_HOST:~/containers/"

echo "==> Bringing services up..."
ssh $SSH_OPTS "$ADMIN_USERNAME@$VM_HOST" \
    'cd ~/containers && docker compose up -d --build --remove-orphans'

echo "==> Done. Connect: ssh $ADMIN_USERNAME@$VM_HOST"
