# OMSCS Infrastructure

I use an M-series Mac. I love it. It loves me. We're a happy family. ❤️

But... many OMSCS courses only support students with x64-based machines. 💔

While emulation 
(via Docker and Rosetta) has been enough to get through most course assignments, taking 
GIOS finally pushed me towards setting up a proper toolchain for native x64 development. 
This repository contains instructions on how to acheive the same setup I did. It's quick,
easy and for most students completely free! 

By the end you'll have a remote VM with containerized environments you can hook up to IDEs 
like CLion for native-feeling project development. 

## Links

- [Deployment](docs/DEPLOY.md) (start here)
- [CLion setup](docs/CLION.md)
- [Manage environments](docs/ENVIRONMENTS.md)
- [Architecture](docs/ARCHITECTURE.md)

## Quickstart

```bash
az login
cp .env.example .env  # set DNS_LABEL, then save
./deploy.sh
ssh omscs@<fqdn> 'cd containers && docker compose ps'
```

Full deployment instructions [here](docs/DEPLOY.md).
