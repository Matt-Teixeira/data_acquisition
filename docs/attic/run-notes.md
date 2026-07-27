> **DEPRECATED (2026-07-27):** describes the pre-vendoring / Dockerfile.runtime / host-mounted-entrypoint era and contradicts the current design. Kept for history only. Current guide: [docker_server_full_setup_2.0.md](../docker_server_full_setup_2.0.md).

# Runtime Image (`docker/Dockerfile.runtime`)

`app_tools` builds from `docker/Dockerfile.runtime`, which extends `node:lts` and pre-installs the system packages used by data jobs.

## Build the image

```sh
docker compose build app_tools
```

## Run a job

Use the runtime image through the `app_tools` service:

```sh
docker compose run --rm app_tools bash -lc "npm run <job_name>"
```

RUN ON FIRST DEPLOY TO NUKE AND UPDATE node_moduels CACHE: fresh install before running the job

```sh
docker compose run --rm app_tools bash -lc "npm ci --omit=dev && npm run <job_name>"
# or
docker compose run --rm app_tools bash -lc "npm ci --omit=dev --no-audit --no-fund && npm run <job_name>"
```

### Command breakdown

- `--rm`: remove the container when it exits; the image remains.
- `app_tools`: the compose service that defines the runtime image, mounts, and environment.
- `bash -lc`: run `bash` as the entry process, loading login config (`-l`) and executing the provided command string (`-c`); ensures PATH works as expected.
- `npm ci --omit=dev`: clean install using `package-lock.json`, skipping `devDependencies`.
- `npm run <job_name>`: execute the `job_name` script defined in `package.json`; runs only if the install step succeeds.
