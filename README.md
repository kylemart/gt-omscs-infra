# OMSCS Infrastructure

I use an M-series Mac. I love it. It loves me. We're a happy family. ❤️

But... many OMSCS courses only support students with x64-based machines. 💔

While emulation 
(via Docker and Rosetta) has been enough to get through most course assignments, taking 
GIOS finally pushed me towards setting up a proper toolchain for native x64 development. 
This repository contains instructions on how to acheive the same setup I did. It's quick,
easy and for most students completely free! By the end you'll have a remote VM with 
containerized environments you can hook up with IDEs like CLion for native-feeling project 
development. 

## Before you start

You need:

- An Azure subscription. As students we get $100 in credit at https://azure.microsoft.com/free/students.
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

## Configure

Copy [`.env.example`](.env.example) to `.env` and set `DNS_LABEL`
(required). Uncomment any other values you want to change; descriptions
are in the file.

```bash
cp .env.example .env
$EDITOR .env
```

## Deploy

```bash
./deploy.sh
```

First run takes about 5 minutes (Docker install on the VM, then the
initial image build). Later runs are closer to 30 seconds and only redo
what changed.

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

## Tear down

When you're done with the VM and want to wipe everything, delete the
resource group. That removes the VM, disk, networking, and the group
itself.

```bash
az group delete --name rg-omscs-eastus2 --yes --no-wait
```

## See also

- [ARCHITECTURE.md](ARCHITECTURE.md) -- why the setup is built this way and what a deploy actually does.
- [containers/README.md](containers/README.md) -- adding, removing, and iterating on course containers.
- [CLION.md](CLION.md) -- CLion remote toolchain setup.
