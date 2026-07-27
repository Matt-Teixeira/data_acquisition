# Docker Server Full Setup — dev/staging (reconciled 2026-07-27)

This guide builds a dev/staging acquisition server the way **acq-vm-0 actually runs**.
Every command, image tag, branch, and permission below was verified against that live
server on 2026-07-27 (see `docker_server_full_setup_2.0_audit_claude.md` for the audit
that drove this revision, and `schedules.md` for the job schedule manifest).

**Scope:** dev and staging servers. **No PROD server exists yet** — `PROD_docker`
branches, a prod cutover runbook, and prod data-governance decisions are all future
work, deliberately out of scope here.

------------------------------------------------------------------------

# CONVENTIONS — the server as it really is

There is no single `ENV` knob. A server's identity is set by four independent axes —
set each one explicitly and don't assume they match:

| Axis | Value on acq-vm-0 | Controls |
|---|---|---|
| Git branch (per repo, table below) | `DEV_docker` / `STAGING_docker` / `main` | which code runs |
| Image tags | `:staging` everywhere | which image compose runs |
| Compose volume vars | `_DEV`-suffixed names (`NODE_MOD_CACHE_DEV`, `DATA_STORE_DEV`) | where caches/files live — the *names* are fixed in compose; point their *values* wherever this server stores data |
| `RUN_ENV` in `.env` | `dev` | **logger file routing only** (see Run logs below) — not deployment |

Database: the single local Postgres serves database **`staging`** for every app
(`PGDATABASE=staging`). There is no `dev` database.

**Branch map (clone target per repo):**

| Repo | Branch on acq-vm-0 |
|---|---|
| data_acquisition, acumatica_sync | `DEV_docker` |
| hhm_rpp_ge, hhm_rpp_philips, hhm_rpp_siemens, monday, reports, part-source-pipeline | `STAGING_docker` |
| incident-engine, ops-dashboard, acquisition-v2, imprivata-poc | `main` (no env branches) |
| redis-admin | `DEV` |
| pg_manage_v2 | `STAGING` |

Other standing conventions:

- **Vendored `utils/`.** The shared library (logger, db, vpn, sh helpers) is vendored
  into each app repo. Never clone the old `AvanteHS-RTT/utils` repo. (Exception:
  acumatica_sync's `utils/` holds only its own `queries.js`.)
- **Per-app entrypoint.** The gosu user-drop entrypoint is baked into each app image
  from a tracked `docker/entrypoint.sh` or root `entrypoint.sh` (matrix below). The old
  global `/opt/resources/entrypoint.sh` is dead — nothing references it; delete it.
- **Run logs.** The vendored logger (`utils/logger/log.js`) switches on `RUN_ENV`:
  - `dev` → writes per-run JSON into **`<repo>/utils/logger/`** (gitignored)
  - `staging`/anything else → writes to **`/opt/run-logs/<APP_NAME>/`**
  Since most apps here run `RUN_ENV=dev`, the repo-local dirs are the hot path — they
  grow ~140 MB/day fleet-wide and are pruned nightly (see BACKUPS & LOG ROTATION).
  Every job also self-logs a row into `util.app_run_logs` regardless of `RUN_ENV`
  (that's what ops-dashboard reads).
- **`RUN_LOGS_DIR` format.** Where an app's `.env` defines it (data_acquisition,
  incident-engine), it is a **full `host:container` bind spec** consumed verbatim by a
  compose volume entry: `RUN_LOGS_DIR=/opt/run-logs/<app>:/opt/run-logs/<app>`.

------------------------------------------------------------------------

# STEP 1: INSTALL DOCKER

acq-vm-0 runs Docker 29.4.3 / Compose v5.1.3 installed via the apt repo. Record
`docker version` and `docker compose version` in the deployment notes when you build a
new server. (The recipe below is the classic keyring method; Docker's current docs use
a deb822 `docker.sources` file instead — either works, prefer the current official
method for new builds.)

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run hello-world
```

### Optional: big-disk data root (ONLY if the VM has a second data disk)

acq-vm-0 has a single 2 TB root disk and uses the default `/var/lib/docker` — skip this
block there. On a VM with a data disk mounted at `/mnt/sdc` (verify: `df -h | grep sdc`,
and make sure it's in `/etc/fstab` so it mounts before Docker starts):

```bash
sudo mkdir -p /mnt/sdc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{ "data-root": "/mnt/sdc/docker" }
EOF
sudo systemctl restart docker
docker info | grep "Docker Root Dir"    # expect /mnt/sdc/docker
```

> ⚠️ **Docker 29+ caveat:** fresh installs may use the containerd image store, whose
> content lives under `/var/lib/containerd` and is NOT moved by `data-root` alone.
> After the restart, pull an image and verify where the bytes actually land before
> trusting the migration.

# STEP 1.1: CREATE USERS

Two kinds of accounts, created differently:

```bash
# Admin users (repeat per human; both exist on acq-vm-0)
sudo adduser matt-teixeira
sudo adduser jonathan-pope
sudo usermod -aG docker matt-teixeira
sudo usermod -aG docker jonathan-pope
# Group membership takes effect on next login (or `newgrp docker` in the current shell).
# Note: membership in `docker` is root-equivalent on the host — admins only.

# Service account (jobs run as this identity inside containers)
sudo adduser --system --no-create-home --group --shell /usr/sbin/nologin svc
sudo usermod -aG docker svc
# svc MUST be in the docker group: shared /opt dirs and the SSH bundle rely on
# group-docker permissions (verified live — jobs break without it).
```

Record the numeric ids — they feed `.env` files and are baked into some images:

```bash
id svc                  # acq-vm-0: uid=105
id matt-teixeira        # acq-vm-0: uid=1006
id jonathan-pope        # acq-vm-0: uid=1001
getent group docker     # acq-vm-0: gid=987
```

> ⚠️ Several repos hardcode `105:987` (compose `user:` on incident-engine/ops-dashboard/
> acumatica_sync; build args in monday/part-source-pipeline; literals in reports'
> Dockerfile). On a new server, either make the ids match or update those files —
> then run each app's write-permission smoke test.

# STEP 1.2: SHARED RESOURCE PERMISSIONS

```bash
sudo mkdir -p /opt/run-logs /opt/apps /opt/resources
for d in /opt/run-logs /opt/apps /opt/resources; do
  sudo chgrp docker "$d"
  sudo chmod 2775 "$d"        # setgid: new files inherit group docker
done
```

# STEP 1.3: DEFAULT ACLs

```bash
sudo apt install -y acl
for d in /opt/run-logs /opt/apps /opt/resources; do
  sudo setfacl -d -m g:docker:rwX "$d"
  sudo setfacl -m g:docker:rwX "$d"
done
```

------------------------------------------------------------------------

# STEP 2: DATABASE INITIALIZATION

Image `postgres:16`, container `pg_db`, network `pg_net`, named volume `postgres_data`.

```bash
docker pull postgres:16
docker volume create postgres_data
docker network create pg_net
```

Use a root-owned password file — never the password on the command line (shell history,
`docker inspect` exposure):

```bash
sudo install -m 600 -o root -g root /dev/null /root/pg_superuser_pw
# put the password in /root/pg_superuser_pw (single line)

docker run -d \
  --name pg_db \
  --network pg_net \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/pg_pw \
  -v /root/pg_superuser_pw:/run/secrets/pg_pw:ro \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:16
```

(For the SSL-enabled variant used in production of this box, see DATABASE SSL SETUP —
you can start with SSL flags from day one and skip the plain run above.)

Wait for readiness (not "a few seconds"):

```bash
until docker exec pg_db pg_isready -U postgres -q; do sleep 1; done && echo ready
```

Create the database. **This stack uses a single `staging` database for every app** —
do not create a `dev` database unless something actually points at it:

```bash
docker exec -it pg_db psql -U postgres -c "CREATE DATABASE staging;"
```

Verify the container joined the network and connect:

```bash
docker network inspect pg_net --format '{{range .Containers}}{{.Name}} {{end}}'   # expect pg_db
sudo apt-get install -y postgresql-client
psql -h localhost -p 5432 -U postgres -d staging
```

------------------------------------------------------------------------

# GIT CONFIG

```bash
git config --global user.email "you.guy@avantehs.com"
git config --global user.name  "You Guy"
```

------------------------------------------------------------------------

# STEP 3: REDIS CONTAINERS (redis-admin)

Four instances: `redis-PROD` (live acquisition state), `redis-STAGING`, `redis_dev-0-4`,
`redis_dev-0-5`, on the dedicated `redis-admin_redis_net` bridge.

```bash
git clone git@github.com:Matt-Teixeira/redis-admin.git /opt/apps/redis-admin
cd /opt/apps/redis-admin
git switch DEV
# Create .env (gitignored). Vars: REDIS_SUBNET, REDIS_GATEWAY,
# REDIS_{PROD,STAGING,DEV04,DEV05}_IP and _PORT (host ports 6379-6382 on acq-vm-0).
docker compose up -d
docker compose ps
```

**Verify the configs actually loaded** — this is not optional. Compose bind-mounts
`./config/<name>.config` over `/usr/local/etc/redis/redis.conf` using long-form syntax
with `create_host_path: false`. (History: the mounts used to point at nonexistent
`conf/*.conf` paths; Docker auto-created them as empty directories and Redis silently
ran on defaults with AOF off for months. Fixed 2026-07-27.)

```bash
for r in redis-PROD redis-STAGING redis_dev-0-4 redis_dev-0-5; do
  echo "$r: appendonly=$(docker exec $r redis-cli CONFIG GET appendonly | tail -1)" # expect yes
done
```

> ⚠️ **Enabling AOF on an instance with existing data is order-sensitive.** If Redis
> boots with `appendonly yes` and no AOF manifest in `/data`, it does **not** load
> `dump.rdb` — it starts EMPTY (verified on redis 7.4). Migration/restore procedure is
> documented in redis-admin's README: `CONFIG SET appendonly yes` on the *running*
> instance first (seeds the AOF from memory), then recreate.

No `requirepass` is set (deferred hardening — see FOLLOW-UPS). Host ports are published
on all interfaces; the Azure NSG is the access boundary — verify its rules.

------------------------------------------------------------------------

# STEP 4: SEED REDIS STATE (new server only)

Rescoped: this seeds a **new dev/staging server** from an existing source; it is not a
production cutover runbook (none exists yet — write and rehearse one before any PROD
build).

```bash
# On the source server:
./redis_dumps/redis_migrate.sh          # ships latest RDB to ~/redis_dumps/ on the target

# On the target server:
DUMP=$(ls -t ~/redis_dumps/redis-PROD-dump-*.rdb | head -1)
echo "Loading: $DUMP"

# Record source key count for verification, then stop targets BEFORE the copy
# (a running Redis rewrites its RDB on shutdown and would clobber it):
docker stop redis-PROD redis-STAGING redis_dev-0-4

for r in redis-PROD redis-STAGING redis_dev-0-4; do docker cp "$DUMP" $r:/data/dump.rdb; done
```

> ⚠️ If the target containers already ran with AOF enabled, the copied `dump.rdb` will
> be IGNORED on restart (AOF wins). In that case: also delete the `appendonlydir/`
> from each target volume while stopped, start, verify DBSIZE, then re-seed the AOF
> with `CONFIG SET appendonly no` → `yes` (or follow redis-admin/README.md).

```bash
docker start redis-PROD redis-STAGING redis_dev-0-4
for r in redis-PROD redis-STAGING redis_dev-0-4; do
  echo "$r: $(docker exec $r redis-cli DBSIZE)"    # compare against the source's DBSIZE
done
```

------------------------------------------------------------------------

# STEP 5: DATABASE SCHEMA & DATA SEEDING (pg_manage_v2)

```bash
git clone git@github.com:Matt-Teixeira/pg_manage_v2.git /opt/apps/pg_manage_v2
cd /opt/apps/pg_manage_v2
git switch STAGING
# Create .env with SRC_* (Azure source) and DST_* (local pg_db) connection vars.
docker build -t pg_manage .
```

### 5.1 Copy schemas/tables (structure + triggers/constraints/indexes/views/sequences)

```bash
docker run --rm --network pg_net --env-file .env -v "$PWD":/app -w /app \
  --entrypoint bash pg_manage -lc './scripts/azure_to_local_migration/1_pgdump_tables_to_local.sh'
```

### 5.2 Copy table data (batch groups set in .env)

```bash
docker run --rm --network pg_net --env-file .env -v "$PWD":/app -w /app \
  --entrypoint bash pg_manage -lc './scripts/azure_to_local_migration/2_pgdump_data_to_local.sh'
```

### 5.3 Date-constrained data

```bash
# Manual timeframe:
... -lc './scripts/azure_to_local_migration/3_pgdump_data_to_local_time_cond.sh'
# Month-to-date (first minute of current month → now):
... -lc './scripts/azure_to_local_migration/4_pgdump_data_to_local_month_to_date.sh'
```

### 5.4 Verify before pointing jobs at it

```bash
# Spot-check row counts per critical table against the source, e.g.:
psql -h localhost -U postgres -d staging -c "SELECT count(*) FROM alert.models;"
```

> Known gaps on acq-vm-0's staging DB (queries against these fail for every role,
> superuser included): `mag.ge_mm` does not exist (only `ge_mm3`/`ge_mm4`), and schema
> `edu` has no tables. Reports jobs touching those paths fail until seeded.

### 5.5 Table updates changelog

The big SQL block that used to live here (offline_* column adds,
`stats.acquisition_history`, `stats.tunnel_run_summary`, the acquisition_script rename)
is a **point-in-time changelog that has already been applied** to acq-vm-0. Future
schema changes belong in versioned migration files applied with `ON_ERROR_STOP`, not
in this guide. `CREATE TABLE IF NOT EXISTS` never upgrades an existing table.

------------------------------------------------------------------------

# STEP 6: DATA ACQUISITION APP SETUP

```bash
git clone git@github.com:Matt-Teixeira/data_acquisition.git /opt/apps/data_acquisition
cd /opt/apps/data_acquisition
git switch -c DEV_docker --track origin/DEV_docker     # acq-vm-0 runs DEV_docker here
```

### 6.1 `.env`

Copy from the previous server / secret store. Full key list (names; values come from
the secret store):

```
APP_NAME LOGGER RUN_ENV APP_SECRET
PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD PG_SSLMODE PG_SSL_PATH
REDIS_HOST REDIS_PORT
NODE_MOD_CACHE_DEV DATA_STORE_DEV RUN_LOGS_DIR
UID_0 UID_1 UID_2 DOCKER_GID RUN_USER SSH_KEY
SRC_* DST_* (migration passthrough)  VNS3_IP VNS3_PW  PHILIPS_MRI_SHELL_TIMEOUT_S
```

Key values on acq-vm-0: `RUN_ENV=dev`, `PGDATABASE=staging`, `PGHOST=pg_db`,
`RUN_LOGS_DIR=/opt/run-logs/data_acquisition:/opt/run-logs/data_acquisition`,
`NODE_MOD_CACHE_DEV=/opt/resources/node_mod_cache/data_acquisition`,
`DATA_STORE_DEV=/opt/resources/acqu_files`, `UID_0/1/2` + `DOCKER_GID` from STEP 1.1.

### 6.2 Build and warm the cache

```bash
docker compose build app_tools        # -> data-acqu:staging (docker/Dockerfile, baked gosu entrypoint)
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger   # dev-mode logs land here

# Warm the node_modules cache ONCE (and again only after dependency changes):
docker compose run --rm app_tools bash -lc "npm ci --omit=dev --no-audit --no-fund"
```

### 6.3 Run a job

```bash
docker compose run --rm app_tools bash -lc "npm run <job_name>"
```

This is exactly what cron runs — **no `npm ci` per invocation** (see
`docs/schedules.md`). Don't run `npm ci` while scheduled jobs are active; it rebuilds
the shared cache under them.

------------------------------------------------------------------------

# STEP 7: RESOURCE DIRS (bulk create)

```bash
APPS="data_acquisition hhm_rpp_ge hhm_rpp_philips hhm_rpp_siemens \
acumatica_sync monday reports part-source-pipeline incident-engine ops-dashboard \
acquisition-v2 odd-jobs"

sudo mkdir -p /opt/resources/node_mod_cache /opt/resources/acqu_files
sudo chgrp -R docker /opt/resources/node_mod_cache /opt/resources/acqu_files
sudo chmod -R 2775   /opt/resources/node_mod_cache /opt/resources/acqu_files

for a in $APPS; do mkdir -p "/opt/resources/node_mod_cache/$a" "/opt/run-logs/$a"; done
chgrp -R docker /opt/resources/node_mod_cache /opt/run-logs
chmod -R g+rwXs /opt/resources/node_mod_cache /opt/run-logs
```

App status notes:
- **acquisition-v2** — strangler-fig replacement for data_acquisition; currently
  **paused** (its totalizer cron line rolled back 2026-07-13; see `docs/schedules.md`).
- **odd-jobs** — legacy; still mounts all of `/opt/resources:ro` and predates current
  conventions. Retire-or-document decision pending.
- **imprivata-poc** — fully self-contained PoC; needs none of these dirs (see its section).

------------------------------------------------------------------------

# STEP 8: UPDATE ENCRYPTED CREDENTIALS (data_acquisition)

```bash
cd /opt/apps/data_acquisition
./run_scripts/update_db_creds.sh
```

What it actually does (read the script): pins EOL-but-compatible `node:16.20.2`,
deletes the (stray, unused) repo-local `node_modules/` dir, then runs
`npm ci && npm run update_db_creds` in a container whose `node_modules` is a **tmpfs**
— nothing lands on the host, no cleanup needed afterwards. The `APP_DIR` path is
hardcoded to `/opt/apps/data_acquisition` — edit it if the layout ever changes.

------------------------------------------------------------------------

# DATABASE SSL SETUP

## Generate the certificate

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

CN/SAN must cover every hostname/IP clients use (`pg_db` for dockerized apps on
`pg_net`, localhost/127.0.0.1 for IDE proxies, the VM IP for external clients) or
Node rejects with `ERR_TLS_CERT_ALTNAME_INVALID`. Regenerate when the IP changes.

## Key permissions (Postgres enforces these)

```bash
setfacl -m u:999:r /opt/resources/ssl/pg_ssl.crt   # uid 999 = postgres in-container
sudo chown 999:docker /opt/resources/ssl/pg_ssl.key
sudo setfacl -b /opt/resources/ssl/pg_ssl.key
sudo chmod 600 /opt/resources/ssl/pg_ssl.key
```

## Run pg_db with SSL

```bash
docker stop pg_db && docker rm pg_db
docker run -d \
  --name pg_db --network pg_net \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/pg_pw \
  -v /root/pg_superuser_pw:/run/secrets/pg_pw:ro \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  -v /opt/resources/ssl/pg_ssl.crt:/etc/ssl/pg_ssl.crt:ro \
  -v /opt/resources/ssl/pg_ssl.key:/etc/ssl/pg_ssl.key:ro \
  --restart unless-stopped \
  postgres:16 -c ssl=on -c ssl_cert_file=/etc/ssl/pg_ssl.crt -c ssl_key_file=/etc/ssl/pg_ssl.key
```

## Enforce SSL-only (pg_hba)

```bash
docker exec -it pg_db cp /var/lib/postgresql/data/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf.bak
docker exec -it pg_db sed -i 's/^host all all all scram-sha-256/hostssl all all all scram-sha-256/' \
  /var/lib/postgresql/data/pg_hba.conf
docker exec -it pg_db psql -U postgres -c "SELECT pg_reload_conf();"
# Verify the edit took (exactly one hostssl catch-all, no errors):
docker exec -it pg_db psql -U postgres -c "SELECT line_number, type, database, user_name, address, auth_method, error FROM pg_hba_file_rules;"
```

Cert regeneration: after re-issuing `pg_ssl.crt`, a **`pg_reload_conf()` is sufficient**
(Postgres re-reads SSL files on reload, not only restart). Restart if you prefer a
clean cycle. All clients must re-pull the new `pg_ssl.crt`.

## App connection contract (what the code actually does)

Apps use libpq-style vars plus two custom ones — **not** `PG_HOST`/`PG_PW`:

```bash
PGHOST=pg_db            # container name on pg_net (VM IP for external clients)
PGPORT=5432
PGDATABASE=staging
PGUSER=<app role>       # see DATABASE ROLES below
PGPASSWORD=<...>
PG_SSLMODE=verify-full  # disable | require | verify-ca | verify-full
PG_SSL_PATH=/opt/resources/ssl/pg_ssl.crt
```

`utils/db/pg-pool.js` semantics (per app — see caveat):
- `require` → encrypted but **unverified** (`rejectUnauthorized: false`). Legacy default.
- `verify-ca` / `verify-full` → CA-pinned + verified; Node's TLS also checks the
  hostname against the SAN, so `pg_db` must be in the cert.
- **reports (pilot, target state for all apps): fail-closed** — a verify mode with a
  missing/unreadable CA **throws** instead of silently downgrading. Other apps still
  carry the old helper that downgrades with only a console warning — copying the
  reports fix to each app is part of the role rollout below.

Verification tests:

```bash
psql "host=<VM_IP> dbname=staging user=postgres sslmode=disable"      # expect: rejected
psql "host=<VM_IP> dbname=staging user=postgres sslmode=require"      # expect: connects
psql "host=<VM_IP> dbname=staging user=postgres sslmode=verify-full sslrootcert=pg_ssl.crt"  # expect: connects (verify-full also checks hostname; verify-ca does not)
```

------------------------------------------------------------------------

# DATABASE ROLES — retiring the shared superuser

**Current state:** incident-engine (`incident_engine_rw`), ops-dashboard
(`ops_dashboard_ro`), and reports (`reports_rw`, piloted 2026-07-27) use dedicated
least-privilege roles. **Every other app still connects as `postgres`** — each is a
full-DB blast radius and must be migrated.

The pattern (proven three times now; scripts to copy):
- `incident-engine/db/setup-owner-role.sql` — owner-role variant (app owns its schema)
- `ops-dashboard/db/setup-readonly-role.sql` — read-only variant
- `reports/db/setup-role.sql` — read-mostly + targeted writes variant, with a
  database-wide fail-closed allowlist audit

Per-app migration checklist (repeat for each remaining app):

1. Enumerate the app's schema/table reads and writes (grep `FROM|JOIN|INSERT|UPDATE`
   over its `.js`/`.sql`, plus the logger's `util.app_run_logs` INSERT that every app
   performs; check write targets for serial columns → sequence grants).
2. Write `db/setup-role.sql` in the app repo from the closest template; include the
   fail-closed audit block.
3. Fix the app's vendored `utils/db/pg-pool.js` to the fail-closed version (copy from
   reports) and set `PG_SSLMODE=verify-full` + the `/opt/resources/ssl:ro` mount in
   compose.
4. Apply: `docker exec -i pg_db psql -U postgres -d staging -v pw='<strong-pw>' -f - < db/setup-role.sql`
5. Swap `.env` `PGUSER`/`PGPASSWORD`, then smoke test grants (copy the pattern from the
   reports pilot: positive reads/writes, expected denials, `pg_stat_ssl` check) before
   the next scheduled run.
6. **Re-run each setup-role script after any staging DB reset** (grants die with the
   schema; roles survive) and re-run it BEFORE deploying code needing new grants.

Rollout order suggestion (blast radius, low → high): monday → part-source-pipeline →
acumatica_sync → hhm_rpp_siemens → hhm_rpp_ge → hhm_rpp_philips → data_acquisition
(save for last: most jobs, busiest schedule).

------------------------------------------------------------------------

# PER-APP ENTRYPOINT (verified matrix, 2026-07-27)

Standard script (gosu drop to `RUN_USER`, default `svc`):

```bash
#!/bin/bash
set -e
RUN_USER="${RUN_USER:-svc}"
export HOME="/home/$RUN_USER"
exec gosu "$RUN_USER" "$@"
```

| App | Entrypoint | Image compose runs | Status |
|---|---|---|---|
| data_acquisition | `docker/entrypoint.sh` | `data-acqu:staging` (compose build) | ✅ baked & used |
| hhm_rpp_ge | `docker/entrypoint.sh` | `hhm_rpp:staging` | ✅ baked & used — but image is built out-of-band (see RPP section) |
| hhm_rpp_philips / siemens | — (no Dockerfile) | `hhm_rpp:staging` (GE's image) | ✅ by reuse |
| monday | `entrypoint.sh` (root) | `monday:staging` (compose build) | ✅ baked & used |
| reports | `docker/entrypoint.sh` | `aux:staging` | ⚠️ tracked Dockerfile builds it, but under the `aux:staging` tag (see reports section) |
| part-source-pipeline | `entrypoint.sh` (root) | `psp:staging` (compose build) | ✅ baked & used |
| acumatica_sync | `entrypoint.sh` (root, tracked) | stock `node:lts` as `user: 105:987` | ⚠️ Dockerfile/entrypoint **unused** — adopt or delete (follow-up) |
| incident-engine | n/a | stock `node:lts`, `user: "105:987"` | by design (declarative drop, no gosu) |
| ops-dashboard | n/a | stock `node:lts`, `user: "105:987"` | by design |
| imprivata-poc | `docker/entrypoint.sh` (conditional gosu) | `imprivata-poc:local` | ✅ baked (runs as root when RUN_USER unset — PoC) |

------------------------------------------------------------------------

# SHARED SSH BUNDLE (/opt/resources/ssh)

Used by data_acquisition's SFTP/rsync jobs; mounted `- /opt/resources/ssh:/opt/resources/ssh:ro`.

```
/opt/resources/ssh/
├── config         # ssh client config
├── id_dev         # private key (referenced by .env SSH_KEY)
├── known_hosts    # accumulated, verified host keys
└── known_hosts.bak
```

**The working permission model (as verified live) is group-based — do not "tighten" it:**

```
config       664  <owner>:docker
id_dev       640  <owner>:docker    # group-read is REQUIRED: jobs run as svc, which
                                    # reads the key via docker-group membership.
                                    # chmod 600 breaks every SFTP/rsync job unless you
                                    # also chown the key to the container run user.
known_hosts  644  <owner>:docker    # read-only at runtime is fine (the mount is :ro;
                                    # lftp is configured with sftp:auto-confirm)
```

Provisioning a NEW server (the bundle never comes from git):

1. Copy `config`, `id_dev`, `known_hosts` from the existing server over scp (or restore
   from the secret store) into `/opt/resources/ssh/`.
2. `sudo chgrp -R docker /opt/resources/ssh && chmod 664 config && chmod 640 id_dev && chmod 644 known_hosts`
3. Never seed `known_hosts` with blind `ssh-keyscan` against production endpoints —
   carry over the existing verified file.

------------------------------------------------------------------------

# RPP APPS (hhm_rpp_ge / hhm_rpp_philips / hhm_rpp_siemens)

All three run the **same image, `hhm_rpp:staging`**, built from
`hhm_rpp_ge/docker/Dockerfile` (node:lts + gosu entrypoint + the same UID_* build args
as data_acquisition; no acquisition tooling). Philips/Siemens have no Dockerfile on
purpose. **None of the three compose files has a `build:` section** — `docker compose
build` is a no-op that "succeeds" while building nothing. Build explicitly, once, from
the GE repo, BEFORE first run of any RPP app:

```bash
cd /opt/apps/hhm_rpp_ge
docker build -f docker/Dockerfile -t hhm_rpp:staging \
  --build-arg DOCKER_GID=$(getent group docker | cut -d: -f3) \
  --build-arg UID_0=$(id -u svc) --build-arg UID_1=$(id -u jonathan-pope) \
  --build-arg UID_2=$(id -u matt-teixeira) .
```

Per app (GE shown; philips/siemens identical with their names):

```bash
git clone git@github.com:Matt-Teixeira/hhm_rpp_ge.git /opt/apps/hhm_rpp_ge
cd /opt/apps/hhm_rpp_ge
git switch -c STAGING_docker --track origin/STAGING_docker
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger
# .env: PG*/REDIS_* vars, RUN_USER=svc, DATA_STORE_DEV=/opt/resources/acqu_files, RUN_ENV
# Warm cache once:
docker compose run --rm app_tools bash -lc "npm ci --omit=dev --no-audit --no-fund"
```

------------------------------------------------------------------------

# ACUMATICA SYNC APP

```bash
git clone git@github.com:Matt-Teixeira/acumatica_table_pull.git /opt/apps/acumatica_sync
cd /opt/apps/acumatica_sync
git switch -c DEV_docker --track origin/DEV_docker
```

Runs **stock `node:lts` as `user: "105:987"`** (svc:docker — fixed 2026-07-27; it
previously ran as a human uid). The repo's tracked Dockerfile/`entrypoint.sh` are
currently **unused** — do NOT `docker build` here; it produces an image nothing runs.
Adopt-or-delete is a follow-up. The app loads `.env` itself via dotenv (compose
deliberately has no `env_file`, so `$expand`/`$format` in Acumatica URIs survive; the
compose CLI warnings about those vars are cosmetic).

```bash
docker compose run --rm app npm install     # warm cache (this app's pattern)
```

------------------------------------------------------------------------

# REPORTS APP

```bash
git clone git@github.com:Matt-Teixeira/reports.git /opt/apps/reports
cd /opt/apps/reports
git switch -c STAGING_docker --track origin/STAGING_docker
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

# Compose runs image `aux:staging` (historical shared-aux tag). It IS built from this
# repo's Dockerfile (baked entrypoint, svc uid 105 / docker gid 987 hardcoded) — the
# tag name is just legacy. Build it under the tag compose expects:
docker build -t aux:staging .

# DB role (pilot pattern — see DATABASE ROLES):
docker exec -i pg_db psql -U postgres -d staging -v pw='<strong-pw>' -f - < db/setup-role.sql
# .env: PGUSER=reports_rw, PGPASSWORD=<same pw>, PG_SSLMODE=verify-full,
#       PG_SSL_PATH=/opt/resources/ssl/pg_ssl.crt
# Compose already forces verify-full + mounts /opt/resources/ssl:ro.

docker compose run --rm app bash -lc "npm ci --omit=dev --no-audit --no-fund"   # warm cache
```

------------------------------------------------------------------------

# MONDAY APP

```bash
git clone git@github.com:Matt-Teixeira/monday.git /opt/apps/monday
cd /opt/apps/monday
git switch -c STAGING_docker --track origin/STAGING_docker
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

docker compose build          # real build -> monday:staging (Dockerfile, root entrypoint.sh,
                              # SVC_UID/DOCKER_GID args default 105/987 — override on a host with different ids)
docker compose run --rm app bash -lc "npm ci --omit=dev --no-audit --no-fund"
```

Note: the app reads `PGUSER` (`utils/db/pg-pool.js`); compose forces
`PG_SSLMODE=require` for now (switch to verify-full during its role migration).
`db/pgPool.js` and `utils/db/pg-pool copy.js` are dead files.

------------------------------------------------------------------------

# PART SOURCE PIPELINE APP

```bash
git clone git@github.com:Matt-Teixeira/part-source-pipeline.git /opt/apps/part-source-pipeline
cd /opt/apps/part-source-pipeline
git switch -c STAGING_docker --track origin/STAGING_docker
mkdir -p files && chmod -R g+rwX files && chgrp -R docker files
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

docker compose build          # real build -> psp:staging (root entrypoint.sh, args 105/987)
docker compose run --rm app bash -lc "npm ci --omit=dev --no-audit --no-fund"
```

Run-logs mapping is intentionally hyphen(host)/underscore(container) — the container
path must match `APP_NAME=part_source_pipeline` (the logger's write path).

------------------------------------------------------------------------

# INCIDENT-ENGINE APP

Cron-batch error→incident pipeline (stock `node:lts`, `user: "105:987"`, no Dockerfile).
Owns schema `incidents`; reads `util.app_run_logs` + `stats.acquisition_history`;
self-logs through a DB-enforced check-option view. Deploy **before ops-dashboard**
(its role script grants SELECT on `incidents.*`).

```bash
git clone git@github.com:Matt-Teixeira/incident-engine.git /opt/apps/incident-engine
cd /opt/apps/incident-engine          # tracks main
mkdir -p /opt/resources/node_mod_cache/incident-engine /opt/run-logs/incident-engine
cp .env.example .env
# PGUSER=incident_engine_rw, PG_SSLMODE=verify-full, PG_SSL_PATH=/opt/resources/ssl/pg_ssl.crt,
# RUN_LOGS_DIR=/opt/run-logs/incident-engine:/opt/run-logs/incident-engine

# Provision DB (superuser, IN THIS ORDER; re-run both after any staging DB reset):
docker exec -i pg_db psql -U postgres -d staging -f - < db/schema.sql
docker exec -i pg_db psql -U postgres -d staging -v pw='<strong-pw>' -f - < db/setup-owner-role.sql

docker compose run --rm app npm install
docker compose run --rm app node index.js materialize
docker compose run --rm app node index.js assess
docker compose run --rm app node index.js assess     # second pass proves idempotency
```

### Deploy worktree (the production run path — REQUIRED before installing its cron line)

```bash
git -C /opt/apps/incident-engine worktree add /opt/apps/incident-engine-deploy <reviewed-sha>
cp /opt/apps/incident-engine/.env /opt/apps/incident-engine-deploy/.env   # copied, NOT symlinked — rotate creds in both
# Update later: git -C /opt/apps/incident-engine-deploy fetch origin && git -C /opt/apps/incident-engine-deploy checkout <new-sha>
# Rollback = checkout a previous SHA.
```

Cron (see `docs/schedules.md`): `25,55 * * * * cd /opt/apps/incident-engine-deploy && docker compose run --rm app node index.js run`

------------------------------------------------------------------------

# OPS-DASHBOARD APP

**Long-running HTTP service** (the only one): `docker compose up -d`, not `run --rm`.
Read-only Express dashboard over `util.app_run_logs` on `:8080`, `restart:
unless-stopped`, stock `node:lts` as `user: "105:987"`.

```bash
git clone git@github.com:Matt-Teixeira/ops-dashboard.git /opt/apps/ops-dashboard
cd /opt/apps/ops-dashboard           # tracks main
mkdir -p /opt/resources/node_mod_cache/ops-dashboard /opt/run-logs/ops-dashboard
cp .env.example .env                 # PG_HOST=pg_db, SSL cert path, self-monitoring toggle

# Roles (superuser, once; incident-engine must already be deployed or the fail-closed
# script errors on the missing incidents.* grant targets):
docker exec -i pg_db psql -U postgres -d staging -v ro_pw='<strong-pw>' < db/setup-readonly-role.sql
# Only if SELF_LOG_ENABLED=true:
docker exec -i pg_db psql -U postgres -d staging -v rw_pw='<strong-pw>' < db/setup-writer-role.sql

docker compose run --rm app npm install
docker compose up -d
curl -s localhost:8080/healthz              # {"ok":true}
curl -s localhost:8080/api/jobs/latest      # 503 "warming" briefly, then 200
```

Re-run `setup-readonly-role.sql` after DB resets or before deploying endpoints needing
new grants (else 500 permission-denied). Port 8080 is published on all interfaces —
the NSG is the boundary; hardening (healthcheck, pinned image, auth proxy) is a
follow-up.

------------------------------------------------------------------------

# IMPRIVATA POC APP

Python PoC (paramiko + Imprivata PAS/CPAM SDK), fully self-contained: no `/opt`
resources, no `pg_net`, no DB. Tracks `main`. Read `docs/README-HANDOFF.md` +
`docs/runbook.md` first.

```bash
git clone git@github.com:Matt-Teixeira/imprivata-poc.git /opt/apps/imprivata-poc
cd /opt/apps/imprivata-poc
# 1) Vendor SDK wheel into sdk/ (gitignored; NEVER commit).
# 2) secrets/securelink.properties (gitignored; keep WRITABLE — the SDK rotates `secret`).
mkdir -p secrets output
cp .env.example .env
# .env MUST override SDK_WHEEL to the 3.2.0 wheel — the compose default still points
# at a stale 2.11.0 filename and the build fails without the override. Also set
# IMPRIVATA_CUSTOMER_NAME / IMPRIVATA_SITE_NAME / IMPRIVATA_REMOTE_PATH.
python3 preflight.py
docker compose build app_tools
docker compose run --rm app_tools bash -lc "python /workspace/check_prereqs.py"
docker compose run --rm app_tools bash -lc "python /workspace/poc_pull_file.py"
```

Entrypoint is a conditional gosu drop; with `RUN_USER` unset it runs as root with
`HOME=/workspace/scm-home` (bind-mounted SDK log persistence). Acceptable for a PoC;
resolve before any production use.

------------------------------------------------------------------------

# STEP 9: SCHEDULES

The complete, live crontab (owner: `matt-teixeira`) with the stagger design, the
incident-engine deploy-worktree requirement, the acquisition-v2 pause note, and
install/rollback commands lives in **`docs/schedules.md`** — treat that file as the
manifest and keep it in sync with `crontab -l`. Always snapshot before editing:

```bash
crontab -l > /opt/resources/backups/crontab-$(date +%Y%m%d-%H%M).txt
```

------------------------------------------------------------------------

# STEP 10: BACKUPS & LOG ROTATION

Scripts live in `/opt/resources/scripts/` (created 2026-07-27):

- **`backup.sh`** — nightly `pg_dump -Fc staging` (verified with `pg_restore --list`;
  >10 GB, ~30 min) + `SAVE`-then-copy of all four Redis RDBs. Local retention: 7 days
  pg / 14 days Redis under `/opt/resources/backups/`. **Local-only until an off-host
  target is provisioned** — add the sync step at the bottom of the script then.
- **`prune-run-logs.sh`** — nightly prune: repo-local `utils/logger/*-log.*.json`
  older than 14 days, `/opt/run-logs/<app>/*-log.*` older than 30 days. Summary to
  `/opt/run-logs/prune.log`.
- **`daemon.json.proposed`** — Docker json-file log rotation (50m × 3). Apply with
  sudo + `systemctl restart docker` in a quiet window (restarts all containers;
  affects newly created containers).
- **`proposed-crontab-additions.txt`** — the two cron lines to install for the above.

Restore test (do this once per server, and after any pg major upgrade):

```bash
docker exec pg_db createdb -U postgres restore_test
docker exec -i pg_db pg_restore -U postgres -d restore_test --no-owner < /opt/resources/backups/pg/staging-<date>.dump
docker exec pg_db psql -U postgres -d restore_test -c "SELECT count(*) FROM alert.models;"
docker exec pg_db dropdb -U postgres restore_test
```

------------------------------------------------------------------------

# FOLLOW-UPS (known debt, deliberately deferred)

1. **DB roles fleet rollout** — see DATABASE ROLES checklist; 7 apps still connect as
   `postgres` with `require`-mode (unverified) TLS.
2. **Redis `requirepass`** — configs and app clients; instances currently unauthenticated
   behind the NSG.
3. **Network exposure** — verify NSG rules for 5432 / 6379-6382 / 8080; consider
   unpublishing Redis host ports (apps use `redis_net`) and binding pg/dashboard to
   specific interfaces.
4. **Image pinning** — `node:lts` is mutable (v24 today); pin per-app
   (e.g. `node:22-bookworm`) on a planned cadence. `node:16.20.2` for the cred tool is
   EOL-pinned on purpose (compatibility).
5. **acumatica_sync Dockerfile** — adopt (build + gosu entrypoint like monday) or delete.
6. **reports image tag** — rename `aux:staging` → `reports:staging` in compose + build
   docs once nothing else consumes the aux tag.
7. **hhm_rpp build:** add a real `build:` block to hhm_rpp_ge's compose (with the arg
   plumbing) so `docker compose build` stops being a silent no-op.
8. **ops-dashboard hardening** — healthcheck, pinned image, reviewed-SHA deploy
   worktree, auth/TLS proxy if it ever leaves the private boundary.
9. **odd-jobs** — retire or bring up to conventions.
10. **PROD** — branches, runbook, data governance: all future work, none of it started.

------------------------------------------------------------------------

# ACCEPTANCE TEST

A reviewer who did not write this guide should be able to build a blank dev/staging VM
from it and demonstrate: every referenced file/branch/image exists; `docker compose
config` validates everywhere; Redis reports `appendonly=yes` from the mounted configs;
Postgres rejects non-SSL and passes the verify-full test; the RPP image exists before
any RPP job runs; each container runs as its intended uid:gid and can write its mounts;
one scheduled job from each family completes; `backup.sh` produces a dump that passes
the restore test; and a full host reboot brings back pg_db, Redis, ops-dashboard, and
the schedules without manual help.
