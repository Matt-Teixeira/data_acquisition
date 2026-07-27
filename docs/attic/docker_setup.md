> **DEPRECATED (2026-07-27):** describes the pre-vendoring / Dockerfile.runtime / host-mounted-entrypoint era and contradicts the current design. Kept for history only. Current guide: [docker_server_full_setup_2.0.md](../docker_server_full_setup_2.0.md).

# Docker Workspace
- Compose defines two services: `app` (vanilla `node:lts`) and `app_tools` (built from `docker/Dockerfile.runtime` with `lftp`/`rsync` plus pre-created `svcDev` and `hostUser` users in the `docker` group).
- Both services mount the repository at `/workspace`, reuse host-cached `node_modules`, and share an external Redis network configured through `.env` (`REDIS_HOST`, `REDIS_PORT`).
- Container homes are pointed at `/tmp`, npm caches into `/tmp/.npm`, and `UMASK=0002` is enforced via `/etc/profile.d/umask.sh` so files created from the container remain group-writeable on the host.

## README Highlights
- Clone `hhm_data_acquisition` alongside the shared `utils` repo, update global git config if needed, and populate `.env` with the required secrets before running containers.
- Align database access by syncing the refined `pgPool.js` configuration and execute `run_scripts/update_db_creds.sh` (uses `node:16.20.2`) to refresh encrypted credentials.
- Prepare host permissions: create `files/`, run `chgrp -R docker .`, and apply group-write plus setgid/ACL hints so both the host user and `svc-dev` can read/write shared artifacts.
- When ready, build the tooling image with `docker compose build app_tools`, then run jobs via `docker compose run --rm app_tools bash -lc "<npm command>"`, optionally prefacing with `npm ci --omit=dev` for clean installs.
- Open README TODO: adjust log output paths so Docker runs write to `/opt/run-logs/${APP_NAME}` while non-Docker workloads continue using the relative `./utils/logger/` directory.

## Host Prerequisites
- Ensure compose bind mounts exist and are writable: `/opt/resources/node_mod_cache/dev/data_acquisition` for `node_modules` caching and `/opt/run-logs/data_acquisition` for central logs.
- If the host Docker group uses a different GID, pass `--build-arg DOCKER_GID=<gid>` when building `app_tools` and adjust `.env` `APP_UID`/`APP_GID` so container users map cleanly to host ownership.
- Confirm an external Docker network named `redis-admin_redis_net` (or update the compose file) is available, allowing containers to reach the shared Redis instance via `host.docker.internal`.

## Typical Workflow
- Build the tooling image when `Dockerfile.runtime` changes: `docker compose build app_tools`.
- Start the runtime container for interactive development: `docker compose up app` (add `-d` to detach).
- Run one-off CLI tasks with the richer toolset: `docker compose run --rm app_tools <command>`.
