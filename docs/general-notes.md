# Data Acquisition App Notes

## Repository Setup

1. Clone the main application repository:
   ```sh
   git clone git@github.com:Matt-Teixeira/hhm_data_acquisition.git
   ```
2. Clone the shared utilities repository:
   ```sh
   git clone git@github.com:AvanteHS-RTT/utils.git
   ```
3. Configure Git:
   ```sh
   git config --global user.email "matt.teixeira@avantehs.com"
   git config --global user.name "Matt Teixeira"
   ```
4. Update environment files (`.env`, etc.); redact secrets before sharing.
5. Update `pgPool.js` using the `PROD_staging-docker` branch changes.
6. Refresh database credentials with the Node 16.20.2 tooling:
   ```sh
   ./run_scripts/update_db_creds.sh
   ```

## Run Notes

- Jobs currently execute via shell scripts that install `rsync`, `lftp`, and other tools as needed.
- Those scripts target the `node:lts` image to ensure consistent runtime behavior.

## Docker Runtime Usage

`app_tools` builds from `docker/Dockerfile.runtime`, which extends `node:lts` and pre-installs system packages used by the jobs.

### Build the runtime image

```sh
docker compose build app_tools
```

### Run a job

```sh
docker compose run --rm app_tools bash -lc "npm run <job_name>"
```

To reinstall dependencies before the run:

```sh
docker compose run --rm app_tools bash -lc "npm ci --omit=dev && npm run <job_name>"
```

**Command breakdown**
- `--rm`: remove the container when it exits; the Docker image persists.
- `app_tools`: compose service that defines the runtime image, mounts, and environment.
- `bash -lc`: launch a login shell (`-l`) and execute the provided command (`-c`); keeps PATH resolution predictable.
- `npm ci --omit=dev`: clean install from `package-lock.json`, skipping `devDependencies`.
- `npm run <job_name>`: execute the desired script from `package.json`; runs only if the install step succeeds.

## Volumes and Caching

1. Project source (live edits on host reflected in the container):
   ```
   ./:/workspace
   ```
2. Cache `node_modules` on the host so installs persist between runs:
   - Dev:
     ```
     /opt/resources/node_mod_cache/dev/data_acquisition:/workspace/node_modules
     ```
   - Live (adjust path per environment: staging, prod, etc.):
     ```
     /opt/resources/node_mod_cache/staging/data_acquisition:/workspace/node_modules
     ```
3. Centralized run logs on the host (ensure the directory exists and is writable):
   ```
   /opt/run-logs/data_acquisition:/opt/run-logs/data_acquisition
   ```

## TODO

- Update the utils app `log.js` path handling to support Docker and non-Docker runs:
  - Non-Docker:
    ```js
    `./utils/logger/${process.env.APP_NAME}-log.${process.env.LOGGER}.${run_id}.js`
    ```
  - Docker (local build):
    ```js
    `./utils/logger/${process.env.APP_NAME}-log.${process.env.LOGGER}.${run_id}.js`
    ```
  - Docker (live/staging/prod):
    ```js
    `/opt/run-logs/${process.env.APP_NAME}/${process.env.APP_NAME}-log.${process.env.LOGGER}.${run_id}.js`
    ```
