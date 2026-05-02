# OMSCS Dev VM on Azure

I'm on an M-series Mac, and my course's x86 Docker image runs under
emulation -- slow when it works, broken when it doesn't. So I built
this: a small Azure VM that runs the container and lets CLion drive
it over SSH like a local toolchain. Real x86, no emulation.

Setup takes about 10 minutes. The VM auto-shuts down each night, so
idle costs run a few bucks a month.

## Before you start

You need:

- An Azure subscription. Students get $100 in credit at https://azure.microsoft.com/free/students.
- Homebrew. https://brew.sh
- `az` CLI. `brew install azure-cli`
- `yq`. `brew install yq`
- An SSH keypair at `~/.ssh/id_ed25519`. Run `ssh-keygen -t ed25519` if you don't have one.

## Log in to Azure

```bash
az login
```

A browser window opens. Sign in, then return to the shell. Your
subscriptions are listed. If more than one, pick the one to use:

```bash
az account set --subscription "Your Subscription Name"
```

## Clone the repo

```bash
git clone git@github.com:kylemart/gt-omscs-infra.git
cd gt-omscs-infra
```

## Deploy

```bash
./deploy.sh
```

First run takes about 5 minutes (Docker install on the VM, then the
initial image build). Later runs are closer to 30 seconds and only redo
what changed.

By default this creates a `Standard_B2s` VM in `rg-omscs-eastus2`
(region `eastus2`). See [Overrides](#overrides) to change any of that.

When the script returns, it prints the FQDN. Confirm what's running:

```bash
ssh omscs@<fqdn> 'cd containers && docker compose ps'
```

You should see one row per container with state `running`.

## Connect CLion

Point CLion at `<fqdn>` on your container's host port (the `<port>:22`
mapping in `containers/docker-compose.yml`), logging in as `root`. CLion
takes over from there: source sync, builds, debug.

[CLION.md](CLION.md) walks through the setup.

---

## Overrides

Defaults live in `deploy.sh`. To change them, copy `.env.example` to
`.env` and uncomment the values you want:

```bash
cp .env.example .env
$EDITOR .env
./deploy.sh
```

For one-off runs, set env vars on the command line instead:

```bash
RG=rg-omscs-test-eastus2 ./deploy.sh
```

Inline values only apply to keys NOT uncommented in `.env`.

| Environment variable | Default value | Purpose |
|---|---|---|
| `AUTO_SHUTDOWN_EMAIL` | empty | Email for the 30-minute advance notice. Empty = no email. |
| `AUTO_SHUTDOWN_ENABLED` | `true` | Daily auto-shutdown schedule. |
| `AUTO_SHUTDOWN_TIME` | `1900` | Local time, `HHmm` 24-hour. |
| `AUTO_SHUTDOWN_TIME_ZONE` | `UTC` | Windows time-zone id. |
| `DNS_LABEL` | _required_ | DNS label prepended to `<LOCATION>.cloudapp.azure.com` to form the FQDN. |
| `LOCATION` | `eastus2` | Azure region. |
| `RG` | `rg-omscs-$LOCATION` | Resource group name. |
| `SSH_KEY` | `~/.ssh/id_ed25519.pub` | Public key embedded in the VM's `authorized_keys`. |
| `SSH_SOURCE_ADDRESS_PREFIX` | `*` | NSG inbound source. Lock to your IP for security. |
| `VM_NAME` | `omscs-dev-vm-$LOCATION` | Used to derive NIC, NSG, IP, and disk names. |
| `VM_SIZE` | `Standard_B2s` | VM SKU. |

## Tear down

```bash
az group delete --name rg-omscs-eastus2 --yes --no-wait
```

Wipes the resource group and everything in it.

## See also

- [containers/README.md](containers/README.md) -- adding, removing, and iterating on course containers.
- [CLION.md](CLION.md) -- CLion remote toolchain setup.
