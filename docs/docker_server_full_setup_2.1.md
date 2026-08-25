# Docker Server Full Setup 2.1 (reconciled 2026-08-18; paradigm notes 2026-08-25)

This guide builds an acquisition server — **dev, staging, or (future) prod** — from
scratch. The **staging server (acq-vm-0) is the reference copy**: every command,
image tag, branch, permission, and schedule below was verified against that live
server on 2026-08-18, at the end of the August hardening plan
(`PLAN_OF_ATTACK_2026-08.md`; finding IDs like SEC-05 or DB-01 refer to
`AUDIT_RECONCILIATION_FINDINGS_2026-08-14.md`). When this document and a server
disagree, one of them is wrong — fix the drift, then fix the document.

> **⚠️ PARADIGM MIGRATION IN PROGRESS (since 2026-08-24).** The fleet is adopting the
> dev/release paradigm (`data_acquisition/docs/migration_CLAUDE.md` Parts 1+3): the
> editable git clone lives in `~/apps/<app>`, and `/opt/apps/<app>` becomes
> **build output produced only by `build-release.sh`** — not a checkout. For a
> MIGRATED app, this document's app-level instructions are superseded: `IMAGE_TAG`
> → `<app>:${USER_ID}` tags (dev = username, release = `svc`), `RUN_ENV` log routing
> → a `LOG_DIR` compose mount with `#RELEASE:` overrides, the shared
> `/opt/resources/node_mod_cache` → in-tree per-copy `node_modules`, and every run
> carries `RELEASE_SHA` provenance. This doc stays authoritative for **server-wide**
> provisioning (users, groups, Postgres/Redis, secrets, networks, backups).
> Migrated so far: **data_acquisition (2026-08-24)** — its sections below are
> updated; other apps' sections still describe their live pre-paradigm state and
> get corrected as each one migrates.

**Read this first — per-server identity.** The document is one recipe for all three
server types. Wherever a command says `<DB_NAME>` (or another `<...>` placeholder),
substitute this server's value; wherever a concrete value appears, the text says
which server it belongs to. The identity table:

| | dev server | staging (acq-vm-0) | prod (future) |
|---|---|---|---|
| App database `<DB_NAME>` | `dev` | `staging` | `prod` |
| App-repo branch | `DEV_docker` | `STAGING_docker` | `PROD_docker` (doesn't exist yet) |
| Admin-repo branch (redis-admin, pg_manage_v2) | `DEV` | `STAGING` | TBD |
| `RUN_ENV` (logger routing only; **legacy apps** — migrated apps use `LOG_DIR`) | `dev`* | `staging` | `prod` |
| `IMAGE_TAG` (**legacy apps** — migrated apps tag by `USER_ID`: dev = username, release = `svc`) | operator's choice, e.g. `dev` | `staging` | TBD |
| `PG_DB` for maintenance scripts | `dev` | `staging` (default) | `prod` |

\* `RUN_ENV=dev` routes per-run logs into each repo instead of `/opt/run-logs/` —
that is a *routing choice*, not tied to the server type; pick where you want logs.
Every other value in this doc (uids, gids, IPs, secrets) is **per-host** and lives
only in untracked `.env` files — see CONVENTIONS.

**What changed since 2.0** (2026-07-27): database container under version control
(tracked compose, no password in metadata); Redis ports removed from the host and
**auth enabled**; nightly backups + pruning + partition watchdog actually installed;
`RUN_ENV=staging` fleet-wide with central run logs; the fail-loudly outcome contract
(`run_outcome/v1`) on all six job apps; every image now built by Compose; allowlist
`.dockerignore`s; container log caps; maintenance scripts moved into their owning
repos; `saved_files` 48-hour retention restored; odd-jobs documented as the partition
maintenance owner.

**Scope:** dev and staging servers. **No PROD server exists yet** — `PROD_docker`
branches, a prod cutover runbook, and prod data-governance decisions are future work,
deliberately out of scope (Phase 4j).

------------------------------------------------------------------------

# CONVENTIONS — the server as it really is

There is no single `ENV` knob. A server's identity is set by four independent axes —
set each one explicitly and don't assume they match:

| Axis | Value on acq-vm-0 | Controls |
|---|---|---|
| Git branch (per repo, table below) | `STAGING_docker` / `STAGING` / `main` | which code runs |
| Image tags | `:staging` on legacy apps (`IMAGE_TAG` in each `.env`); **migrated apps: `<app>:${USER_ID}`** (`data-acqu:svc` in production) | which image compose runs |
| Compose volume vars | `_DEV`-suffixed names (`NODE_MOD_CACHE_DEV`, `DATA_STORE_DEV`) — migrated apps drop `NODE_MOD_CACHE_DEV` (in-tree deps) | where caches/files live — the *names* are fixed in compose; point their *values* wherever this server stores data |
| `RUN_ENV` in `.env` | `staging` on legacy apps; **retired in migrated apps** (the `LOG_DIR` mount routes logs; fails safe to the dev path) | **logger file routing only** — not deployment |

Database: the single local Postgres serves **one app database, `<DB_NAME>`** (from
the identity table: `dev`/`staging`/`prod`), for every app (`PGDATABASE=<DB_NAME>`).
Create exactly one — a second database that "matches the other server's name" is how
apps end up pointed at an empty DB (the pre-August monday failure).

**Host identity lives only in untracked `.env` files** (convention since 2026-08-06):
numeric uid/gid values (`UID_0/1/2`, `DOCKER_GID`, `SVC_UID`), image tags
(`IMAGE_TAG`), and secrets never appear in tracked files. Committed `.env.example`
files carry **placeholders, not staging's real numbers** — a real value in an example
would silently poison a new server whose ids differ (REL-07). Builds fail loudly when
the variables are unset; that is deliberate. The same fail-loud rule applies to file
bind-mounts: long-form syntax with `create_host_path: false` everywhere a missing
host file must stop the build instead of being auto-created as an empty directory.

**Branch map (clone target per repo; upstreams are set — `git pull` works
everywhere).** The env-branch repos follow the identity table: `DEV_docker`/`DEV` on
a dev server, `STAGING_docker`/`STAGING` on staging (shown), `PROD_docker` when prod
exists. The `main` repos are the same branch on every server.

| Repo | Branch on acq-vm-0 (staging) |
|---|---|
| acumatica_sync, hhm_rpp_ge, hhm_rpp_philips, hhm_rpp_siemens, monday, reports, part-source-pipeline | `STAGING_docker` |
| data_acquisition (**migrated**) | `STAGING_docker` — but the checkout lives at `~/apps/data_acquisition`; `/opt/apps/data_acquisition` is `build-release.sh` output, NOT a repo |
| redis-admin, pg_manage_v2 | `STAGING` |
| incident-engine, ops-dashboard, acquisition-v2, imprivata-poc | `main` (no env branches) |
| odd-jobs | **not a git checkout on this box** — Jonathan deploys it; see PARTITION MAINTENANCE |

Other standing conventions:

- **Vendored `utils/`.** The shared library (logger, db, vpn, sh helpers) is vendored
  into each app repo. Never clone the old `AvanteHS-RTT/utils` repo. (Exception:
  acumatica_sync's `utils/` holds only its own `queries.js`.)
- **Per-app entrypoint.** The gosu user-drop entrypoint is baked into each app image
  from a tracked `docker/entrypoint.sh` or root `entrypoint.sh` (matrix below).
- **Run logs — legacy apps.** The vendored logger (`utils/logger/log.js`) switches on
  `RUN_ENV`:
  - `dev` → per-run JSON into **`<repo>/utils/logger/`** (gitignored)
  - `staging`/anything else (including unset) → **`/opt/run-logs/<APP_NAME>/`**
  Note the else-branch **fails unsafe** (missing var → production path); the paradigm
  inverts this. Every job also self-logs a row into `util.app_run_logs` regardless
  (that's what ops-dashboard and incident-engine read). Nit: psp leaves `RUN_ENV`
  unset and lands centrally via the else-branch — same outcome, but set it explicitly
  on a new build.
- **Run logs — migrated apps** (data_acquisition): the logger always writes the fixed
  container path `./utils/logger/logs/`, and the compose mount
  `${LOG_DIR:-./utils/logger/logs}` decides the host destination — dev path by
  default (**fails safe**), `/opt/run-logs/<app>` in a release via `#RELEASE:LOG_DIR`.
- **`RUN_LOGS_DIR` format (legacy).** Where an app's `.env` still defines it
  (incident-engine), it is a **full `host:container` bind spec** consumed verbatim by
  a compose volume entry: `RUN_LOGS_DIR=/opt/run-logs/<app>:/opt/run-logs/<app>`.
  Retired in migrated apps in favor of `LOG_DIR` above.
- **Maintenance scripts live in the repo that owns their subject** (2026-08-18):
  database scripts in `pg_manage_v2/scripts/`, Redis scripts and host-setup files in
  `redis-admin/`, the cross-app run-log prune in `data_acquisition/scripts/`.
  `/opt/resources/scripts/` is **not** a script home anymore.
- **Secrets on disk follow the root-only-file pattern**: machine-generated value in a
  file under a `700 root:root` directory, owned by the container uid that must read
  it, bind-mounted as a single file. Host uid-999 (`dd-agent`) collides with the
  container `postgres`/`redis` uid — the root-only parent directory is what blocks it
  (SEC-06). Current instances: `/opt/resources/ssl/private/pg_ssl.key`,
  `/opt/resources/secrets/redis_auth.conf`.
- **Container log caps are per-service in tracked compose files** — `json-file`,
  `max-size: 10m`, `max-file: 3` on every long-running service (pg_db, the four
  Redis, ops-dashboard). Never via `/etc/docker/daemon.json`: a host file is exactly
  the kind of dependency a rebuild forgets, and the daemon restart it needs is not
  (OPS-02).

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

Record the numeric ids — they feed every app's untracked `.env` (see Host identity
convention above; never bake them into tracked files):

```bash
id svc                  # acq-vm-0: uid=105
id matt-teixeira        # acq-vm-0: uid=1006
id jonathan-pope        # acq-vm-0: uid=1001
getent group docker     # acq-vm-0: gid=987
```

> ⚠️ Two repos still hardcode `105:987` outside `.env` (compose `user:` on
> incident-engine/ops-dashboard; literals in reports' Dockerfile). On a new server,
> either make the ids match or update those files — then run each app's
> write-permission smoke test. Migrating those stragglers to the `.env` convention is
> tracked debt.

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

# STEP 1.4: GIT, GITHUB ACCESS & THE INFRA CLONES

Nothing below works without git, a database client, and the ability to clone the
private repos — a blank VM has none of these (audit A21-01/03/13).

```bash
sudo apt install -y git postgresql-client

git config --global user.email "you.guy@avantehs.com"
git config --global user.name  "You Guy"

# GitHub access: enroll a key for this server (or restore the previous server's
# deploy key from the secret store into ~/.ssh/).
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"
# Add the public key to GitHub (account key or per-repo deploy keys), then:
ssh -T git@github.com    # accept github.com's host key AFTER checking its
                         # fingerprint against https://docs.github.com/en/authentication
                         # /keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
```

Clone the two infra repos now — STEP 2 (database) and STEP 3 (Redis) run compose
from inside them, before the app-repo steps:

```bash
git clone git@github.com:Matt-Teixeira/redis-admin.git /opt/apps/redis-admin
git -C /opt/apps/redis-admin switch <branch per the identity table>     # STAGING on acq-vm-0
git clone git@github.com:Matt-Teixeira/pg_manage_v2.git /opt/apps/pg_manage_v2
git -C /opt/apps/pg_manage_v2 switch <branch per the identity table>    # STAGING on acq-vm-0
```

------------------------------------------------------------------------

# STEP 2: DATABASE (pg_db — tracked compose, pg_manage_v2/infra/pg_db)

The database container is **defined in git**: `pg_manage_v2/infra/pg_db/
docker-compose.yaml`, with its recreate procedure in `RUNBOOK.md` beside it (executed
2026-08-18; SEC-05/06, DB-04/06). Never `docker run` it by hand again.

What the tracked definition provides:
- reuses the **external** named volume `postgres_data` and network `pg_net` — a
  container swap never touches data;
- **no password in container metadata** (SEC-05): postgres:16 only requires
  `POSTGRES_PASSWORD*` when initializing an *empty* volume — on a running server the
  role password lives in the database catalog (rotate with `\password`, never in
  compose). The compose file carries commented-out secret plumbing for the
  new-server case only;
- TLS cert/key bind-mounted **long-form with `create_host_path: false`** (a missing
  key fails `up` loudly instead of Docker fabricating an empty directory — REL-09);
- healthcheck (`pg_isready`), `shared_preload_libraries=pg_stat_statements` (DB-06),
  and the standard log cap.

### New server, empty volume

```bash
docker network create pg_net
docker volume create postgres_data

# Superuser password: root-only file, generated, never typed or displayed
sudo install -m 600 -o root -g root /dev/null /root/pg_superuser_pw
sudo sh -c 'head -c 32 /dev/urandom | base64 | tr -d "/+=" | head -c 32 > /root/pg_superuser_pw'

# In pg_manage_v2/infra/pg_db/docker-compose.yaml, uncomment the environment: and
# secrets: blocks (POSTGRES_PASSWORD_FILE) — initialization genuinely needs them.
# Generate the TLS material FIRST (see DATABASE SSL SETUP below), then:
cd /opt/apps/pg_manage_v2/infra/pg_db
docker compose config --quiet && docker compose up -d

until docker exec pg_db pg_isready -U postgres -q; do sleep 1; done && echo ready
docker exec -it pg_db psql -U postgres -c "CREATE DATABASE <DB_NAME>;   -- dev / staging / prod per the identity table"
# Then RE-COMMENT the secret blocks and recreate once (docker compose up -d), so the
# running container carries no password reference (SEC-05). Keep /root/pg_superuser_pw
# as the break-glass copy.
```

**This stack uses a single `<DB_NAME>` database for every app** — do not also create
the *other* server type's name (a `dev` database on staging, a `staging` database on
dev): a second database that nothing should point at is exactly how an app ends up
silently pointed at empty tables (the pre-August monday failure).

### Existing server (container swap / config change)

Follow `pg_manage_v2/infra/pg_db/RUNBOOK.md`. Short form: fresh backup verified →
`docker stop pg_db && docker rm pg_db` → `docker compose up -d` → the runbook's
verification gates (healthy; zero `POSTGRES_PASSWORD` in `docker inspect`; `SELECT 1`;
non-SSL rejected; dd-agent denied on the key; one cron cycle lands in
`util.app_run_logs`). Downtime is under a minute; the volume is external.

### Enforce SSL-only (pg_hba — once per new volume)

```bash
docker exec -it pg_db cp /var/lib/postgresql/data/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf.bak
docker exec -it pg_db sed -i 's/^host all all all scram-sha-256/hostssl all all all scram-sha-256/' \
  /var/lib/postgresql/data/pg_hba.conf
docker exec -it pg_db psql -U postgres -c "SELECT pg_reload_conf();"
# Verify the edit took (exactly one hostssl catch-all, no errors):
docker exec -it pg_db psql -U postgres -c "SELECT line_number, type, database, user_name, address, auth_method, error FROM pg_hba_file_rules;"
```

The stock `trust` rules for the local socket and loopback (127.0.0.1/::1) above the
catch-all are **retained deliberately**: every `docker exec pg_db psql -U postgres`
maintenance command in this document relies on them, and loopback inside the
container is only reachable with docker-group access, which is root-equivalent on
the host anyway. Do not "harden" them away — the `hostssl` catch-all is the rule
governing network clients (audit A21-14).

### Query statistics (DB-06)

`pg_stat_statements` is preloaded by the tracked compose. Enable it once per database:

```bash
docker exec pg_db psql -U postgres -d <DB_NAME> -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
```

------------------------------------------------------------------------

# STEP 3: REDIS (redis-admin — ports off, auth on)

**The standard build is all four instances together** — one `docker compose up -d`
in redis-admin creates the full set on the dedicated `redis-admin_redis_net` bridge.
Never bring up a subset; apps and odd-jobs resolve these by container name:

| Instance | Consumers | Auth |
|---|---|---|
| `redis_dev-0-4` | the four job apps (live acquisition state) | **required** |
| `redis-PROD` | none currently | **required** |
| `redis_dev-0-5` | none (spare) | **required** |
| `redis-STAGING` | **odd-jobs** | **required** (standardized 2026-08-19 — see odd-jobs caveat below) |

**No host ports are published** (REDIS-01): everything reaches Redis over the docker
network. Auth: **all four instances** load `requirepass` at boot from a root-only
host file via an `include` in their tracked configs (REDIS-01 rollout 2026-08-18;
extended to `redis-STAGING` 2026-08-19). ⚠️ odd-jobs caveat: redis-STAGING's
consumer is odd-jobs, whose Redis client historically had **no auth support** —
the pre-2026-08-19 exception existed for it. An unauthenticated client fails fast
with NOAUTH; coordinate odd-jobs' connectivity with Jonathan.

Order matters and is proven, not theoretical: **a client configured with a password
against a passwordless server hangs in an infinite reconnect loop** (node-redis v4,
tested 2026-08-18); the reverse fails fast with a clean NOAUTH error. So on any
rollout or rollback: **server first, app `.env`s immediately after.**

```bash
# 1. Kernel settings Redis needs (once per host; files are tracked in the repo,
#    cloned in STEP 1.4)
cd /opt/apps/redis-admin
sudo cp host-setup/90-redis.conf /etc/sysctl.d/ && sudo sysctl --system
sudo cp host-setup/disable-thp.service /etc/systemd/system/ && sudo systemctl enable --now disable-thp.service

# 2. Auth secret FIRST — compose fails loudly without it (create_host_path: false)
sudo install -d -m 700 -o root -g root /opt/resources/secrets
sudo sh -c 'umask 277; printf "requirepass %s\n" "$(head -c 32 /dev/urandom | base64 | tr -d "/+=" | head -c 32)" > /opt/resources/secrets/redis_auth.conf'
sudo chown 999:root /opt/resources/secrets/redis_auth.conf   # 999 = container redis uid; the 700 dir blocks host uid-999 (dd-agent)
sudo chmod 400 /opt/resources/secrets/redis_auth.conf

# 3. Instances up
# Create .env (gitignored): REDIS_SUBNET, REDIS_GATEWAY, REDIS_{PROD,STAGING,DEV04,DEV05}_IP
docker compose config --quiet && docker compose up -d
docker compose ps        # all four (healthy) — healthchecks authenticate and demand a literal PONG

# The generated password is now the ONLY credential the instances accept, and every
# consuming app MUST carry it as REDIS_PW in its untracked .env. Read it when needed:
sudo cat /opt/resources/secrets/redis_auth.conf   # value after "requirepass"

# 4. Give the consuming apps the password (after their .envs exist — see app steps).
# Prefer the script over hand-copying — it propagates REDIS_PW into the four job-app
# .envs and verifies auth end-to-end without echoing the value:
sudo scripts/activate_redis_auth.sh
```

**Verify the configs actually loaded** — not optional. Compose bind-mounts
`./config/<name>.config` over `/usr/local/etc/redis/redis.conf` long-form with
`create_host_path: false`. (History: the mounts once pointed at nonexistent paths;
Docker auto-created empty dirs and Redis silently ran on defaults with AOF off for
months. Fixed 2026-07-27; the fail-loud mount style exists because of it.)

```bash
for r in redis-PROD redis-STAGING redis_dev-0-4 redis_dev-0-5; do
  echo "$r: $(docker exec $r sh -c 'redis-cli -a "$(awk "/^requirepass/{print \$2}" /usr/local/etc/redis/auth.conf)" --no-auth-warning CONFIG GET appendonly' | tail -1)"   # expect yes
done
docker exec redis_dev-0-4 redis-cli PING    # expect NOAUTH error — auth is live
ss -ltn | grep -E ':(6379|6380|6381|6382)' || echo "no redis host listeners (correct)"
```

**Human access** (redis-cli never prompts — it connects, then refuses commands until
you authenticate; full patterns in redis-admin README → Connecting):

```bash
docker exec -it redis_dev-0-4 sh -c 'redis-cli -a "$(awk "/^requirepass/{print \$2}" /usr/local/etc/redis/auth.conf)" --no-auth-warning'
sudo cat /opt/resources/secrets/redis_auth.conf     # the value itself, for GUI clients etc.
```

> ⚠️ **Restore/seed procedures can silently produce an EMPTY Redis** (REDIS-05): if
> Redis boots with `appendonly yes` and no AOF manifest in `/data`, it does **not**
> load `dump.rdb`. When enabling AOF on a live instance, follow the order in
> redis-admin README → Config files (`CONFIG SET appendonly yes` first, wait for the
> rewrite, then recreate). When seeding from an RDB dump, use the temp-server
> procedure embedded in STEP 4. In both cases verify with `DBSIZE` against the
> source count.

------------------------------------------------------------------------

# STEP 4: SEED REDIS STATE (new server only)

Rescoped: this seeds a **new dev/staging server** from an existing source; it is not a
production cutover runbook (none exists yet — write and rehearse one before any PROD
build).

```bash
# On the SOURCE server — the script is tracked as data_acquisition/scripts/
# redis_migrate.sh (since 2026-08-20); copy it over or run it from a checkout:
./redis_migrate.sh                      # ships latest RDB to ~/redis_dumps/ on the target

# On the target server:
DUMP=$(ls -t ~/redis_dumps/redis-PROD-dump-*.rdb | head -1)
echo "Loading: $DUMP"

# Record the source key count for verification, then stop targets BEFORE touching
# their volumes (a running Redis rewrites its RDB on shutdown and would clobber
# the seed):
docker stop redis-PROD redis-STAGING redis_dev-0-4

for pair in redis-PROD:prod_data redis-STAGING:staging_data redis_dev-0-4:dev04_data; do
  name=${pair%%:*}; vol=redis-admin_${pair##*:}

  # 1. Clear the AOF the fresh build created, place the dump:
  docker run --rm -v $vol:/data -v ~/redis_dumps:/seed:ro redis:7-alpine \
    sh -c "rm -rf /data/appendonlydir /data/dump.rdb \
           && cp /seed/$(basename "$DUMP") /data/dump.rdb \
           && chown redis:redis /data/dump.rdb"

  # 2. Load it in a throwaway server with AOF OFF (the only state in which
  #    dump.rdb is actually read), then convert the loaded dataset to AOF:
  docker run -d --rm --name seed -v $vol:/data redis:7-alpine \
    redis-server --appendonly no --save ''
  sleep 2
  docker exec seed redis-cli DBSIZE      # must equal the source count
  docker exec seed redis-cli CONFIG SET appendonly yes
  docker exec seed redis-cli INFO persistence | grep aof_rewrite_in_progress  # expect :0
  docker stop seed                       # --rm removes it

  # 3. The real container now boots from the generated AOF manifest:
  docker start $name
done

# DBSIZE per instance (all four are auth'd — use the -a pattern from STEP 3)
# must equal the source count. dev-0-5 (spare) is deliberately left empty.
```

> ⚠️ **Why the temp-server dance instead of `docker cp` + start** (rehearsed
> 2026-08-19): after STEP 3 the targets have ALWAYS already run with AOF enabled —
> the tracked configs say `appendonly yes`, so first boot creates `appendonlydir/`
> immediately. From there, a copied `dump.rdb` is ignored on start (AOF wins), and
> the once-documented "fix" of deleting `appendonlydir/` before starting is worse:
> per REDIS-05, `appendonly yes` with no AOF manifest boots EMPTY without reading
> `dump.rdb` at all. The dump is only loaded by a server started with
> `--appendonly no`; `CONFIG SET appendonly yes` then writes the manifest the real
> container needs. The throwaway seeder runs unauthenticated but publishes no
> ports and dies before the real instance starts.

------------------------------------------------------------------------

# STEP 5: DATABASE SCHEMA & DATA SEEDING (pg_manage_v2)

```bash
cd /opt/apps/pg_manage_v2        # cloned + branch-switched in STEP 1.4
# Create .env with SRC_* (Azure source) and DST_* (local pg_db) connection vars.
docker build -t pg_manage .
```

This repo also owns the pg_db runtime definition (`infra/pg_db/` — STEP 2) and the
database maintenance scripts (`scripts/backup.sh`, `scripts/check-partition-horizon.sh`
— see BACKUPS and PARTITION MAINTENANCE).

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
docker run --rm --network pg_net --env-file .env -v "$PWD":/app -w /app \
  --entrypoint bash pg_manage -lc './scripts/azure_to_local_migration/3_pgdump_data_to_local_time_cond.sh'
# Month-to-date (first minute of current month → now):
docker run --rm --network pg_net --env-file .env -v "$PWD":/app -w /app \
  --entrypoint bash pg_manage -lc './scripts/azure_to_local_migration/4_pgdump_data_to_local_month_to_date.sh'
```

### 5.4 Verify before pointing jobs at it

```bash
# Spot-check row counts per critical table against the source, e.g.:
psql -h localhost -U postgres -d <DB_NAME> -c "SELECT count(*) FROM alert.models;"
```

> DB-08 resolved as a non-issue (2026-08-19): the once-flagged "missing" `mag.ge_mm`
> table never existed and no code references it — every real query uses
> `mag.ge_mm3`/`ge_mm4` (+ `_units`), which exist and are populated. The only
> occurrence anywhere is a commented sanity example in reports/db/setup-role.sql.
> (An earlier claim that schema `edu` was empty is wrong and was corrected by audit
> A21-05 — `edu` holds ~20 tables with live data.)

### 5.5 The systems inventory drifts — decide the sync policy (B0a)

`public.systems` (and its flags: active systems, credentials, host IPs) was seeded
once and then **drifts silently from prod**: prod retires/adds systems and staging
never hears about it. Two consequences observed in August: staging polled 6 systems
prod had retired, and prod still lists 14 systems dark since July 7. **Before relying
on a rebuilt server, reconcile the inventory against prod and record the delta** —
snapshot pattern: `/opt/resources/backups/systems-flags-snapshot-<date>.txt`. A named,
scheduled sync (or an explicit "manual, on change" policy with an owner) is an open
decision; the acceptance test includes the check either way.

### 5.6 Table updates changelog

Schema changes made on this stack **after** the source data was seeded, kept here in
one place **so they can be applied to a freshly seeded server** (in particular: run
this against the prod database when the prod server is initiated). Already applied to
acq-vm-0. Apply in one pass with `ON_ERROR_STOP`; note that
`CREATE TABLE IF NOT EXISTS` / `ADD COLUMN IF NOT EXISTS` make the block re-runnable
but never *upgrade* an existing table whose shape drifted — verify, don't assume.

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

When a future schema change lands, **append it here** (dated) — this section is the
single changelog that a new server's seeded database gets replayed against.

### 5.7 Re-encrypt migrated credentials (every seed — learned the hard way 2026-08-20)

Seeded `hhm_credentials` rows are ciphertext under the **source server's legacy
scheme**; this server's jobs decrypt with the AES/`APP_SECRET` scheme. Until
converted, every credentialed HHM acquisition fails with
`Invalid authentication tag length: 0` (the 2026-08-19 migration ran ~20 h in that
state — 9 systems succeeding instead of ~65). After seeding, snapshot then convert:

```bash
docker exec pg_db pg_dump -U postgres -d <DB_NAME> -t hhm_credentials -Fc \
  > /opt/resources/backups/pg/hhm_credentials-pre-reencrypt-$(date +%Y%m%d-%H%M).dump
cd /opt/apps/data_acquisition && ./run_scripts/update_db_creds.sh   # see STEP 8
```

Run it **exactly once per seed** — it has no already-converted guard, and a second
run would feed new-format ciphertext to the legacy decryptor and destroy the
credentials (old format = uniform 32-char values; converted = 68–80 chars —
`SELECT length(password_enc), count(*) FROM hhm_credentials GROUP BY 1` tells you
which state you're in). Its stdout prints decrypted credentials — private terminal,
no redirection. Verify on the next cron burst: zero `credential_decrypt` errors in
`util.app_run_logs`.

### 5.8 Import production host keys (every seed that carries systems inventory)

A migrated inventory references hosts this server may never have keyed; strict host-key
checking then fails those systems every cycle (2026-08-19: 905
`No ED25519 host key is known` errors in 17 h). **Before the first cron burst after
seeding**, push the source server's verified `known_hosts` — run
`scripts/known_hosts_migrate.sh` **on the source server** (dry-run first). Full
procedure and verification: SHARED SSH BUNDLE → "Incremental import after a migration".

### 5.9 Re-provision app DB schemas & roles (every reseed — learned the hard way 2026-08-21)

Recreating schemas/tables **destroys every grant on them**, and app-owned schemas
that don't exist in the source DB (`incidents`) vanish entirely. Roles survive (they
are cluster-level) — which makes the breakage *silent*: after the 2026-08-19 reseed,
incident-engine failed every run for two days (`permission denied for schema util`,
unable to even self-log to the DB), ops-dashboard served data frozen at the pre-wipe
timestamp while returning 200s (`"stale":"last refresh failed: permission denied"`
in the payload), and reports_rw sat broken-but-latent (no schedule on this box).

**Step 0 — make sure the role password files exist.** The scripts read each role's
password from a root-only file (`/root/<role>_pw`, DATABASE ROLES pattern). These
files are host state — a rebuilt/never-provisioned host won't have them (found
missing on acq-vm-0, 2026-08-21). No password is lost when they're absent: the live
value is in each app's untracked `.env`. Recreate them from there — values flow
through pipes only, never shell history or `ps`, and **nothing is rotated** (the
scripts will re-set each role to the password the apps already use):

```bash
sudo ls -l /root/incident_engine_rw_pw /root/ops_dashboard_ro_pw /root/ops_dashboard_rw_pw /root/reports_rw_pw
# For any file MISSING (source key is PGPASSWORD, except the ops-dashboard
# writer, which lives in PG_WRITER_PASSWORD):
sudo install -m 600 -o root -g root /dev/null /root/incident_engine_rw_pw
grep '^PGPASSWORD=' /opt/apps/incident-engine/.env | cut -d= -f2- | sudo tee /root/incident_engine_rw_pw >/dev/null
sudo install -m 600 -o root -g root /dev/null /root/ops_dashboard_ro_pw
grep '^PGPASSWORD=' /opt/apps/ops-dashboard/.env | cut -d= -f2- | sudo tee /root/ops_dashboard_ro_pw >/dev/null
sudo install -m 600 -o root -g root /dev/null /root/ops_dashboard_rw_pw
grep '^PG_WRITER_PASSWORD=' /opt/apps/ops-dashboard/.env | cut -d= -f2- | sudo tee /root/ops_dashboard_rw_pw >/dev/null
sudo install -m 600 -o root -g root /dev/null /root/reports_rw_pw
grep '^PGPASSWORD=' /opt/apps/reports/.env | cut -d= -f2- | sudo tee /root/reports_rw_pw >/dev/null
sudo sh -c 'wc -c /root/*_pw'    # every file non-empty (~20-50 bytes) before proceeding
```

**Steps 1–5 — re-run the provisioning scripts, in this order** (incident-engine
before ops-dashboard: its role script grants SELECT on `incidents.*`; the writer
role is required whenever ops-dashboard runs `SELF_LOG_ENABLED=true`, which is the
standard config). Stop on any `ERROR` line; the reports script is non-transactional
(DB-03) — read a midway error rather than re-running blind:

```bash
docker exec -i pg_db psql -U postgres -d <DB_NAME> -f - < /opt/apps/incident-engine/db/schema.sql
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v pw="$(sudo cat /root/incident_engine_rw_pw)" -f - < /opt/apps/incident-engine/db/setup-owner-role.sql
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v ro_pw="$(sudo cat /root/ops_dashboard_ro_pw)" < /opt/apps/ops-dashboard/db/setup-readonly-role.sql
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v rw_pw="$(sudo cat /root/ops_dashboard_rw_pw)" < /opt/apps/ops-dashboard/db/setup-writer-role.sql
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v pw="$(sudo cat /root/reports_rw_pw)" -f - < /opt/apps/reports/db/setup-role.sql
```

**Verify** (executed and confirmed on acq-vm-0, 2026-08-21) — note each role's
*intended* shape differs; test what it should have, not blanket SELECT:

```bash
docker exec pg_db psql -U postgres -d <DB_NAME> -tAc "
SELECT r, has_schema_privilege(r,'util','USAGE'),
       has_table_privilege(r,'util.app_run_logs','SELECT'),
       has_table_privilege(r,'util.app_run_logs','INSERT')
FROM unnest(ARRAY['incident_engine_rw','ops_dashboard_ro','reports_rw']) r"
# expect: incident_engine_rw t|t|f · ops_dashboard_ro t|t|f · reports_rw t|f|t
# (reports_rw is INSERT-not-SELECT by design; ops_dashboard_rw has NO table
#  grants by design — it only executes the writer function:)
docker exec pg_db psql -U postgres -d <DB_NAME> -tAc "
SELECT has_function_privilege('ops_dashboard_rw','ops.log_ops_dashboard_run(uuid,json,json)','EXECUTE')"   # t
```

Then: the next `:25/:55` incident-engine run logs an outcome to `util.app_run_logs`,
and ops-dashboard's `/api/jobs/latest` shows a current `asOf` with no `stale` field
(its refresh recovers unaided within minutes). This list must grow with the
DATABASE ROLES rollout — add a Step-0 line and a script line here for every future
role.

------------------------------------------------------------------------

# STEP 6: DATA ACQUISITION APP SETUP (paradigm — migrated 2026-08-24)

data_acquisition follows the dev/release paradigm: the checkout goes in the
operator's home, and `/opt/apps/data_acquisition` is produced by `build-release.sh`,
never cloned. Full conventions: the repo's own `CLAUDE.md` +
`docs/migration_CLAUDE.md` Parts 1+3.

```bash
mkdir -p ~/apps
git clone git@github.com:Matt-Teixeira/data_acquisition.git ~/apps/data_acquisition
cd ~/apps/data_acquisition
git switch -c STAGING_docker --track origin/STAGING_docker
```

### 6.1 `.env`

Copy from the previous server / secret store into the CLONE; `build-release.sh`
transforms a copy of it for the release. Full key list (names; values from the
secret store; template with `#RELEASE:` markers = tracked `.env.example`):

```
APP_NAME USER_ID LOGGER_MODE LOG_DIR APP_SECRET      # identity keys carry #RELEASE: overrides
PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD PG_SSLMODE PG_SSL_PATH
REDIS_HOST REDIS_PORT REDIS_PW
DATA_STORE_DEV SSH_KEY
UID_0 UID_1 UID_2 DOCKER_GID
SRC_* DST_* (migration passthrough)  VNS3_IP VNS3_PW  PHILIPS_MRI_SHELL_TIMEOUT_S
```

Retired keys — do not reintroduce: `IMAGE_TAG`, `RUN_ENV`, `RUN_LOGS_DIR`,
`NODE_MOD_CACHE_DEV`, `LOGGER`, pinned `RUN_USER`. Key values on acq-vm-0:
`USER_ID=<your-username>` (+ `#RELEASE:USER_ID=svc`), `LOG_DIR=./utils/logger/logs`
(+ `#RELEASE:LOG_DIR=/opt/run-logs/data_acquisition`), `PGDATABASE=staging` (this
server's <DB_NAME>), `PGHOST=pg_db`, `REDIS_HOST=redis_dev-0-4`, `REDIS_PW` mirrors
`/opt/resources/secrets/redis_auth.conf` (set by `activate_redis_auth.sh`, STEP 3),
`DATA_STORE_DEV=/opt/resources/acqu_files`, `UID_0/1/2` + `DOCKER_GID` from STEP 1.1.

### 6.2 Build (dev) and release

The repo carries an allowlist `.dockerignore` (SEC-10) — the build context admits
only the Dockerfile + entrypoint, and `.env`, `.git`, and logs can never land in an
image. No shared cache to warm: `build.sh` installs `node_modules` **in-tree, per
copy**.

```bash
bash preflight-check.sh    # authenticated Redis + sibling-container Postgres checks; expect 0 warnings
bash build.sh              # in-tree npm install + docker compose build -> data-acqu:<username>
bash build-release.sh      # guard -> mirror to /opt/apps -> #RELEASE flips -> RELEASE_SHA stamp
                           #   -> builds data-acqu:svc (refuses a dirty tree; that is the point)
```

### 6.3 Run a job

```bash
# dev, from the clone, as yourself:
RUN_USER=<you> docker compose run --rm app_tools node index.js offline_alert
# production shape (what cron runs), from the release copy:
cd /opt/apps/data_acquisition && docker compose run --rm -T app_tools node index.js <group> [args]
```

Cron entries use direct `node index.js` argv with `flock -n` and bounded `.out`
files — recorded in `cron-bk/crontab.restore-2026-08-24.cron`. Verify any run from
`util.app_run_logs`: production rows read `svc | <RELEASE_SHA>`; `dev-tree` on a
schedule means cron is running the wrong copy.

------------------------------------------------------------------------

# THE OUTCOME CONTRACT — jobs fail loudly (run_outcome/v1, OPS-03)

Every job app (data_acquisition, hhm_rpp_ge/philips/siemens, part-source-pipeline,
reports) ends **every run** with a terminal `run_outcome` event and an honest exit
code. This is the foundation the dashboards, incident-engine, and all future alerting
stand on — never reintroduce a catch that logs and reports success.

| Exit | Outcome | Meaning |
|---|---|---|
| 0 | `success` | zero ERROR events (or an explicitly `skipped` run, e.g. lock-busy) |
| 1 | `failed`  | a fatal error escaped to the top-level catch |
| 2 | `partial` | tolerated per-system ERROR events, or self-log persistence failed |
| 3 | usage     | unknown run group — operator must fix the crontab |

Semantics: per-system failures (an offline site, one bad credential group) are caught
by the job's own per-unit catches, logged as ERROR events, and yield `partial` —
the run itself keeps going. A **fatal** is anything that escapes to `onBoot`'s catch.
The `run_outcome` event is type INFO **on purpose** — it must never land in
`warn_error_logs` (ops-dashboard derives status and incident-engine materializes
incidents from that column). Exit codes are set via `process.exitCode`, never
`process.exit()` (lets I/O flush). If the self-log cannot be persisted to **both** DB
and disk, the run refuses to report clean success.

Quick health read across the fleet:

```sql
SELECT app_name, e->'note'->>'outcome' AS outcome, count(*)
FROM util.app_run_logs, LATERAL json_array_elements(verbose_log) e
WHERE inserted_at > now() - interval '1 hour' AND e->>'func' = 'run_outcome'
GROUP BY 1, 2 ORDER BY 1, 2;
```

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

The `/opt/run-logs/<app>` dirs are the logger's hot path (legacy `RUN_ENV=staging`
routing; migrated apps reach the same dirs via their release `LOG_DIR` mount) — they
**must be writable by the container run user** (svc uid via group docker). The
group-write + setgid bits above are what OPS-05 was about; verify with a real run,
not `ls`. **Migrated apps no longer use `/opt/resources/node_mod_cache/<app>`**
(in-tree deps) — keep creating it only for the legacy apps still in the list.

App status notes:
- **acquisition-v2** — strangler-fig replacement for data_acquisition; **paused**
  (its totalizer cron line is commented out — re-verified 2026-08-18 after it was
  found accidentally re-enabled; its `.env` deliberately holds a stale DB password
  until revival).
- **odd-jobs** — Jonathan's app, **out of scope, never modify** — but it owns
  partition maintenance (next section), so it must exist and run on any server that
  hosts the database.
- **imprivata-poc** — fully self-contained PoC; needs none of these dirs.

------------------------------------------------------------------------

# PARTITION MAINTENANCE — owned by odd-jobs (DB-01)

The 24 binned (partitioned) tables get next month's partitions created and old ones
archived by **Jonathan's odd-jobs app**: job `pg-part-arch`, scheduled in the **`svc`
service account's crontab** (requires root to read: `sudo crontab -l -u svc`), at
**14:00 UTC on the 1st of each month**. This is settled ownership
(keep-and-document, 2026-08): **retiring odd-jobs would silently end partition
maintenance** and produce a fleet-wide outage on the 1st of the following month.

Because that run fails *silently* if it ever breaks, we run an independent, read-only
watchdog: `pg_manage_v2/scripts/check-partition-horizon.sh`, cron `0 9 3,25 * *`
(the 3rd catches a failed run on the 1st with 27 days to react; the 25th catches
anything late-breaking before month-end). It asks one question — "does every binned
table have next month's partition?" — and alerts on any gap. The underlying check:

```sql
-- One row per binned table missing next month's partition (healthy = zero rows)
SELECT parent.relname
FROM pg_partitioned_table pt
JOIN pg_class parent ON parent.oid = pt.partrelid
WHERE NOT EXISTS (
  SELECT 1 FROM pg_inherits i
  JOIN pg_class child ON child.oid = i.inhrelid
  WHERE i.inhparent = parent.oid
    AND pg_get_expr(child.relpartbound, child.oid)
        LIKE '%' || to_char(date_trunc('month', now() + interval '1 month'), 'YYYY-MM-01') || '%'
);
```

Standing rhythm: in the first week of each month, confirm the new bins appeared
(the watchdog's run on the 3rd does this automatically). A stale copy of the
partition SQL inside data_acquisition misled the August audits — treat odd-jobs as
the single owner; anything else is reference-only.

**Before go-live on a NEW server (audit A21-12):** odd-jobs has no provisioning
path in this document — it is not a git checkout here (Jonathan deploys it: app
tree + vendored node_modules + its images + the `svc` crontab entry). A new
database server **runs without partition maintenance until he does**, and the gap
is silent until the watchdog's first firing (as late as the 3rd of the following
month). Coordinate the odd-jobs deployment with Jonathan before relying on the
server, then verify: `sudo crontab -l -u svc` shows the `pg-part-arch` line, and
the watchdog query returns zero rows.

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
sudo install -d -m 700 -o root -g root /opt/resources/ssl/private
openssl genrsa -out /tmp/pg_ssl.key 2048
openssl req -new -x509 -days 1095 \
  -key /tmp/pg_ssl.key \
  -out /opt/resources/ssl/pg_ssl.crt \
  -subj "/CN=pg_db" \
  -addext "subjectAltName=DNS:pg_db,DNS:postgres-server,DNS:localhost,IP:<VM_IP>,IP:127.0.0.1"
sudo mv /tmp/pg_ssl.key /opt/resources/ssl/private/pg_ssl.key
chown $USER:docker /opt/resources/ssl/pg_ssl.crt && chmod 644 /opt/resources/ssl/pg_ssl.crt
```

CN/SAN must cover every hostname/IP clients use (`pg_db` for dockerized apps on
`pg_net`, localhost/127.0.0.1 for IDE proxies, the VM IP for external clients) or
Node rejects with `ERR_TLS_CERT_ALTNAME_INVALID`. Regenerate when the IP changes.

## Key permissions (SEC-06 — the layout is the security control)

The key lives in the **root-only directory** `/opt/resources/ssl/private/` (700
root:root), owned by the container postgres uid:

```bash
sudo chown 999:root /opt/resources/ssl/private/pg_ssl.key
sudo chmod 600 /opt/resources/ssl/private/pg_ssl.key
```

Why this exact layout: on acq-vm-0, host uid 999 is `dd-agent` (Datadog), which
collides with the container `postgres` uid. The container reads the key through its
**direct file bind-mount** (mounts bypass host directory traversal), while any host
process running as uid 999 is stopped by the 700 parent directory. The layout is
correct on any server — whatever host account happens to hold uid 999 (Datadog here;
possibly another package's account, or nobody, on a fresh VM) can never traverse to
the key. **Monitoring agents themselves (Datadog) are out of this document's scope**
(audit A21-11): installing one is an org decision made separately — a doc-built
server has no host monitoring until that happens. Verify after setup:

```bash
docker exec pg_db psql -U postgres -tAc "SHOW ssl;"                 # on
# If a uid-999 host account exists (dd-agent on acq-vm-0):
sudo -u "$(getent passwd 999 | cut -d: -f1)" cat /opt/resources/ssl/private/pg_ssl.key   # Permission denied
```

Cert regeneration: after re-issuing `pg_ssl.crt`, a **`pg_reload_conf()` is
sufficient** (Postgres re-reads SSL files on reload). All clients must re-pull the
new `pg_ssl.crt`.

## App connection contract (what the code actually does)

Apps use libpq-style vars plus two custom ones — **not** `PG_HOST`/`PG_PW`:

```bash
PGHOST=pg_db            # container name on pg_net (VM IP for external clients)
PGPORT=5432
PGDATABASE=<DB_NAME>
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
psql "host=<VM_IP> dbname=<DB_NAME> user=postgres sslmode=disable"      # expect: rejected
psql "host=<VM_IP> dbname=<DB_NAME> user=postgres sslmode=require"      # expect: connects
psql "host=<VM_IP> dbname=<DB_NAME> user=postgres sslmode=verify-full sslrootcert=pg_ssl.crt"  # expect: connects
```

------------------------------------------------------------------------

# DATABASE ROLES — retiring the shared superuser

**Current state:** incident-engine (`incident_engine_rw`), ops-dashboard
(`ops_dashboard_ro`), and reports (`reports_rw`) use dedicated least-privilege roles.
**Every other app still connects as `postgres`** — each is a full-DB blast radius and
must be migrated (Phase 4a).

The pattern (proven three times; scripts to copy):
- `incident-engine/db/setup-owner-role.sql` — owner-role variant (app owns its schema)
- `ops-dashboard/db/setup-readonly-role.sql` — read-only variant
- `reports/db/setup-role.sql` — read-mostly + targeted writes variant, with a
  database-wide fail-closed allowlist audit

**Passwords never go on a command line as literals** (SEC-09 — shell history and
`ps` exposure). Generate into a root-only file first, then expand from it. The
`/root/<role>_pw` files are **host state** — keep them; if a host is missing them
(found on acq-vm-0 2026-08-21), recreate each from the owning app's `.env` per
**§5.9 Step 0** before re-running any role script:

```bash
sudo install -m 600 -o root -g root /dev/null /root/<role>_pw
sudo sh -c 'head -c 24 /dev/urandom | base64 | tr -d "/+=" > /root/<role>_pw'
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v pw="$(sudo cat /root/<role>_pw)" -f - < db/setup-role.sql
```

Per-app migration checklist (repeat for each remaining app):

1. Enumerate the app's schema/table reads and writes (grep `FROM|JOIN|INSERT|UPDATE`
   over its `.js`/`.sql`, plus the logger's `util.app_run_logs` INSERT that every app
   performs; check write targets for serial columns → sequence grants).
2. Write `db/setup-role.sql` in the app repo from the closest template; include the
   fail-closed audit block.
3. Fix the app's vendored `utils/db/pg-pool.js` to the fail-closed version (copy from
   reports) and set `PG_SSLMODE=verify-full` + the `/opt/resources/ssl:ro` mount in
   compose.
4. Apply with the password-file pattern above.
5. Swap `.env` `PGUSER`/`PGPASSWORD`, then smoke test grants (positive reads/writes,
   expected denials, `pg_stat_ssl` check) before the next scheduled run.
6. **Re-run each setup-role script after any app-database reset** (grants die with the
   schema; roles survive) and re-run it BEFORE deploying code needing new grants.

Rollout order suggestion (blast radius, low → high): monday → part-source-pipeline →
acumatica_sync → hhm_rpp_siemens → hhm_rpp_ge → hhm_rpp_philips → data_acquisition
(save for last: most jobs, busiest schedule).

------------------------------------------------------------------------

# PER-APP ENTRYPOINT & BUILD MATRIX (verified 2026-08-18)

Standard entrypoint (gosu drop to `RUN_USER`, default `svc`):

```bash
#!/bin/bash
set -e
RUN_USER="${RUN_USER:-svc}"
export HOME="/home/$RUN_USER"
exec gosu "$RUN_USER" "$@"
```

**Every image is now built by Compose** — `docker compose build` works in every repo
that has an image (the 2.0-era "build RPP by hand" and "do not build acumatica"
instructions are dead):

| App | Entrypoint | Image compose runs | Built by |
|---|---|---|---|
| data_acquisition (**migrated**) | `docker/entrypoint.sh` (baked; root-phase log-dir repair) | `data-acqu:${USER_ID}` (dev = username, release = `svc`) | `bash build.sh` (dev) / `build-release.sh` (release, as svc) |
| hhm_rpp_ge | `docker/entrypoint.sh` | `hhm_rpp:${IMAGE_TAG}` | `docker compose build` in **GE** (owns the shared image) |
| hhm_rpp_philips / siemens | — (no Dockerfile, on purpose) | `hhm_rpp:${IMAGE_TAG}` (GE's image) | by reuse |
| monday | `entrypoint.sh` (root) | `monday:${IMAGE_TAG}` | `docker compose build` |
| reports | `docker/entrypoint.sh` | `aux:${IMAGE_TAG}` (legacy tag name) | `docker compose build` |
| part-source-pipeline | `entrypoint.sh` (root) | `psp:${IMAGE_TAG}` | `docker compose build` |
| acumatica_sync | `entrypoint.sh` (root) | `acu-sync:${IMAGE_TAG}` | `docker compose build` (adopted — no longer stock node:lts) |
| incident-engine | n/a | stock `node:lts`, `user: "105:987"` | by design (declarative drop, no gosu) |
| ops-dashboard | n/a | stock `node:lts`, `user: "105:987"` | by design |
| imprivata-poc | `docker/entrypoint.sh` (conditional gosu) | `imprivata-poc:local` | `docker compose build app_tools` |

Host identity (uid/gid build args, image tags) comes exclusively from each repo's
untracked `.env` — builds fail loudly if unset. That is the convention working, not
an error.

------------------------------------------------------------------------

# SHARED SSH BUNDLE (/opt/resources/ssh)

Used by data_acquisition's SFTP/rsync jobs (mounted
`- /opt/resources/ssh:/opt/resources/ssh:ro`) **and by odd-jobs**, which mounts all of
`/opt/resources:ro` and runs `ssh -F /opt/resources/ssh/config` the same way — a change
to this bundle reaches both apps.

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

### Incremental import after a migration (EXISTING server, new inventory)

A systems-inventory seed brings host IPs this server may never have keyed; strict
checking then fails every cycle (the 2026-08-19 migration produced 905
`No ED25519 host key is known` errors in 17 h across 11 systems). Do **not** keyscan
(guardrail 3). Instead push the source server's verified file with
**`scripts/known_hosts_migrate.sh`** (tracked here, **runs on the source server** —
same lifecycle as `redis_migrate.sh`):

```bash
# On the SOURCE (prod) server:
./known_hosts_migrate.sh --dry-run   # validates, ships, reports what would append
./known_hosts_migrate.sh             # backup on target -> append-only merge -> install
```

Semantics: append-only with exact-line dedupe — nothing already on the target is
removed or replaced; the install is atomic (temp + `mv` in the same dir), safe under
live cron. A changed host key ends up with old+new entries (OpenSSH accepts when any
matches); pruning stale keys stays manual. Backup lands at
`/opt/resources/backups/known_hosts.pre-import-<ts>`; the script prints the temp+`mv`
rollback line (a plain `cp` onto the file is blocked by the ACL mask for non-owners).

Verify on the target: `ssh-keygen -F <new-ip> -f /opt/resources/ssh/known_hosts` per
new system, then zero `%host key%` `err_msg` rows in `util.app_run_logs` on the next
`:00/:30` burst. **Single new host:** same procedure works (the merge only appends
what's new), or obtain that host's key from any server that already trusts it — never
keyscan.

------------------------------------------------------------------------

# RPP APPS (hhm_rpp_ge / hhm_rpp_philips / hhm_rpp_siemens)

All three run the **same image, `hhm_rpp:${IMAGE_TAG}`**, built from
`hhm_rpp_ge/docker/Dockerfile` (node:lts + gosu entrypoint + the same UID_* build args
as data_acquisition). Philips/Siemens have no Dockerfile on purpose. **The GE repo
owns the image and its compose has the `build:` block** — build there once, before
first run of any RPP app:

```bash
cd /opt/apps/hhm_rpp_ge
docker compose build        # -> hhm_rpp:${IMAGE_TAG}; args from .env (fails loudly if unset)
```

Per app (GE shown; philips/siemens identical with their names):

```bash
git clone git@github.com:Matt-Teixeira/hhm_rpp_ge.git /opt/apps/hhm_rpp_ge
cd /opt/apps/hhm_rpp_ge
git switch -c STAGING_docker --track origin/STAGING_docker
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger
# .env: PG*/REDIS_* vars (incl. REDIS_PW), RUN_USER=svc, RUN_ENV=staging,
#       DATA_STORE_DEV=/opt/resources/acqu_files, IMAGE_TAG, UID_*/DOCKER_GID
# Warm cache once:
docker compose run --rm app_tools bash -lc "npm ci --omit=dev --no-audit --no-fund"
```

**Philips also owns `log.saved_files` retention** — see SAVED_FILES RETENTION below.

------------------------------------------------------------------------

# ACUMATICA SYNC APP

```bash
git clone git@github.com:Matt-Teixeira/acumatica_table_pull.git /opt/apps/acumatica_sync
cd /opt/apps/acumatica_sync
git switch -c STAGING_docker --track origin/STAGING_docker

docker compose build        # -> acu-sync:${IMAGE_TAG} (adopted 2026-08: baked entrypoint,
                            #    replaces the old stock-node:lts + hardcoded user: pattern)
docker compose run --rm app npm install     # warm cache (this app's pattern)
```

The app loads `.env` itself via dotenv (compose deliberately has no `env_file`, so
`$expand`/`$format` in Acumatica URIs survive Compose's `$`-interpolation — REL-02
class; verify values arrive byte-for-byte from inside a container when touching this).

------------------------------------------------------------------------

# REPORTS APP

```bash
git clone git@github.com:Matt-Teixeira/reports.git /opt/apps/reports
cd /opt/apps/reports
git switch -c STAGING_docker --track origin/STAGING_docker
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

docker compose build        # -> aux:${IMAGE_TAG} (historical shared-aux tag; rename is tracked debt)

# DB role (pilot pattern — see DATABASE ROLES; use the password-file pattern):
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v pw="$(sudo cat /root/reports_rw_pw)" -f - < db/setup-role.sql
# .env: PGUSER=reports_rw, PG_SSLMODE=verify-full, PG_SSL_PATH=/opt/resources/ssl/pg_ssl.crt
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

docker compose build          # -> monday:${IMAGE_TAG} (Dockerfile, root entrypoint.sh,
                              #    SVC_UID/DOCKER_GID args from .env)
docker compose run --rm app bash -lc "npm ci --omit=dev --no-audit --no-fund"
```

`.env` points at the real **`staging`** database (the pre-August `dev` value was a
standing failure — REL-02). The app reads `PGUSER` (`utils/db/pg-pool.js`); compose
forces `PG_SSLMODE=require` for now (switch to verify-full during its role migration).

------------------------------------------------------------------------

# PART SOURCE PIPELINE APP

```bash
git clone git@github.com:Matt-Teixeira/part-source-pipeline.git /opt/apps/part-source-pipeline
cd /opt/apps/part-source-pipeline
git switch -c STAGING_docker --track origin/STAGING_docker
mkdir -p files && chmod -R g+rwX files && chgrp -R docker files    # REQUIRED — first run fails without it
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger

docker compose build          # -> psp:${IMAGE_TAG} (root entrypoint.sh, args from .env)
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

# Provision DB (superuser, IN THIS ORDER; re-run both after any app-database reset;
# password-file pattern per DATABASE ROLES):
docker exec -i pg_db psql -U postgres -d <DB_NAME> -f - < db/schema.sql
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v pw="$(sudo cat /root/incident_engine_rw_pw)" -f - < db/setup-owner-role.sql

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
unless-stopped`, stock `node:lts` as `user: "105:987"`, log cap in compose.

```bash
git clone git@github.com:Matt-Teixeira/ops-dashboard.git /opt/apps/ops-dashboard
cd /opt/apps/ops-dashboard           # tracks main
mkdir -p /opt/resources/node_mod_cache/ops-dashboard /opt/run-logs/ops-dashboard
cp .env.example .env                 # PGHOST=pg_db, SSL cert path, self-monitoring toggle

# Roles (superuser, once; incident-engine must already be deployed or the fail-closed
# script errors on the missing incidents.* grant targets; password-file pattern):
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v ro_pw="$(sudo cat /root/ops_dashboard_ro_pw)" < db/setup-readonly-role.sql
# Only if SELF_LOG_ENABLED=true:
docker exec -i pg_db psql -U postgres -d <DB_NAME> -v rw_pw="$(sudo cat /root/ops_dashboard_rw_pw)" < db/setup-writer-role.sql

docker compose run --rm app npm install
docker compose up -d
curl -s localhost:8080/healthz              # {"ok":true}
curl -s localhost:8080/api/jobs/latest      # 503 "warming" briefly, then 200
```

Re-run `setup-readonly-role.sql` after DB resets or before deploying endpoints needing
new grants (else 500 permission-denied). Port 8080 is published on all interfaces —
the NSG is the boundary; hardening (pinned image, auth proxy) is a follow-up.

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
manifest: **a schedule that is not in it does not exist**, and it must be kept in
sync with `crontab -l`.

> **2026-08-24:** data_acquisition's 24 entries were replaced with hardened ones
> (direct `node index.js` argv, `flock -n`, `-T`, absolute paths, bounded
> `cron.<job>.out` files) at the paradigm cutover — the installed set is
> `data_acquisition/cron-bk/crontab.restore-2026-08-24.cron`. `schedules.md`
> still shows the legacy npm-run entries for this app: sync it on next touch.

The maintenance schedule at a glance:

| When | What |
|---|---|
| 02:15 nightly | `pg_manage_v2/scripts/backup.sh` |
| 03:30 nightly | `data_acquisition/scripts/prune-run-logs.sh` |
| 09:00 on the 3rd & 25th | `pg_manage_v2/scripts/check-partition-horizon.sh` |
| :05/:35 | `hhm_rpp_philips` `delete_old_db_files` (saved_files 48 h retention) |
| 14:00 UTC, 1st (svc crontab — odd-jobs) | partition create/archive (`pg-part-arch`) |

Always snapshot before editing:

```bash
crontab -l > /opt/resources/backups/crontab-$(date +%Y%m%d-%H%M).txt
```

------------------------------------------------------------------------

# STEP 10: BACKUPS & MAINTENANCE (installed, not proposed)

All scripts are **tracked in their owning repos** and already scheduled (STEP 9).

- **`pg_manage_v2/scripts/backup.sh`** — nightly 02:15: `pg_dump -Fc <DB_NAME>` (via its `PG_DB` variable, default `staging`)
  (structurally verified with `pg_restore --list` before reporting success) + a
  reply-checked `SAVE` and RDB copy of all four Redis instances (`redis-cli` exits 0
  even when refused — the script checks for a literal `OK`; all four instances
  authenticate via their mounted auth.conf). Local retention: 7 days pg /
  14 days Redis under `/opt/resources/backups/`. Logs one line per night to
  `backup.log` — "newest backup < 25 h old" is a standing health check.
  **Local-only until decision D4 picks an off-host target** (Azure storage is the
  natural fit) — then enable the sync stub at the bottom of the script (Phase 4g).
- **`data_acquisition/scripts/prune-run-logs.sh`** — nightly 03:30: prunes
  `/opt/run-logs/<app>/` and legacy repo-local logger dirs; summary to
  `/opt/run-logs/prune.log`.
- **Container log rotation** — per-service `logging:` blocks in the tracked compose
  files (see CONVENTIONS). There is deliberately no `daemon.json` step.
- **Reference dumps** kept outside retention on purpose: `staging-20260727-1933.dump.initial`,
  `staging-20260817-1324.dump.full` (the last full dumps that include
  `log.saved_files` history).

Restore test (once per server, after any pg major upgrade, and as part of acceptance):

```bash
docker exec pg_db createdb -U postgres restore_test
docker exec -i pg_db pg_restore -U postgres -d restore_test --no-owner < /opt/resources/backups/pg/<DB_NAME>-<date>.dump
docker exec pg_db psql -U postgres -d restore_test -c "SELECT count(*) FROM alert.models;"
docker exec pg_db dropdb -U postgres restore_test
```

## SAVED_FILES RETENTION (DB-05 — restored 2026-08-18)

`log.saved_files` holds raw Philips machine-file blobs (~381 kB each, incompressible,
~7,600 rows/day). Retention policy: **48 hours** (decision D2), enforced by
`hhm_rpp_philips`'s `delete_old_db_files` job every 30 minutes at `:05/:35` —
batched deletes on the indexed column, session advisory lock
(`hashtext('log.saved_files:retention')`), per-batch timeouts, `run_outcome/v1`
participation (lock-busy = `skipped`, exit 0). History: the original cron line was
lost in the hhm_rpp three-way split and the table silently grew to 141 GB / 40 days
before being purged back to ~6 GB.

Steady state to expect: ~15,400 rows / ~6 GB on disk; nightly dump ~10 GB. If the
table is ever found far above that, the retention job has been failing — check its
outcomes in `util.app_run_logs` (a persistent `skipped` streak means something holds
the advisory lock). A large backlog must be cleared with **batched deletes + a
post-purge `VACUUM FULL` in a quiet minute** — never one big `DELETE`, and remember
plain `VACUUM` does not return the disk space.

------------------------------------------------------------------------

# SECURITY BASELINE (what a built server must satisfy)

- **No secrets in any repo's current tree** — rotated and scrubbed 2026-08-17
  (SEC-01/02); a worktree scan for credentials must come back empty. **One accepted
  exception in history** (owner decision 2026-08-18): part-source-pipeline's git
  history retains an SFTP credential the vendor cannot rotate — a history-aware
  scan WILL find it; repo access control is the boundary for it. Secret scanner in
  CI is tracked debt (Phase 4e).
- **Secrets on disk** follow the root-only-file pattern (CONVENTIONS): the pg
  superuser password file, the pg TLS key, the Redis auth file.
- **Build hygiene**: allowlist `.dockerignore` in every repo that builds an image
  (SEC-10) — context must be KBs, never contain `.env`/`.git`/logs.
- **Network**: the server has no public IP; the Azure NSG is the boundary — verify
  its rules for 5432 and 8080 (Redis has no host ports at all). Binding pg/dashboard
  to specific interfaces (SEC-11) is deliberately deferred.
- **Redis**: auth on **all four instances** (redis-STAGING standardized 2026-08-19;
  odd-jobs' client-side auth must be coordinated with Jonathan).
- **Postgres**: hostssl-only; container metadata carries no password; per-app roles
  are the target state (3 of 10 done).

------------------------------------------------------------------------

# FOLLOW-UPS (known debt, deliberately deferred — Phase 4 of the plan)

1. **DB roles fleet rollout** (4a) — 7 apps still connect as `postgres` with
   unverified TLS; per-app checklist above.
2. **Verified TLS everywhere** (4b) — copy reports' fail-closed pg-pool to each app.
3. **Stricter secret/config file permissions + runtime group** (4d).
4. **Version pinning + CI checks** (4e) — `node:lts` is mutable; pin per-app; add
   secret-scanning and compose-validation to CI.
5. **DB tuning & the June OOM** (4f) — `pg_stat_statements` is now collecting; add
   memory guardrails to pg_db compose from measured peaks.
6. **Off-host encrypted backups** (4g) — blocked on decision D4.
7. **Cron mail cleanup** (4h) — 400 MB spool, some sensitive output.
8. **External-endpoint inventory** (4i) — which staging jobs touch real prod systems
   (Acumatica, Monday, SFTP), with per-env credentials/mode.
9. **odd-jobs Redis auth support** — redis-STAGING is auth'd like the rest since
   2026-08-19 (reverses the 2026-08-18 passwordless decision). odd-jobs' client
   must authenticate to reach it; until Jonathan confirms/ships that, odd-jobs'
   Redis access fails fast with NOAUTH — coordinate before the next `pg-part-arch`
   run (1st of the month) if that job touches Redis.
10. **reports image tag** — rename `aux:` → `reports:` once nothing else consumes it.
11. **incident-engine / ops-dashboard / reports hardcoded ids** — migrate the
    remaining `105:987` literals to the `.env` convention.
12. **systems-inventory sync policy (B0a)** — named decision + owner (see 5.5).
13. **git-history scrub of the old DB password** (D3) — value is dead; cleanup only.
14. **PROD** (4j) — branches, cutover runbook, data governance: unblocked once this
    document passes acceptance.

------------------------------------------------------------------------

# ACCEPTANCE TEST (item 13 — run by someone who didn't write this doc)

Build a blank dev/staging VM from this document alone, then demonstrate **all** of:

**Provenance & config**
- [ ] Every referenced repo/branch/file/image exists; every `docker compose config`
      validates with **zero warnings — except acumatica_sync's documented
      `$expand`/`$format` interpolation warnings** (inherent to its no-`env_file`
      dotenv design, A21-07; count varies with its `$`-bearing URIs); a
      **worktree** secret scan finds nothing (the psp *history* credential is an
      accepted exception — see SECURITY BASELINE).
- [ ] Config values arrive byte-for-byte inside containers (spot-check an Acumatica
      URI with `$` characters from inside its container).
- [ ] Committed `.env.example` files contain placeholders only — no real uid/gid/tag
      values (REL-07).

**Identity & permissions**
- [ ] Each container runs as its intended uid:gid and can write its mounts (run a
      real job per app — a directory existing is not the test).
- [ ] `/opt/run-logs/<app>/` receives fresh files from a scheduled run of each family
      (legacy apps: `RUN_ENV=staging` routing; migrated apps: release `LOG_DIR`
      mount — files named `<app>-log.svc.<run_id>.json` and rows in
      `util.app_run_logs` carrying the release's `RELEASE_SHA`).

**Database**
- [ ] Non-SSL connection rejected; `verify-full` passes; `docker inspect pg_db` shows
      zero `POSTGRES_PASSWORD*`; healthcheck healthy; `pg_stat_statements` returns rows.
- [ ] If any host account holds uid 999 (dd-agent on acq-vm-0; check
      `getent passwd 999`): `sudo -u <that account> cat
      /opt/resources/ssl/private/pg_ssl.key` → Permission denied. (No uid-999
      account = nothing to test; note that the server has no monitoring agent —
      out of doc scope, A21-11.)
- [ ] Every binned table has ≥1 month of future partitions (watchdog query returns
      zero rows) and the watchdog cron is installed.
- [ ] **odd-jobs is deployed and scheduled** (Jonathan): `sudo crontab -l -u svc`
      shows the `pg-part-arch` line — a new DB server without it has no partition
      maintenance (A21-12).
- [ ] The systems inventory has been reconciled against prod (B0a) and the delta
      recorded.

**Redis**
- [ ] No Redis ports on the host; anonymous `PING` → NOAUTH on **all four**
      instances; authenticated `PING` → PONG; `appendonly=yes` from the mounted
      configs; key counts match the seed source.

**Jobs & honesty**
- [ ] One scheduled job from each family completes; outcomes land in
      `util.app_run_logs` with `run_outcome` events.
- [ ] A deliberately-broken test job exits nonzero and records `failed` — the
      fail-loudly contract holds on the rebuilt server.
- [ ] `log.saved_files` holds ≤ ~3 days of rows and the `:05/:35` retention job shows
      `success` outcomes.

**Safety net**
- [ ] `backup.sh` produces a dump that passes the restore test; newest backup < 25 h;
      Redis SAVE verified against auth'd instances; prune log shows a run.
- [ ] Long-running containers show `max-size` in `docker inspect` LogConfig.
- [ ] A full host reboot brings back pg_db, all four Redis (still auth'd — requirepass
      survives restart via the mounted include), ops-dashboard, and the schedules
      without manual help.

When this list passes on staging **and** on a rebuild, "build from the doc" and
"clone staging" mean the same thing — the golden image exists.
