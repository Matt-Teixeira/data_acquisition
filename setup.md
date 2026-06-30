# CONVENTIONS (read first)

These apply throughout this guide. Set them once per shell before running the steps below.

```bash
# Environment this server runs as: DEV | STAGING | PROD
# Used for branch names and for the env-suffixed volume vars (e.g. NODE_MOD_CACHE_STAGING).
export ENV=STAGING
```

- **Branches.** Each app has a per-environment Docker branch named `<ENV>_docker`
  (`DEV_docker`, `STAGING_docker`, `PROD_docker`). Throughout this guide the clone
  steps use `${ENV}_docker`, so set `ENV` above to match the server you are building.
- **Vendored `utils`.** The shared `utils/` library (logger, db, vpn, sh helpers) is now
  **vendored directly into each app repo** and committed there. Do **not** `git clone`
  the `utils` repo separately anymore — it ships inside the app checkout. Older steps that
  cloned `AvanteHS-RTT/utils` and switched its branch are obsolete.
- **Per-app entrypoint.** The container user-drop entrypoint (gosu → `RUN_USER`) is now
  **baked into each app image** from a tracked `docker/entrypoint.sh` (or `entrypoint.sh`
  at the repo root). The old global `/opt/resources/entrypoint.sh` is **deprecated** — it
  is no longer mounted into containers. See the "Per-app entrypoint" section below.
- **Run logs.** Canonical location is `/opt/run-logs/<app>/`. The older
  `/opt/resources/run-logs/` tree is **deprecated** and should not be used for new apps.
- **Env-suffixed volume vars.** Volume path vars in each app's `.env` carry the
  environment as a suffix and must match `ENV`: e.g. on staging use
  `NODE_MOD_CACHE_STAGING` / `DATA_STORE_STAGING`; on dev use `NODE_MOD_CACHE_DEV` /
  `DATA_STORE_DEV`. `RUN_LOGS_DIR` points at `/opt/run-logs/<app>` regardless of env.

------------------------------------------------------------------------

# STEP 1: INSTALL DOCKER

## Note: If Docker has been installed on the server - follow the docker-disk-migration.md guide to move Docker's storage directory from /var/lib/docker to /mnt/sdc/docker

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- NEW: point Docker at the big disk BEFORE first start ---
# Prereq: a large data disk is mounted at /mnt/sdc (verify with `df -h | grep /mnt/sdc`).
# If your VM doesn't have a second disk, skip this block and use defaults.
sudo mkdir -p /mnt/sdc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
  "data-root": "/mnt/sdc/docker"
}
EOF
# ------------------------------------------------------------

sudo systemctl enable --now docker
sudo docker run hello-world
docker info | grep "Docker Root Dir"   # sanity check: /mnt/sdc/docker

```

# STEP 1.1 CREATE USERS

```bash
sudo adduser jonathan-pope
sudo usermod -aG docker jonathan-pope
source ~/.bashrc # *ONLY NEEDED IF PERFORMING SELF ADJUSTMENTS
docker run hello-world
CREATE SERVICE ACCOUT USER

sudo adduser \
--system \
--no-create-home \
--group \
--shell /usr/sbin/nologin \
svc
```

# STEP 1.2 SHARED RESOURCE PERMISSIONS

> **Canonical run-logs path is `/opt/run-logs/<app>/`.** A legacy
> `/opt/resources/run-logs/` tree may exist from an older layout — it is **deprecated**;
> do not create new app dirs there. Per-app log dirs are created in STEP 7.

```bash
# Create shared apps and run-logs directories
sudo mkdir -p /opt/run-logs
sudo chgrp docker /opt/run-logs
sudo chmod 2775 /opt/run-logs

sudo mkdir -p /opt/apps
sudo chgrp docker /opt/apps
sudo chmod 2775 /opt/apps

sudo mkdir -p /opt/resources
sudo chgrp docker /opt/resources
sudo chmod 2775 /opt/resources
```
# STEP 1.3 Update permissions via ACL

```bash
sudo apt install acl

sudo setfacl -d -m g:docker:rwX /opt/run-logs
sudo setfacl -m g:docker:rwX /opt/run-logs

sudo setfacl -d -m g:docker:rwX /opt/apps
sudo setfacl -m g:docker:rwX /opt/apps

sudo setfacl -d -m g:docker:rwX /opt/resources
sudo setfacl -m g:docker:rwX /opt/resources
```


# STEP 2: DATABASE INITIALIZATION

## Setup Summary

Image	postgres:16
Container name	pg_db
Port	5432 → 5432
Password	*****
Volume	Named volume postgres_data → /var/lib/postgresql/data
Restart policy	unless-stopped
Network	bridge (default)

### 2.1 Pull the image
```bash
docker pull postgres:16
```

### 2.2 Create the named volume
```bash
docker volume create postgres_data
```

### 2.3 Add docker network
```bash
docker network create pg_net
```
### 2.4 Confirm pg_db is attached
```bash
docker network inspect pg_net
```

### 2.5 Run the container
```bash
# With Shared Network
docker run -d \
  --name pg_db \
  --network pg_net \
  -e POSTGRES_PASSWORD=<paste_pass_here> \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:16
```

### 2.6 Create the database
The container starts with a default postgres database. You'll need to create the staging and/or dev databases that the app expects:

### - Install psql
```bash
sudo apt-get update && sudo apt-get install -y postgresql-client
```

### - Wait a few seconds for postgres to initialize, then:
```bash
docker exec -it pg_db psql -U postgres -c "CREATE DATABASE staging;"
docker exec -it pg_db psql -U postgres -c "CREATE DATABASE dev;"
``` 

### 5. Verify connectivity
```bash
psql -h localhost -p 5432 -U postgres -d postgres
```

------------------------------------------------------------------------

# GIT CONFIG
```bash
git config --global user.email "you.guy@avantehs.com"
git config --global user.name  "You Guy"
```
------------------------------------------------------------------------

------------------------------------------------------------------------

# STEP 3: REDIS CONTAINERS

This step provisions isolated dev, staging, and prod Redis instances.

### 3.1 Clone the Redis Admin Repository

``` bash
git clone git@github.com:Matt-Teixeira/redis-admin.git
cd redis-admin
```

### 3.2 Start the Redis Containers

``` bash
docker compose up -d
```

### 3.3 Verify Container Health

``` bash
docker compose ps
docker compose logs redis-PROD
```

# STEP 4:  STOP PROD JOBS HERE - MIGRATE PROD REDIS AND PROD DB STATE NOW

### 4.1 On Old Debian Instance
```bash
sudo docker exec -it redis-PROD redis-cli SAVE
sudo docker exec -it redis-PROD redis-cli CONFIG GET dir
sudo docker exec -it redis-PROD redis-cli CONFIG GET dbfilename

# You cannot scp directly from inside the container, so first copy it to the host machine:
sudo docker cp redis-PROD:/data/dump.rdb /tmp/redis-PROD-dump.rdb

# Now SCP from the host to the new server:
scp /tmp/redis-PROD-dump.rdb data-acqu-vm-dev:/tmp/
```

### 4.2 ON Destination Server
```bash
# Go to destination server
ssh data-acqu-vm-dev

# Then on the destination server:
docker stop redis-PROD && docker stop redis-STAGING && docker stop redis_dev-0-4

docker cp /tmp/redis-PROD-dump.rdb redis-PROD:/data/dump.rdb && docker cp /tmp/redis-PROD-dump.rdb redis-STAGING:/data/dump.rdb && docker cp /tmp/redis-PROD-dump.rdb redis_dev-0-4:/data/dump.rdb

docker start redis-PROD && docker start redis-STAGING && docker start redis_dev-0-4

# Verify
sudo docker exec -it redis-PROD redis-cli DBSIZE
sudo docker exec -it redis-STAGING redis-cli DBSIZE
```

------------------------------------------------------------------------

# STEP 5: DATABASE SCHEMA & DATA MIGRATION

This step uses the `pg_manage_v2` utility image to clone Azure data into
your local PostgreSQL instance.

### 5.1 Clone the pg_manage_v2 Repository

``` bash
git clone git@github.com:Matt-Teixeira/pg_manage_v2.git
cd pg_manage_v2
```

### 5.2 Create & Populate `.env`

Place your database source + destination connection variables inside
`.env`.

### 5.3 Build the pg_manage_v2 Docker Image

``` bash
docker build -t pg_manage .
```

### 5.4 Copy Tables & Schemas

```bash
docker run --rm \
  --network pg_net \
  --env-file .env \
  -v "$PWD":/app -w /app \
  --entrypoint bash \
  pg_manage \
  -lc './scripts/azure_to_local_migration/1_pgdump_tables_to_local.sh'

```

This transfers:

-   Tables\
-   Schemas\
-   Triggers\
-   Constraints\
-   Indexes\
-   Views\
-   Sequences\
-   Extensions (`CREATE EXTENSION` must exist on destination)

### 5.5 Copy Table Data

For each batch of tables, modify variables in `.env` to set which groups
to import, then run:
``` bash
docker run --rm   --network pg_net   --env-file .env   -v "$PWD":/app -w /app   --entrypoint bash   pg_manage   -lc './scripts/azure_to_local_migration/2_pgdump_data_to_local.sh'
```

### 5.6 Copy Date-Constrained Table Data
``` bash
docker run --rm   --network pg_net   --env-file .env   -v "$PWD":/app -w /app   --entrypoint bash   pg_manage   -lc './scripts/azure_to_local_migration/3_pgdump_data_to_local_time_cond.sh'
```

### YOU CAN START THE HALTED PROD SERVICES AT THIS POINT

### 5.7 Table Updates
```sql
BEGIN;

ALTER TABLE alert.offline_hhm_conn
  ADD COLUMN IF NOT EXISTS error_category VARCHAR(40),
  ADD COLUMN IF NOT EXISTS phase VARCHAR(20);

ALTER TABLE alert.offline_mmb_conn
  ADD COLUMN IF NOT EXISTS successful_acquisition BOOLEAN,
  ADD COLUMN IF NOT EXISTS host_intervention BOOLEAN,
  ADD COLUMN IF NOT EXISTS connection_error TEXT,
  ADD COLUMN IF NOT EXISTS error_category VARCHAR(40),
  ADD COLUMN IF NOT EXISTS phase VARCHAR(20),
  ADD COLUMN IF NOT EXISTS daily_total INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS lifetime_total INTEGER DEFAULT 0;

UPDATE
	config.acquisition
SET
	acquisition_script = 'phil_mri_data_grab_3.sh'
WHERE
	acquisition_script = 'phil_mri_data_grab_6.sh';

-- Stats: tunnel + IP health history (per-run × per-system fact + per-run × per-tunnel rollup)
CREATE TABLE IF NOT EXISTS stats.acquisition_history(
    id BIGSERIAL PRIMARY KEY,
    run_id UUID NOT NULL,
    acq_run_id UUID,
    app_name VARCHAR(64) NOT NULL,
    system_id VARCHAR(8) NOT NULL,
    data_source VARCHAR(8) NOT NULL,
    manufacturer VARCHAR(32),
    modality VARCHAR(32),
    capture_datetime TIMESTAMPTZ,
    successful_acquisition BOOLEAN NOT NULL,
    host_intervention BOOLEAN,
    connection_error TEXT,
    error_category VARCHAR(64),
    phase VARCHAR(32),
    host_ip INET,
    tunnel_id INTEGER,
    endpoint_id INTEGER,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_acq_hist_system_inserted ON stats.acquisition_history(system_id, inserted_at DESC);

CREATE INDEX IF NOT EXISTS idx_acq_hist_tunnel_inserted ON stats.acquisition_history(tunnel_id, inserted_at DESC) WHERE tunnel_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_acq_hist_inserted_brin ON stats.acquisition_history USING BRIN(inserted_at);

CREATE INDEX IF NOT EXISTS idx_acq_hist_run_id ON stats.acquisition_history(run_id);

CREATE INDEX IF NOT EXISTS idx_acq_hist_acq_run_id ON stats.acquisition_history(acq_run_id) WHERE acq_run_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_acq_hist_err_cat_inserted ON stats.acquisition_history(error_category, inserted_at DESC) WHERE error_category IS NOT NULL;

CREATE TABLE IF NOT EXISTS stats.tunnel_run_summary(
    id BIGSERIAL PRIMARY KEY,
    run_id UUID NOT NULL,
    app_name VARCHAR(64) NOT NULL,
    tunnel_id INTEGER,
    endpoint_id INTEGER,
    subnet_24 CIDR,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    systems_total INT NOT NULL,
    systems_success INT NOT NULL,
    systems_failed INT NOT NULL,
    systems_intervention INT NOT NULL,
    err_cat_breakdown JSONB
);

-- Dedupe constraint: one row per (run × tunnel × app), with NULL tunnel_id treated as a single bucket
CREATE UNIQUE INDEX IF NOT EXISTS uq_tun_run_sum_run_tunnel_app ON stats.tunnel_run_summary(run_id, COALESCE(tunnel_id, -1), app_name);

CREATE INDEX IF NOT EXISTS idx_tun_run_sum_tunnel_processed ON stats.tunnel_run_summary(tunnel_id, processed_at DESC);

CREATE INDEX IF NOT EXISTS idx_tun_run_sum_subnet_processed ON stats.tunnel_run_summary(subnet_24, processed_at DESC);


COMMIT;
```

------------------------------------------------------------------------

# STEP 6: DATA ACQUISITION APP SETUP

This section covers repository setup, environment prep, permissions, and
execution.

### 6.1 Clone Repositories

Clone data_acquisition App & Switch to Docker-specific branches:

``` bash
git clone git@github.com:Matt-Teixeira/data_acquisition.git
cd data_acquisition
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"
```

> **No separate `utils` clone.** `utils/` is vendored into the repo and is already present
> in the checkout. (See Conventions.) The logger dir still needs group-writable perms so
> containerized runs can write rotated logs — handled in STEP 8.

### 6.2 Update Local .env With User Info
- Currently, this step is a copy/past of saved .env state from local computer

### 6.3 List users and get usernames & IDs for service user, jonathan, and matt
```bash
cut -d: -f1 /etc/passwd
```

#### Get service user uid and add to .env under the UID_0 var
Do the same for jonathan and matt as UID_1 and UID_2 respectivly 
```bash
# UID_0
id svc

# UID_1
id jonathan-pope

# UID_2
id matt-teixeira
```

#### Get the docker group id and save to .env as DOCKER_GID
```bash
# DOCKER_GID
getent group docker
```
# STEP 7: CREATE RESOURCES DIRs

Use absolute paths. `/opt/resources` holds the shared node_modules caches, acquisition
file store, SSH bundle, and SSL certs. `/opt/run-logs` holds per-app run logs (canonical).

The app list below is the current full suite. Add a dir for every app you deploy
(per-app sections later create their own, so this is the one-shot bulk create).

```bash
APPS="data_acquisition hhm_rpp_ge hhm_rpp_philips hhm_rpp_siemens \
acumatica_sync monday reports part-source-pipeline ops-dashboard"
```

#### 7.1 Create the shared resource roots
``` bash
sudo mkdir -p /opt/resources/node_mod_cache /opt/resources/acqu_files
sudo chgrp -R docker /opt/resources/node_mod_cache /opt/resources/acqu_files
sudo chmod -R 2775   /opt/resources/node_mod_cache /opt/resources/acqu_files
```

#### 7.2 Create per-app node_mod_cache dirs
``` bash
for a in $APPS; do mkdir -p "/opt/resources/node_mod_cache/$a"; done
chgrp -R docker /opt/resources/node_mod_cache
chmod -R g+rwXs /opt/resources/node_mod_cache   # setgid so cache files stay group-docker
```

#### 7.3 Create per-app run-logs dirs (canonical: /opt/run-logs)
``` bash
for a in $APPS; do mkdir -p "/opt/run-logs/$a"; done
chgrp -R docker /opt/run-logs
chmod -R g+rwXs /opt/run-logs
```

> Do **not** use `/opt/resources/run-logs/` — it is the deprecated legacy path. If it
> exists from an old build, it can be left in place or removed once you've confirmed no
> app's `.env` `RUN_LOGS_DIR` still points at it.

#### STEP 8: UPDATE ENCRYPTED CREDENTIALS
``` bash
# In the data_acqu app root
./run_scripts/update_db_creds.sh
```
Notes ^:

-   Uses pinned image: `node:16.20.2`
-   Produces temporary `node_modules` --- safe to delete after run

#### 8.1 Build Image
``` bash
docker compose build app_tools
```

> **Per-app baked entrypoint.** The build copies the tracked `docker/entrypoint.sh` into
> the image (`COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh` →
> `ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]`). At runtime it drops to `RUN_USER` via
> `gosu` and execs your command. Because it is baked in, **no `/opt/resources` tree is
> mounted for the entrypoint** — the compose file only bind-mounts the read-only SSH
> bundle (`/opt/resources/ssh`) that specific jobs need. The old global
> `/opt/resources/entrypoint.sh` is deprecated and unused. See "Per-app entrypoint"
> below for the standard and which apps still need one added.

## Change utils dir to write and group permissions
The vendored `utils/logger` dir must be group-writable so containerized runs (executing
as `RUN_USER`, group `docker`) can write rotated logs:
```bash
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger
```

## Run a data acquisition job

```sh
# Run first to create node_modules cache
docker compose run --rm app_tools bash -lc "npm ci --omit=dev --no-audit --no-fund && npm run <job_name>"

# Normal run when node_modules exist in cache
docker compose run --rm app_tools bash -lc "npm ci --omit=dev && npm run <job_name>"
```
------------------------------------------------------------------------

### DATABASE SSL SETUP

# SSL Config for Docker Postgres

## Context
Self-managed Dockerized Postgres 16 on an Azure VM. Developers share `/opt` resources via `docker` group membership. `/opt` lives on the root OS drive (`sda1`). The external drive (`/mnt/sdc`) hosts Docker volumes only. Postgres runs as UID 999 inside the container.

---

## Prerequisites
- Your user is in the `docker` group
- `/opt/resources` is writable by the `docker` group
- `openssl` is installed on the VM
- Postgres container is named `pg_db` and runs on network `pg_net`

---

## Step 1 — Generate the Certificates

Run as your dev user (no sudo needed):

```bash
mkdir -p /opt/resources/ssl

openssl genrsa -out /opt/resources/ssl/pg_ssl.key 2048

openssl req -new -x509 -days 1095 \
  -key /opt/resources/ssl/pg_ssl.key \
  -out /opt/resources/ssl/pg_ssl.crt \
  -subj "/CN=pg_db" \
  -addext "subjectAltName=DNS:pg_db,DNS:postgres-server,DNS:localhost,IP:<VM_PUBLIC_IP>,IP:127.0.0.1"

chown -R $USER:docker /opt/resources/ssl
chmod 640 /opt/resources/ssl/pg_ssl.crt
chmod 640 /opt/resources/ssl/pg_ssl.key
```

> ⚠️ **CN and SAN are critical.** The `CN` and `subjectAltName` fields must match every hostname and IP address clients will use to connect. Node.js and modern TLS clients will reject connections with `ERR_TLS_CERT_ALTNAME_INVALID` if there is any mismatch.
>
> In this setup the SAN covers the following environments:
> - **`DNS:pg_db`** — Docker container name, used by dockerized apps on `pg_net`
> - **`DNS:postgres-server`** — legacy CN name, retained for compatibility
> - **`DNS:localhost`** — covers DB IDEs (e.g. Beekeeper) that internally proxy connections through localhost regardless of the configured host
> - **`IP:<VM_PUBLIC_IP>`** — used by external clients, web stack apps, and direct psql connections
> - **`IP:127.0.0.1`** — loopback IP equivalent of localhost, covers tools that resolve localhost to an IP internally
>
> If the VM IP changes or a new hostname is added, the cert must be regenerated. See the Regenerating the Cert section.

---

## Step 2 — Set Final Permissions

Postgres enforces strict ownership and permission rules on the private key. The following steps are required and must be run in order:

```bash
# Grant UID 999 (postgres inside container) read access to the cert via ACL
setfacl -m u:999:r /opt/resources/ssl/pg_ssl.crt

# Transfer key ownership to UID 999 — Postgres requires this
sudo chown 999:docker /opt/resources/ssl/pg_ssl.key

# Remove ACL from key — Postgres rejects any group/world access on the key
sudo setfacl -b /opt/resources/ssl/pg_ssl.key

# Set strict permissions on key — required when owned by UID 999
sudo chmod 600 /opt/resources/ssl/pg_ssl.key
```

### Final State
```
pg_ssl.crt  →  640, owned by $USER:docker, ACL grants u:999:r--  ✅
pg_ssl.key  →  600, owned by 999:docker, no ACL                  ✅
```

### Postgres Permission Rules (for reference)
| Key owned by | Max permitted permissions |
|---|---|
| UID 999 (database user) | `600` |
| root | `640` |

---

## Step 3 — Run the Postgres Container with SSL
- docker stop pg_db && docker rm pg_db
```bash
docker run -d \
  --name pg_db \
  --network pg_net \
  -e POSTGRES_PASSWORD=<paste_pass_here> \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  -v /opt/resources/ssl/pg_ssl.crt:/etc/ssl/pg_ssl.crt:ro \
  -v /opt/resources/ssl/pg_ssl.key:/etc/ssl/pg_ssl.key:ro \
  --restart unless-stopped \
  postgres:16 \
  -c ssl=on \
  -c ssl_cert_file=/etc/ssl/pg_ssl.crt \
  -c ssl_key_file=/etc/ssl/pg_ssl.key
```

---

## Step 4 — Enforce SSL-Only via pg_hba.conf

### Backup first
```bash
docker exec -it pg_db cp /var/lib/postgresql/data/pg_hba.conf \
  /var/lib/postgresql/data/pg_hba.conf.bak
```

### Apply the change
Replace the default catch-all `host` rule with `hostssl`:
```bash
docker exec -it pg_db sed -i \
  's/^host all all all scram-sha-256/hostssl all all all scram-sha-256/' \
  /var/lib/postgresql/data/pg_hba.conf
```

### Reload without restarting
```bash
docker exec -it pg_db psql -U postgres -c "SELECT pg_reload_conf();"
```

### What changed
```
# Before
host    all   all   all   scram-sha-256

# After
hostssl all   all   all   scram-sha-256
```

The localhost `trust` rules are left intact — they apply only to Unix socket or loopback connections from within the container itself and never leave the host.

---

## Step 5 — Configure App Connections

### Node.js / pg-promise

```javascript
const fs = require('fs');
const pgp = require('pg-promise')();

const config = {
   host: process.env.PG_HOST,
   port: process.env.PG_PORT,
   database: process.env.PG_DB,
   user: process.env.PG_USER,
   password: process.env.PG_PW,
   ssl: {
      require: true,
      ca: fs.readFileSync(process.env.PG_SSL_PATH),
      rejectUnauthorized: true,
   },
};

const db = pgp(config);
module.exports = db;
```

### Environment Variables
```bash
PG_HOST=pg_db                          # container name for dockerized apps
PG_HOST=<VM_PUBLIC_IP>                 # public IP for external connections
PG_PORT=5432
PG_SSL_PATH=/opt/resources/ssl/pg_ssl.crt
```

> Note: `PG_SSL_PATH` previously pointed to `BaltimoreCyberTrustRoot.crt.pem` (Azure Flexi-server CA cert). It now points to `pg_ssl.crt`. The field in the connection config also changed from `cert` to `ca` since the self-signed cert acts as its own trust anchor.
>
> For App Service deployments, `pg_ssl.crt` must be deployed alongside the app. Only the public cert is needed, never the key.

---

## SSL Encryption vs Certificate Verification

These are two distinct layers:

| Layer | What it means | Controlled by |
|---|---|---|
| **Encryption** | Connection traffic is encrypted | `pg_hba.conf` `hostssl` |
| **Verification** | Client confirms server identity | Client `sslmode=verify-ca` + `sslrootcert` |

`hostssl` in `pg_hba.conf` enforces encryption only. Certificate verification is a client-side decision on top of that, handled by `rejectUnauthorized: true` in the app config.

### How each client handles verification
| Client | Config | Enforces cert verify? |
|---|---|---|
| Node.js app | `rejectUnauthorized: true` + `ca: cert` | ✅ Yes |
| psql | `sslmode=verify-ca sslrootcert=pg_ssl.crt` | ✅ Yes |
| DB IDE | Configure to trust `pg_ssl.crt` | ✅ Once configured |

---

## Verification Tests

```bash
# Test 1 — should be rejected (no SSL)
psql "host=<VM_PUBLIC_IP> port=5432 dbname=dev user=postgres sslmode=disable"

# Test 2 — should connect (SSL, no cert verify)
psql "host=<VM_PUBLIC_IP> port=5432 dbname=dev user=postgres sslmode=require"

# Test 3 — should connect (SSL + cert verify)
psql "host=<VM_PUBLIC_IP> port=5432 dbname=dev user=postgres sslmode=verify-ca sslrootcert=~/pg_ssl.crt"
```

| Test | Expected Result |
|---|---|
| No SSL | ❌ Rejected |
| SSL, no cert verify | ✅ Connected |
| SSL + cert verify | ✅ Connected |

---

## Regenerating the Cert

Required when: cert expires, VM IP changes, or a new hostname needs to be added.

```bash
# Regenerate — sudo required since pg_ssl.key is owned by UID 999
sudo openssl req -new -x509 -days 1095 \
  -key /opt/resources/ssl/pg_ssl.key \
  -out /opt/resources/ssl/pg_ssl.crt \
  -subj "/CN=pg_db" \
  -addext "subjectAltName=DNS:pg_db,DNS:postgres-server,DNS:localhost,IP:<VM_PUBLIC_IP>,IP:127.0.0.1"

# Restore ownership to your dev user
sudo chown $USER:docker /opt/resources/ssl/pg_ssl.crt

# Re-apply ACL for UID 999 (lost when file is overwritten)
setfacl -m u:999:r /opt/resources/ssl/pg_ssl.crt

# Restart container — Postgres loads cert at startup, not dynamically
docker restart pg_db
```

> ⚠️ **The container must be restarted** after regenerating the cert. Volume mounting alone is not sufficient — Postgres loads the cert into memory at startup.
>
> **After regenerating, all devs must re-pull `pg_ssl.crt` to their local machines.**


------------------------------------------------------------------------

### PER-APP ENTRYPOINT (standard)

Every app image bakes its own entrypoint instead of mounting the old global
`/opt/resources/entrypoint.sh`. The standard script is:

```bash
#!/bin/bash
set -e
# Default to svc if RUN_USER not specified
RUN_USER="${RUN_USER:-svc}"
# Dynamically set HOME based on the chosen user
export HOME="/home/$RUN_USER"
# Drop privileges and exec the command as that user
exec gosu "$RUN_USER" "$@"
```

It is committed in the repo and copied in by the Dockerfile:

```dockerfile
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
```

Location differs by app (both are valid, just be consistent within a repo):

| App | Entrypoint path | Status |
|---|---|---|
| data_acquisition | `docker/entrypoint.sh` | ✅ baked |
| reports | `docker/entrypoint.sh` | ✅ baked |
| acumatica_sync | `entrypoint.sh` (root) | ✅ baked |
| part-source-pipeline | `entrypoint.sh` (root) | ✅ baked |
| imprivata-poc | `docker/entrypoint.sh` | ✅ baked (conditional gosu) |
| hhm_rpp_ge | — | ⚠️ no tracked entrypoint — add one |
| monday | — | ⚠️ no tracked entrypoint — add one |
| ops-dashboard | n/a | runs as `user: "<svc_uid>:<docker_gid>"` (long-running service, no gosu drop) |

> **Action:** `hhm_rpp_ge` and `monday` have no committed entrypoint. Add the standard
> script + Dockerfile `COPY`/`ENTRYPOINT` lines so they don't depend on the deprecated
> global file.

### SHARED SSH BUNDLE

Apps that SFTP/rsync to remote hosts (e.g. data_acquisition → MMB) use a **single shared
SSH bundle** at `/opt/resources/ssh/`, mounted read-only into the container:

```
/opt/resources/ssh/
├── config        # ssh client config
├── id_dev        # private key (referenced by the .env SSH_KEY var)
├── known_hosts   # accumulated host keys
└── known_hosts.bak
```

In compose this is mounted `- /opt/resources/ssh:/opt/resources/ssh:ro`, and the app's
`.env` sets `SSH_KEY` to the key path inside that dir (used by `rsync_mmb.sh`).

> **Reconciliation note:** an earlier design used a per-app
> `/opt/resources/ssh_bundles/<app>/known_hosts` layout where the entrypoint copied the
> bundle into `~/.ssh` and copied `known_hosts` back out on exit. That `ssh_bundles/`
> layout is **not** what the running system uses — the current convention is the single
> flat read-only `/opt/resources/ssh/` bundle above, and the entrypoint no longer does any
> ssh copy dance (it only drops to `RUN_USER`). The old `docs/entrypoint.md` has been
> updated to match.

#### Permissions for the shared SSH bundle
```bash
sudo chgrp -R docker /opt/resources/ssh
chmod 640 /opt/resources/ssh/config
chmod 600 /opt/resources/ssh/id_dev          # private key: owner-only
chmod 660 /opt/resources/ssh/known_hosts     # group-writable so new host keys can append
```

------------------------------------------------------------------------

### HHM RPP SETUP
------------------------------------------------------------------------

# ✅ Step ** --- RPP Apps Setup

This section covers repository setup, environment prep, permissions, and
execution.

------------------------------------------------------------------------

# 📦 Repository Setup

## 1. Clone Repositories

Clone data_acquisition App & Switch to Docker-specific branches:

# CLONE GE RPP APP
```bash
git clone git@github.com:Matt-Teixeira/hhm_rpp_ge.git

cd hhm_rpp_ge

# Switch to docker branch
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"

# utils/ is vendored in the repo (no separate clone). Make logger group-writable:
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

# Build the image (bakes the gosu entrypoint)
docker compose build

# Create cache + run-log dirs
mkdir -p /opt/resources/node_mod_cache/hhm_rpp_ge /opt/run-logs/hhm_rpp_ge
```

> **Entrypoint note:** `hhm_rpp_ge` does not yet ship a tracked `docker/entrypoint.sh`.
> Confirm its image either bakes one or that the job still relies on the deprecated global
> entrypoint; standardize it to a per-app baked entrypoint to match the other apps.
# CLONE PHILIPS RPP APP
```bash
git clone git@github.com:Matt-Teixeira/hhm_rpp_philips.git

cd hhm_rpp_philips

# Switch to docker branch
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"

# utils/ is vendored in the repo (no separate clone). Make logger group-writable:
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

# Build the image (bakes the gosu entrypoint)
docker compose build

# Create cache + run-log dirs
mkdir -p /opt/resources/node_mod_cache/hhm_rpp_philips /opt/run-logs/hhm_rpp_philips
```

# CLONE SIEMENS RPP APP
```bash
git clone git@github.com:Matt-Teixeira/hhm_rpp_siemens.git

cd hhm_rpp_siemens

# Switch to docker branch
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"

# utils/ is vendored in the repo (no separate clone). Make logger group-writable:
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

# Build the image (bakes the gosu entrypoint)
docker compose build

# Create cache + run-log dirs
mkdir -p /opt/resources/node_mod_cache/hhm_rpp_siemens /opt/run-logs/hhm_rpp_siemens
```

### ACUMATICA PULL APP SETUP
------------------------------------------------------------------------

# CLONE acumatica_sync APP

```bash
git clone git@github.com:Matt-Teixeira/acumatica_table_pull.git acumatica_sync

cd acumatica_sync

# Switch to docker branch
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"

# utils/ is vendored; entrypoint ships at the repo root (entrypoint.sh), baked in at build.

# Build image
docker build -t acu-sync:svc .

# Creat dir
mkdir -p /opt/resources/node_mod_cache/acumatica_sync /opt/run-logs/acumatica_sync
```

### REPORTS APP SETUP
------------------------------------------------------------------------

# CLONE reports APP

```bash
git clone git@github.com:Matt-Teixeira/reports.git

cd reports

# Switch to docker branch
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"

# utils/ is vendored in the repo (no separate clone). Make logger group-writable:
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

# Build image
docker build -t reports:svc .

# Creat dir
mkdir -p /opt/resources/node_mod_cache/reports /opt/run-logs/reports

```

### MONDAY APP SETUP
------------------------------------------------------------------------

# CLONE monday APP

```bash
git clone git@github.com:Matt-Teixeira/monday.git

cd monday

# Switch to docker branch
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"

# utils/ is vendored in the repo (no separate clone). Make logger group-writable:
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

# Build image
docker build -t monday:svc .

# Creat dir
mkdir -p /opt/resources/node_mod_cache/monday /opt/run-logs/monday
```

### Part Source Pipeline APP SETUP
------------------------------------------------------------------------

# CLONE part-source-pipeline APP

```bash
git clone git@github.com:Matt-Teixeira/part-source-pipeline.git

cd part-source-pipeline

# Switch to docker branch
git switch -c "${ENV}_docker" --track "origin/${ENV}_docker"

mkdir -p files && chmod -R g+rwX files && chgrp -R docker files

# utils/ is vendored in the repo (no separate clone). Make logger group-writable:
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

# This app ships its entrypoint at the repo root (entrypoint.sh), baked in at build.

# Build image
docker compose build

# Creat dir
mkdir -p /opt/resources/node_mod_cache/part-source-pipeline /opt/run-logs/part-source-pipeline
```

### OPS-DASHBOARD APP SETUP
------------------------------------------------------------------------

`ops-dashboard` is **different from every other app in this guide**: it is a
**long-running HTTP service**, not a one-shot cron job. It is a read-only Express +
`pg-promise` dashboard over the shared `util.app_run_logs` Postgres table — it shows, in
one screen, whether each app's cron jobs ran, succeeded, failed, or went stale. It only
reads pipeline data (its lone write is its own opt-in heartbeat row).

Because it is long-running, you manage it with `docker compose up -d` / `down` /
`restart` / `logs` — **not** `docker compose run --rm`. The container stays up serving
HTTP on `:8080`, `restart: unless-stopped`, attached to `pg_net`.

There is **no Dockerfile / no baked entrypoint** — it runs the stock `node:lts` image and
drops privileges via compose `user: "<svc_uid>:<docker_gid>"` (e.g. `"105:987"` —
`id -u svc` and the `docker` GID from `getent group docker`). Confirm those IDs on the
target VM before `up`, since they are hardcoded in its `docker-compose.yaml`.

# CLONE ops-dashboard APP
```bash
git clone git@github.com:Matt-Teixeira/ops-dashboard.git

cd ops-dashboard

# This app currently tracks 'main' (no <ENV>_docker branch). Stay on main unless an
# environment branch has since been created.

# utils/ is vendored in the repo (no separate clone).

# Create cache + run-log dirs (run logs dir is bind-mounted read-write)
mkdir -p /opt/resources/node_mod_cache/ops-dashboard /opt/run-logs/ops-dashboard

# Configure environment
cp .env.example .env
# Fill in PG connection (PG_HOST=pg_db, SSL via /opt/resources/ssl/pg_ssl.crt), and the
# self-monitoring toggle. See .env.example and README.md for every key.

# First run: populate the node_modules cache, then start the service
docker compose run --rm app bash -lc "npm ci --omit=dev --no-audit --no-fund"
docker compose up -d

# Verify
docker compose ps
docker compose logs -f app          # watch startup
curl -s http://localhost:8080/ | head   # dashboard UI/API on :8080
```

Notes:
- Mounts: source `./:/workspace`, node cache
  `/opt/resources/node_mod_cache/ops-dashboard`, run logs `/opt/run-logs/ops-dashboard`,
  and the SSL cert dir `/opt/resources/ssl:ro`.
- Change the host port mapping in `docker-compose.yaml` (`"8080:8080"`) if 8080 is taken.

### IMPRIVATA POC APP SETUP
------------------------------------------------------------------------

`imprivata-poc` is a **proof-of-concept**, not a production cron app, and a couple of
things make it special:

1. **It is Python, not Node** (`paramiko` + the Imprivata PAS/CPAM SDK), built from
   `docker/Dockerfile` into `imprivata-poc:local`, run via
   `docker compose run --rm app_tools`.
2. **It is not (yet) a tracked git repo on this server** — the working copy has no
   `origin` remote. Treat the on-disk directory as the source of truth and read
   `README-HANDOFF.md` + `docs/runbook.md` first; those are the live project context and
   blocker checklist. If/when it gets a remote, add the clone line here.
3. **Two artifacts are supplied at build/run time and must never be committed or baked
   into the image:**
   - `sdk/imprivata_pas_cpam_sdk-2.11.0.whl` — the vendor SDK wheel (build arg `SDK_WHEEL`).
   - `secrets/securelink.properties` — host-side, mounted **writable** into the container
     at `/workspace/securelink.properties` (the SDK rewrites it).

Its entrypoint (`docker/entrypoint.sh`) is a **conditional** gosu drop: it only switches
to `RUN_USER` if that var is set and the user exists, otherwise it runs as-is — so the PoC
works without the baked user accounts the Node images have.

# SET UP imprivata-poc
```bash
cd /opt/apps/imprivata-poc      # already present; not cloned from a remote

# 1) Place the SDK wheel (do NOT commit it)
#    cp <source>/imprivata_pas_cpam_sdk-2.11.0.whl sdk/

# 2) Create the host secrets file from the approved API-key setup (do NOT commit it)
#    See docs/runbook.md for the exact properties.
mkdir -p secrets output
# create secrets/securelink.properties ...

# 3) Configure non-secret runtime selectors
cp .env.example .env
# Fill in IMPRIVATA_CUSTOMER_NAME, IMPRIVATA_SITE_NAME, optional service filters,
# IMPRIVATA_REMOTE_PATH, etc. (all have defaults in docker-compose.yaml).

# 4) Preflight, then build
python3 preflight.py
docker compose build app_tools

# 5) Verify prereqs inside the container
docker compose run --rm app_tools bash -lc "python /workspace/check_prereqs.py"

# 6) Run the pull
docker compose run --rm app_tools bash -lc "python /workspace/poc_pull_file.py"
```

Notes:
- Pulled files land in `./output/` (bind-mounted to `/workspace/output`).
- No `/opt/resources` cache or run-log dirs are used — it is self-contained under its repo
  dir, which suits its PoC status.
