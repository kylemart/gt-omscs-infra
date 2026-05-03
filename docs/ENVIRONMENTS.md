# Environments

One folder per course under `containers/`, one service in
`docker-compose.yml`, one host port mapped to the container's `:22`.
Each is tagged with a Compose profile so you can run only the ones
you need.

## Available environments

| Profile | Course | Port | Folder |
| --- | --- | --- | --- |
| `gios` | [CS 6200: Introduction to Operating Systems](https://omscs.gatech.edu/cs-6200-introduction-operating-systems) | 2222 | [gios-env](../containers/gios-env) |
| `sat` | [CS 6340: Software Analysis](https://omscs.gatech.edu/cs-6340-software-analysis) | 2223 | [sat-env](../containers/sat-env) |

## Enabling environments

Set `COMPOSE_PROFILES` in `.env` to a comma-separated list of profiles
(e.g. `COMPOSE_PROFILES=gios,sat`). Leaving it unset runs every
available profile. Re-run `./deploy.sh` to apply changes; environments
removed from the list are stopped on the VM.

## Adding an environment

Create `containers/<service>/` with a `Dockerfile` for the course.
`gios-env/Dockerfile` is a reasonable starting point.

Add a matching service block to `docker-compose.yml`, picking an unused
host port for the `<port>:22` mapping. Tag the service with a Compose
profile (`profiles: [<course>]`); `deploy.sh` discovers profiles from
the compose file, so the new environment is enabled by default.

Add a row to the table above, then run `./deploy.sh`. The new port
opens in the NSG and the container is built and started on the VM.
Existing environments keep running.

## Removing an environment

Delete `containers/<service>/` and its service block from
`docker-compose.yml`, then drop the row from the table above and run
`./deploy.sh`. The directory is removed from the VM, the NSG rule goes
away, and the container is stopped and removed.

The image stays cached on the VM. `docker image prune` reclaims the
disk.

## Modifying an environment

Edit files in `containers/<service>/` locally, then re-run `./deploy.sh`.
Only changed bytes ship and only the affected service rebuilds.

Don't edit on the VM directly; redeploys mirror the local `containers/`
over it.
