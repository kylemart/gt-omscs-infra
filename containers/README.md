# Course containers

One folder per course, one service in `docker-compose.yml`, one host
port mapped to the container's `:22`. Add a course by adding a folder
and a service block; remove one by deleting them.

## Adding a container

Create `<service>/` with a `Dockerfile` for the course environment.
`gios-env/Dockerfile` is a reasonable starting point.

Add a matching service block to `docker-compose.yml`, picking an unused
host port for the `<port>:22` mapping.

Run `./deploy.sh` from the repo root. The new port opens in the NSG and
the container is built and started on the VM. Existing containers keep
running.

## Removing a container

Delete `<service>/` and its service block from `docker-compose.yml`,
then run `./deploy.sh`. The directory is removed from the VM, the NSG
rule goes away, and the container is stopped and removed.

The image stays cached on the VM. `docker image prune` reclaims the
disk.

## Iterating on a container

Edit files in `<service>/` locally, then re-run `./deploy.sh` from the
repo root. Only changed bytes ship and only the affected service
rebuilds.

Don't edit on the VM directly -- redeploys mirror the local
`containers/` over it.
