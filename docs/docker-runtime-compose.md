# Docker Runtime and Compose Guide

This doc explains how the `docker/Dockerfile.runtime` image and `docker-compose.yaml` work together to support local development for the data acquisition app.

## Dockerfile.runtime

The runtime Dockerfile builds an extended Node.js image that bundles the extra CLI tools used by the project.

- **Base image**: Starts from `node:lts` to track the current long-term support release of Node.js.
- **CLI dependencies**: Installs `lftp`, `rsync`, and `ca-certificates` during build so every container created from this image already has the tools.
- **User mapping**: Accepts `APP_UID` and `APP_GID` build arguments (defaults to 1000) and makes sure there is an `app` user with those IDs. This keeps file ownership consistent between the host and bind-mounted files.
- **Workspace defaults**: Sets `/workspace` as the working directory and `/home/app` as the home directory so node commands run against the project tree. The container drops root privileges permanently by switching to the `app` user.

To build the image manually:

```bash
docker build \
  --build-arg APP_UID=$(id -u) \
  --build-arg APP_GID=$(id -g) \
  -t utility-app_tools:latest \
  -f docker/Dockerfile.runtime .
```

## docker-compose.yaml

The compose file defines two services that share a common configuration through compose anchors.

### Shared configuration

- **Environment file**: `env_file: .env` loads the project environment variables. Keys like `APP_UID` and `APP_GID` feed into the build arguments for the tooling image.
- **Extra hosts**: Adds `host.docker.internal` so containers can reach services running on the host (for example, a database exposed on `localhost`).
- **Runtime environment**: Forces `HOME` and `NPM_CONFIG_CACHE` into `/tmp` inside the container to avoid polluting the image with root-owned cache files.
- **Working directory and mounts**: Sets `working_dir: /workspace` and binds the local repository to that path. Additional mounts cache `node_modules` under `/opt/resources/node_mod_cache/...` and ship logs to `/opt/run-logs/data_acquisition`. These host paths must exist and be writable before running compose.

### Services

- **app**: A lightweight container that runs directly from the upstream `node:lts` image. It inherits the shared env and volume configuration and is ideal for quick Node.js tasks without extra tooling.
- **app_tools**: Builds from `docker/Dockerfile.runtime` to provide the CLI utilities and user mapping described earlier. The built image is tagged `utility-app_tools:latest`. The service inherits the same mounts and environment, so it can run the same workflows as `app` but with the additional tools available.

Use compose to build and run:

```bash
# Build the tooling image with the UID/GID in .env
docker compose build app_tools

# Run the basic Node container
docker compose run --rm app node -v

# Run the tooling container
docker compose run --rm app_tools bash
```

Because both services mount the project directory into `/workspace`, changes you make on the host are immediately visible inside the containers, and files created inside the containers carry your host UID/GID.
