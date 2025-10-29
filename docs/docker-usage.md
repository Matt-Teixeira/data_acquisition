# Docker Usage Guide

This project relies on Docker both for day-to-day development tasks and for running data-acquisition jobs in a reproducible container. The configuration is spread across the main compose file, a runtime Dockerfile used to bake in extra tooling, and a handful of helper scripts under `run_scripts/`.

## Compose Services

The primary entry point is `docker-compose.yaml`, which defines two services and a couple of reusable anchors:

- `x-common-env` injects environment variables from `.env`, binds `host.docker.internal`, and forwards a writable npm cache inside the container.
- `x-common-mounts` sets the working directory to `/workspace`, mounts the repository into that path, and binds the shared host cache `/opt/resources/node_mod_cache/data_acq` to `/workspace/node_modules` so dependencies persist between runs.

With those anchors applied, the compose file exposes two services:

- `app`: runs against the upstream `node:lts` image; best when you only need Node.js.
- `app_tools`: builds from `docker/Dockerfile.runtime` so that extra CLI tools (for example `lftp`) are always available without reinstalling.

Both services inherit `.env`, so updates to that file immediately affect container runs.

## Runtime Image (`docker/Dockerfile.runtime`)

`app_tools` builds from `docker/Dockerfile.runtime`, which extends `node:lts` and pre-installs system packages used by data jobs:

```
apt-get install -y --no-install-recommends lftp rsync ca-certificates
```

Because these tools are baked into the image, repeated runs through `docker compose` or `docker run` start quickly and do not re-run `apt-get` unless the image is rebuilt.

## Run Scripts (`run_scripts/`)

The shell helpers wrap `docker run` to give repeatable entry points outside of compose:

- `run_scripts/start.sh` mounts the repo at `/usr/src/app`, loads `.env`, and runs `npm ci --omit=dev` followed by `npm run start` inside the stock `node:lts` image.
- `run_scripts/ge_ct.sh` does the same, but installs `lftp` on-the-fly (when you are not using the prebuilt `app_tools` image), runs `npm run ge_ct`, and finishes with a `chown` so that files created in the container remain owned by the invoking user.
- `run_scripts/update_db_creds.sh` targets a specific Node version (`node:16.20.2`) to run `npm run update_db_creds`, again wiring in the repository, `.env`, and host networking.

Choose these scripts when you want a simple, reproducible invocation without remembering the full `docker run` flags.

## `docker-config.yaml`

The repository does not currently ship a `docker-config.yaml`. If your workflow relies on an additional Docker or Compose configuration file by that name (for example to supply environment-specific overrides), add it alongside `docker-compose.yaml` and reference it via `docker compose -f docker-compose.yaml -f docker-config.yaml ...`. Until such a file exists, only the compose files discussed above take effect.

## Routine Invocation

To run the GE CT acquisition job with the tooling baked into `app_tools`, use:

```
docker compose run --rm app_tools bash -lc "npm ci --omit=dev && npm run ge_ct"
```

This matches the behaviour in `run_scripts/ge_ct.sh` but relies on the compose-defined image (which already has `lftp`, `rsync`, and CA certificates installed). Switching the command after `bash -lc` lets you call any other npm script in the same environment.
