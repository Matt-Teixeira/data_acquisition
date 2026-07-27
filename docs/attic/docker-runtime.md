> **DEPRECATED (2026-07-27):** describes the pre-vendoring / Dockerfile.runtime / host-mounted-entrypoint era and contradicts the current design. Kept for history only. Current guide: [docker_server_full_setup_2.0.md](../docker_server_full_setup_2.0.md).

## Runtime Container Overview

This project uses two key files to shape the runtime Docker image: `docker/Dockerfile.runtime` and `docker/entrypoint.sh`. Together they install the tooling your data acquisition jobs need, set up user and permission defaults, and prepare SSH credentials at container start.

### `docker/Dockerfile.runtime`
- **Base image:** Starts from `node:lts`.
- **System tools:** Installs `lftp`, `rsync`, `ca-certificates`, `sshpass`, `mdbtools`, and `expect` (and then cleans the apt cache).
- **lftp defaults:** Writes `/etc/lftp.conf` to auto-accept host keys and enable older SSH algorithms required by legacy GE devices.
- **Docker group alignment:** Accepts `DOCKER_GID` (defaults to `995`) and ensures a `docker` group exists with that GID so the container’s group matches the host and can talk to the Docker socket.
- **Built-in users:** Creates two users with the `docker` primary group: `svcDev` (uid 999) and `hostUser` (uid 1003) to mirror common host UIDs.
- **Cooperative umask:** Adds `umask ${UMASK:-0002}` to login, interactive, and non-interactive shells so files are group-writable by default (overridable via `UMASK`).
- **Entrypoint wiring:** Copies `docker/entrypoint.sh` into `/usr/local/bin`, makes it executable, and sets it as `ENTRYPOINT`.
- **Runtime defaults:** Sets `WORKDIR` to `/workspace` and `NPM_CONFIG_CACHE` to `/tmp/.npm`. It intentionally does not set a default `USER`; Compose chooses the user when starting the service.

### `docker/entrypoint.sh`
- **Purpose:** Wrapper that handles SSH credentials before and after running the main container command.
- **Bundle source:** Looks for `/opt/ssh_bundles/data_acquisition`. If present, copies its contents into the current user’s `~/.ssh` and applies restrictive permissions (700 for the directory, 600 for `mmb_google_deb` if it exists).
- **Command execution:** Logs and executes the container’s command (`"$@"`) and preserves its exit code.
- **Persist new hosts:** After the command finishes, if `known_hosts` exists it copies it back into the SSH bundle so newly accepted host keys persist between runs.
