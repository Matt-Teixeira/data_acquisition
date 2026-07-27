# Audit of `docker_server_full_setup_2.0.md`

Audit date: 2026-07-27  
Audited draft: [`docker_server_full_setup_2.0.md`](./docker_server_full_setup_2.0.md)

## Executive conclusion

The draft is **not ready to serve as the final server build or production
cutover runbook**. It has a useful overall inventory and several sound
conventions, but a clean server built by following it would encounter multiple
blocking failures. More importantly, some successful-looking steps would deploy
the wrong environment, use an old or unrelated image, or leave database and
Redis ports exposed.

The highest-priority problems are:

1. The environment abstraction is not implemented by the app Compose files.
   `ENV=PROD` cannot work as documented, and the audited remotes do not have
   `origin/PROD_docker`.
2. The Redis Compose file refers to config paths that are not files, so a clean
   Redis deployment will not start with the documented command.
3. Several image build commands are no-ops or build an image that Compose never
   uses.
4. PostgreSQL and Redis are published on all host interfaces without a complete
   network-control procedure.
5. The production-state migration procedure lacks a safe cutover, final delta,
   validation gate, backup/restore test, and rollback plan.
6. Most apps currently connect as the PostgreSQL superuser.
7. Job scheduling is largely absent from the draft, while the existing cron
   reference is legacy and does not safely prevent overlapping runs.

This was a static, non-mutating audit. Existing app files were not changed.
Compose models were parsed, repository state and cached remote refs were
inspected, and build declarations were checked. The Docker daemon itself could
not be inspected because this audit session does not have access to
`/var/run/docker.sock`; no containers, migrations, or live network connections
were started.

## What is already reasonable

- The move toward app-local, tracked entrypoints is a good direction.
- Vendoring the utilities actually used by each app removes a fragile
  cross-repository checkout dependency.
- Canonical `/opt/run-logs/<app>` paths and read-only data/credential mounts are
  good conventions.
- External `pg_net` and Redis networks give the apps stable service names.
- `incident-engine` and `ops-dashboard` have substantially better
  least-privilege database role designs than the older apps.
- The draft recognizes that `ops-dashboard` is long-running while most other
  workloads are one-shot jobs.
- Compose syntax currently parses for every audited Compose project when its
  local `.env` is present. This does not validate source-path types, external
  network existence, image availability, permissions, or runtime health.

## Release-blocking findings

### RB-1 — The stated environment convention is not true

The draft says every app has `DEV_docker`, `STAGING_docker`, and `PROD_docker`
and that environment-suffixed variables follow `ENV` (draft lines 5-27).

Observed:

- None of the eight environment-branch apps audited has a cached remote ref
  named `origin/PROD_docker`.
- [`data_acquisition/docker-compose.yaml`](../docker-compose.yaml) always uses
  `NODE_MOD_CACHE_DEV` and `DATA_STORE_DEV`, while its built image is always
  tagged `data-acqu:staging`.
- The three RPP Compose files always consume `DATA_STORE_DEV` and
  `hhm_rpp:staging`.
- Monday, reports, and part-source-pipeline also use staging-specific image
  names.
- The current data-acquisition `.env` contract contains the DEV cache/store
  variables, not the STAGING variables the draft says a staging deployment
  should use.

Impact: an operator can set `ENV=STAGING` or `ENV=PROD` and still deploy DEV
mounts and staging-tagged images. A PROD clone command fails because the branch
does not exist.

Needed change: either make Compose truly environment-parameterized and create a
documented release-branch policy, or remove the generic claim and provide
explicit, tested procedures for each supported environment. Resolve immutable
image tags separately from Git branch names.

### RB-2 — Redis does not use the config files that exist

[`redis-admin/docker-compose.yaml`](../../redis-admin/docker-compose.yaml)
mounts paths such as `./conf/prod.conf` to Redis's config-file location.
In the audited checkout, `conf/prod.conf`, `conf/staging.conf`, and the DEV
equivalents are directories. The actual files are named
`config/prod.config`, `config/staging.config`, and so on.

On a clean checkout, short bind-mount syntax can create a missing source as a
directory, producing the same class of error. Redis then receives a directory
where it expects a file.

Impact: `docker compose up -d` in draft step 3 will fail or repeatedly restart
Redis.

Needed change: fix and test the Redis Compose mount sources, use long bind
syntax with `create_host_path: false` where supported, and add a preflight that
asserts each source is a regular file before starting containers.

### RB-3 — RPP build steps do not build an image

The draft runs `docker compose build` in each RPP repository (lines 878-920).
All three commands currently report `No services to build` and exit zero.

- GE has a Dockerfile but its Compose service only names
  `image: hhm_rpp:staging`; it has no `build:` section.
- Philips and Siemens have no local Dockerfile and intentionally reference the
  same GE image.

Impact: the guide appears to succeed while leaving the required image absent or
stale.

Needed change: establish one explicit, verified build/publish step for the
shared RPP runtime, pin the image by immutable version or digest, and make
Philips/Siemens depend on that artifact. Alternatively, add a real GE `build:`
declaration and document that it must run first.

### RB-4 — Reports and Acumatica build images that their Compose files ignore

For reports, the draft builds `reports:svc`, but
[`reports/docker-compose.yml`](../../reports/docker-compose.yml) runs
`aux:staging` and has no `build:` declaration. The tracked reports Dockerfile
and entrypoint are therefore unused by the documented runtime.

For Acumatica, the draft builds `acu-sync:svc`, but
[`acumatica_sync/docker-compose.yaml`](../../acumatica_sync/docker-compose.yaml)
runs stock `node:lts` as hardcoded user `1006:987`. Its tracked Dockerfile and
entrypoint are also unused.

Impact: build success does not prove the subsequently run service contains the
expected users, entrypoint, or dependencies.

Needed change: make the build tag and Compose `image` identical, or add the
appropriate `build:` declaration. Add an assertion such as
`docker compose images` plus an entrypoint/user smoke test.

### RB-5 — The shared SSH-key procedure can make the key unreadable

The draft sets `/opt/resources/ssh/id_dev` to mode `0600` after changing only
its group (lines 840-846). Containers normally run as `svc`; unless the file's
numeric owner is exactly the container `svc` UID, `svc` cannot read it. Group
membership cannot help with a `0600` file.

The guide also never creates the bundle or explains how its initial
`config`, private key, and verified `known_hosts` contents arrive on the new
server.

Impact: SSH/SFTP acquisition jobs fail at runtime, often only when the first
scheduled job reaches a remote device.

Needed change: define a single owner model and verify it from inside the
container. For example, make the host key owner UID match the runtime UID and
keep `0600`, rather than relying on group access. Include an approved,
fingerprint-verified host-key bootstrap; do not blindly trust `ssh-keyscan`
output.

### RB-6 — The `incident-engine` deploy worktree is never created

The draft clones `/opt/apps/incident-engine`, then later runs Git commands in
`/opt/apps/incident-engine-deploy` (lines 1043-1104). There is no
`git worktree add` or equivalent creation step and no complete procedure for
copying and securing the deploy `.env`.

Impact: the production deployment command fails on a new server.

Needed change: add a tested worktree-creation, reviewed-SHA checkout,
environment-file provisioning, permissions, smoke-test, and rollback sequence.

### RB-7 — The production migration is not a safe cutover procedure

Draft steps 4 and 5 stop production jobs, copy one Redis RDB into PROD,
STAGING, and DEV, import PostgreSQL data in manual batches, and then permit
production jobs to restart.

Missing controls include:

- a named change owner and maintenance window;
- a source backup and tested restore before destructive work;
- RDB checksum, Redis version/format compatibility, `INFO persistence`, and
  sample-data validation;
- PostgreSQL source/destination version and extension compatibility checks;
- row counts, sequence values, constraints, large-object, ownership, and grant
  validation;
- a final delta/catch-up after the bulk import;
- an explicit cutover gate and application read/write freeze;
- rollback criteria and commands;
- validation that jobs are pointed at the destination before restart;
- handling for partial failure after only some batches are imported;
- a data-governance decision authorizing production data in DEV and STAGING.

Impact: lost writes, inconsistent source/destination state, accidental
production-data proliferation, or a prolonged outage.

Needed change: replace this section with a separately rehearsed migration
runbook that records recovery point objective, recovery time objective,
backups, validations, final synchronization, go/no-go decision, cutover, and
rollback.

### RB-8 — Network exposure is unsafe and incomplete

PostgreSQL uses `-p 5432:5432`, Redis publishes every environment port, and
ops-dashboard uses `8080:8080`. These forms bind on all host interfaces by
default. The draft does not define an Azure NSG, host firewall/`DOCKER-USER`
policy, source allowlist, private network, authentication boundary for the
dashboard, or an SSH/VPN access pattern.

TLS does not replace network access control. Docker also warns that published
container ports can bypass `ufw`/firewalld expectations; filtering must be
designed with Docker's packet path in mind. See the official
[Debian installation firewall warning](https://docs.docker.com/engine/install/debian/)
and [packet-filtering guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).
Redis explicitly recommends keeping Redis in a trusted network and not exposing
it directly to untrusted clients; see
[Redis security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/).

Needed change: bind to a private or loopback address where possible, avoid
publishing Redis when only Docker-network clients need it, define Azure and host
firewall rules, and put ops-dashboard behind an authenticated TLS reverse proxy
or private access boundary.

## High-priority correctness and security findings

### H-1 — The user-creation command block contains an executable typo and does not activate group membership

`CREATE SERVICE ACCOUT USER` in draft line 68 is plain text inside a shell block,
so it is executed as a command. `source ~/.bashrc` does not refresh supplementary
groups after `usermod`; the user must log out/in or use `newgrp docker`.
Docker's official post-install guide states this and also warns that membership
in `docker` grants root-level host privileges:
[Linux post-installation steps](https://docs.docker.com/engine/install/linux-postinstall).

The guide later expects `matt-teixeira` to exist but never creates that account,
and creates `svc` without adding it to the Docker group. It also does not state
which account owns the production crontab.

Needed change: define administrative users separately from the least-privilege
job account, explicitly decide who may control Docker, and test each account's
login, group, directory, and crontab permissions.

### H-2 — Eight audited apps use the PostgreSQL superuser

The current local environment files for data_acquisition, all three RPP apps,
Acumatica, Monday, reports, and part-source-pipeline set `PGUSER=postgres`.
Only incident-engine and ops-dashboard use dedicated roles.

Impact: a bug or compromised credential in any batch app can change roles,
drop schemas, alter unrelated data, or bypass intended ownership boundaries.

Needed change: create per-app login roles with only the required schema/table
privileges, rotate out the shared superuser password, and add grant-audit SQL.
The incident-engine and ops-dashboard scripts are useful patterns, though they
currently hardcode the `staging` database name and therefore are not generic
PROD procedures.

### H-3 — TLS behavior in code does not match the draft

The draft presents a fail-closed Node configuration with
`rejectUnauthorized: true` (lines 664-697). The actual data-acquisition
[`db/pgPool.js`](../db/pgPool.js) and vendored
[`utils/db/pg-pool.js`](../utils/db/pg-pool.js) silently fall back to
`rejectUnauthorized: false` when a verify-mode CA path is missing or unreadable.
That converts a certificate-verification configuration error into an
unauthenticated encrypted connection.

Monday and reports force `PG_SSLMODE=require` in Compose, overriding their
`.env` and disabling certificate verification. Ops-dashboard's example also
defaults to `require`. Incident-engine correctly fails closed for verify modes.

Needed change: standardize one tested, fail-closed TLS helper across the apps;
use `verify-full` for server identity; reject unknown modes; and make a missing
CA fatal.

### H-4 — The SSL section contains two factual errors

- `sslmode=verify-ca` validates the CA chain but does not verify that the
  hostname is the expected server. The identity-verifying psql test should use
  `verify-full`.
- The draft says PostgreSQL must restart after certificate regeneration.
  PostgreSQL reads SSL files on server start **and configuration reload**, so a
  successful `pg_reload_conf()` can apply them. See
  [PostgreSQL SSL server file usage](https://www.postgresql.org/docs/current/ssl-tcp.html).
  A controlled restart may still be an operational choice, but it is not the
  only supported mechanism.

The exact `sed` replacement for `pg_hba.conf` is also brittle: it assumes one
specific generated line and auth method, does not assert that exactly one line
changed, and does not test both IPv4 and IPv6/no-SSL rejection paths.

Needed change: use an idempotent managed config fragment or validated edit,
inspect the effective `hba_file`, run `pg_hba_file_rules`, reload, and execute
positive and negative tests.

### H-5 — Database credentials are exposed through command arguments and shared broadly

`POSTGRES_PASSWORD=<paste_pass_here>` is entered directly in `docker run`.
It can be retained in shell history and is visible in container configuration.
The same superuser credential is then copied into many app `.env` files.

Needed change: use a root-owned secret file with the official image's
`POSTGRES_PASSWORD_FILE` support or another approved secret manager, avoid
interactive history exposure, and give apps separate rotated credentials.

### H-6 — The Docker storage procedure is incomplete for current fresh installs

The draft overwrites `/etc/docker/daemon.json` instead of safely merging and
validating an existing file. Its referenced `docker-disk-migration.md` is not
present anywhere in the audited app tree.

There is also a current-version issue: Docker documents that fresh Docker
Engine 29+ installations use the containerd image store, whose image content
and snapshots remain under `/var/lib/containerd` unless containerd's root is
configured separately. Setting Docker's `data-root` alone no longer guarantees
that all large image data moves to `/mnt/sdc`. See
[Docker daemon data directory](https://docs.docker.com/engine/daemon/).

Needed change: pin/test the supported Docker version, verify the persistent disk
is mounted through `/etc/fstab` before Docker starts, configure both required
storage roots for that version, validate configuration before restart, and
monitor both root and data-disk usage.

### H-7 — The Docker installation recipe is stale and unpinned

The current official Debian instructions use `/etc/apt/keyrings/docker.asc` and
a deb822 `docker.sources` file, and require checking/removing conflicting
packages. The draft uses the older `/usr/share/keyrings`/`docker.list` method.
It installs the latest available Docker packages with no tested version policy.
See [Install Docker Engine on Debian](https://docs.docker.com/engine/install/debian/).

Needed change: follow the current official repository method, record supported
Debian versions, pin an approved Docker/Compose version or define an upgrade
test policy, and capture `docker version`/`docker compose version` in the
deployment record.

### H-8 — Moving image tags make deployments non-reproducible

Nearly every Dockerfile and several services use `node:lts`; Redis uses
`redis:7-alpine`; PostgreSQL uses `postgres:16`. Rebuilding later can pull a
different OS, Node major/minor, or database patch. Node's release status changes
over time; production should use a supported LTS line, and Node 16 used by the
credential script is EOL. See the official
[Node.js release table](https://nodejs.org/en/about/previous-releases).

Needed change: pin base/runtime images by tested version and preferably digest,
use immutable app release tags, scan and rebuild on a planned cadence, and
document the isolated compatibility exception for the Node 16 credential tool.

### H-9 — `update_db_creds.sh` is destructive and the draft describes it incorrectly

The draft says it “produces temporary `node_modules` — safe to delete.”
[`run_scripts/update_db_creds.sh`](../run_scripts/update_db_creds.sh) actually
runs `rm -rf /opt/apps/data_acquisition/node_modules` before starting its
temporary container. This may delete a populated host dependency directory and
is materially different from merely cleaning up a temporary directory.

It also runs an EOL Node image with the entire repository mounted read-write,
loads the full `.env`, and can pull the image at execution time.

Needed change: make the deletion target and consequences explicit, add a
preflight guard for the exact path, pin the compatibility image digest, mount
only required paths, and define how generated credentials are backed up and
validated.

### H-10 — Dependency installation and caches are not a deployment strategy

The draft labels both of these as different workflows:

```text
npm ci --omit=dev --no-audit --no-fund && npm run ...
npm ci --omit=dev && npm run ...
```

Both run `npm ci`, which deletes/recreates `node_modules`. Running this inside
every cron invocation makes each job depend on registry/network availability,
adds latency, creates race conditions when jobs share a cache, and defeats much
of the cache benefit.

Ops-dashboard and incident-engine use `npm install` rather than `npm ci`.
`pg_manage_v2` has no package lock and its Dockerfile uses `npm install`.

Needed change: install from committed lockfiles once per immutable image or
release cache, then run jobs without reinstalling. Never let concurrent jobs
mutate the same dependency directory.

### H-11 — The draft does not install the application schedules

Except for incident-engine, the draft does not define or install cron/systemd
timers for the apps it sets up. [`cron-jobs.txt`](./cron-jobs.txt) contains many
legacy `/home/prod/...` non-Docker paths and is not a safe canonical schedule
for the new `/opt/apps` layout.

It also has no overlap protection. Multiple jobs start at the same minute, and
another copy starts 30 minutes later whether the previous copy finished or not.

Needed change: create one reviewed schedule manifest for this architecture;
state the crontab owner, `PATH`, timezone, logging, alerting, and environment;
use `flock` or an equivalent per-job concurrency policy; use timeouts where
appropriate; and include install/list/remove/rollback commands.

### H-12 — There is no complete backup, restore, retention, or disaster-recovery procedure

The guide creates persistent Postgres and Redis storage but does not schedule
backups, protect them off-host, encrypt them, define retention, monitor failures,
or rehearse restores. A one-line `pg_hba.conf.bak` is not a database backup.

Needed change: define automated logical and/or physical PostgreSQL backups,
Redis persistence/backup handling, configuration and secret recovery, off-host
copies, retention, restore tests, and RPO/RTO acceptance.

### H-13 — Docker and application logs can fill disks

The guide creates application log directories but does not configure retention
for them or Docker's container logs. Docker documents that the default
`json-file` logs can grow until storage is exhausted and recommends rotation or
the `local` driver; see
[Docker post-install logging guidance](https://docs.docker.com/engine/install/linux-postinstall/).

Needed change: define rotation/compression/retention for `/opt/run-logs`, Redis,
PostgreSQL, and Docker logs; monitor inode and byte usage on both disks.

### H-14 — Operations dashboard deployment needs a production security boundary

Ops-dashboard:

- publishes port 8080 on all host interfaces;
- has no documented authentication or reverse-proxy/TLS layer in this guide;
- runs from a mutable `main` checkout instead of a reviewed deploy worktree;
- bind-mounts source read-write into a long-running service;
- uses a moving `node:lts` image;
- has no Compose healthcheck;
- defaults to encrypted-but-unverified PostgreSQL TLS.

Needed change: deploy a reviewed immutable revision, install dependencies
reproducibly, use a read-only source/image, add health/restart verification, and
place it behind private access or authenticated HTTPS.

### H-15 — Hardcoded numeric identities make “similar server” reuse unsafe

Acumatica uses `1006:987`; Monday, reports, incident-engine, and ops-dashboard
use examples/defaults around `105:987`; reports bakes those IDs directly into
its Dockerfile. The draft tells the operator to discover IDs but does not feed
them consistently into these apps.

Impact: files can become unwritable or be owned by an unrelated account on
another server.

Needed change: parameterize IDs, validate that they map to the intended account
on every host, and run a write/read/delete smoke test for every bind mount.

## App-by-app reconciliation

| App | Current observation | Required runbook correction |
|---|---|---|
| data_acquisition | Local Dockerfile and gosu entrypoint are used; Compose hardcodes DEV mounts and staging tag; bare `RUN_LOGS_DIR` expects a full `host:container` spec; TLS helper can downgrade; local env uses DB superuser. | Fix environment selection, make the log mount explicit long syntax, fail TLS closed, and provision a dedicated DB role. |
| hhm_rpp_ge | A tracked Dockerfile and entrypoint now exist, contrary to draft lines 807/885; Compose has no build declaration and hardcodes DEV data plus a staging image. | Update the stale matrix and add one real shared-image build/release step. |
| hhm_rpp_philips | No local Dockerfile; intentionally consumes GE's `hhm_rpp:staging`; `docker compose build` is a no-op. | Document the external image dependency and its required build order/version. |
| hhm_rpp_siemens | Same shared-image and no-op build problem as Philips. | Same correction as Philips. |
| acumatica_sync | Draft-built image is unused; Compose runs stock Node as hardcoded UID/GID; this repo contains only its app-specific `utils/queries.js`, not the general shared utility tree. | Decide whether to use the Dockerfile/entrypoint or delete that path from the procedure; do not claim all apps have the same vendored utilities. |
| monday | A tracked root entrypoint now exists, contrary to the draft matrix; Compose build is real but IDs and staging tag are hardcoded and TLS is forced to `require`. | Update the matrix; parameterize identity/tag and enable verified TLS. |
| reports | Tracked Dockerfile/entrypoint exist but Compose runs unrelated `aux:staging`; the draft builds unused `reports:svc`; TLS is forced to `require`. | Align build and runtime image, then verify entrypoint/user and TLS. |
| part-source-pipeline | Compose build and root entrypoint align; IDs and staging tag are hardcoded. Host log path uses `part-source-pipeline`, container path uses `part_source_pipeline`. | Parameterize identity/tag and verify that the differing log names match logger configuration. |
| incident-engine | One-shot/no-Dockerfile design is coherent; least-privilege TLS and DB code are strong. Deploy worktree creation is missing and DB scripts hardcode staging. | Complete reviewed-SHA worktree provisioning and parameterize/validate database target. |
| ops-dashboard | Long-running/no-Dockerfile model is coherent but production exposure, mutable source, dependencies, healthcheck, identity, and TLS need work. | Add a production service boundary and immutable deploy procedure. |
| redis-admin | Compose parses but config bind sources are wrong; configs do not currently enable Redis authentication; all ports are published. | Fix source paths, decide ACL/password policy, and keep Redis private. |
| pg_manage_v2 | All four migration scripts cited by the draft exist. The image uses moving Node tags, no package lock, and an unpinned APT supply chain. | Pin dependencies/image, add preflight/validation/rollback, and treat migration as a controlled change. |
| imprivata-poc | Draft correctly labels it a PoC, but Compose still defaults to a stale SDK wheel and the container runs as root when `RUN_USER` is unset. | Keep it outside production scope until the default, runtime identity, secret lifecycle, and vendor support model are resolved. |
| acquisition-v2 | Present in `/opt/apps` but omitted from the claimed “current full suite”; its Compose has the same DEV/staging hardcoding. | Explicitly classify it as replacement, experiment, or deployed app; do not leave its relationship to data_acquisition ambiguous. |
| odd-jobs | Present in `/opt/apps` but omitted; still mounts all `/opt/resources:ro` and uses older identity/build conventions. | Explicitly include, retire, or mark out of scope and document any schedules that still depend on it. |

## Other needed corrections and considerations

### Database initialization and schema management

- Replace “wait a few seconds” with a healthcheck/readiness loop such as
  `pg_isready` plus a bounded timeout.
- Draft section 2.4 says to confirm `pg_db` is attached before the container has
  been created; rename it to network verification or move it after startup.
- Do not create both DEV and STAGING databases unconditionally, and add the
  missing PROD decision.
- Do not keep application schema evolution as a large SQL block pasted from a
  Markdown file. Put it in a versioned migration with `ON_ERROR_STOP`, checksum,
  migration ledger, preconditions, and postconditions.
- `CREATE TABLE IF NOT EXISTS` does not upgrade an existing table to a changed
  definition. Every future schema change needs an explicit migration.
- Define extension installation, owners, default privileges, and role creation
  as code.
- Add capacity configuration and monitoring for connections, storage,
  autovacuum, WAL, checkpoints, and slow queries.

### Redis persistence and migration

- The actual configs enable AOF and RDB saves but do not enable authentication.
  The comment suggesting `REDIS_PASSWORD` does not cause Redis to consume that
  environment variable.
- Copying only `dump.rdb` into an AOF-enabled destination requires an explicit
  persistence-state procedure; verify which file Redis loads and inspect
  startup logs.
- Compare logical key counts per selected database, TTL distributions, sample
  values, memory usage, and application behavior—not only total `DBSIZE`.
- Do not seed DEV and STAGING from PROD without approved data classification,
  masking, access controls, and retention.

### Directory and permission handling

- Recursive `chmod -R 2775` can add inappropriate execute/setgid bits to files
  if rerun against populated trees. Apply directory and file modes separately.
- The `docker` group is a host-administration boundary, not a harmless
  shared-files group. Consider a separate non-privileged group for shared files
  so log/cache access does not imply Docker root-equivalent access.
- Add default ACLs to the actual per-app directories after creation and verify
  effective ACL masks.
- Add mount-source assertions. Short bind syntax can silently create a
  root-owned directory when a source is misspelled.

### Service health, resource control, and boot behavior

- Add healthchecks for PostgreSQL, Redis, and ops-dashboard and define what
  blocks dependent jobs.
- Add CPU/memory/PID limits or documented host capacity assumptions.
- Verify external networks and required images before scheduling jobs.
- Test a full host reboot: data disk mounts first, Docker starts, database and
  Redis recover, the dashboard starts, and one-shot schedules resume without
  racing readiness.
- Add clock synchronization/timezone verification because schedules,
  month-to-date migrations, TLS validity, and application timestamps depend on
  accurate time.

### Documentation integrity

The draft says older docs were reconciled, but repository documentation still
contradicts the actual design:

- [`README.md`](../README.md) still says to clone `utils` separately and says
  `app_tools` builds `Dockerfile.runtime`.
- [`docker_setup.md`](./docker_setup.md) and
  [`run-notes.md`](./run-notes.md) also describe `Dockerfile.runtime`.
- [`docker-runtime.md`](./docker-runtime.md) says the entrypoint copies an SSH
  bundle, while the actual tracked entrypoint only uses gosu.
- `Dockerfile.runtime` does not install gosu but copies the gosu-based current
  entrypoint, so using that legacy image path would fail at runtime.
- [`entrypoint.md`](./entrypoint.md) is the closest match to the current
  data-acquisition entrypoint and shared read-only SSH layout.
- [`cron-jobs.txt`](./cron-jobs.txt) mixes the new Docker path with many legacy
  `/home/prod` jobs.

The audited draft itself is currently untracked in Git. A new server cloning the
repository cannot receive it until it is reviewed and committed.

## Recommended correction order

1. Freeze and document the real environment/release model: supported
   environments, branches, immutable images, databases, networks, and data
   boundaries.
2. Fix Redis config mounts and app image/build alignment; add clean-host
   preflight tests.
3. Close network exposure and design the admin/authentication boundary.
4. Replace shared PostgreSQL superuser use with app roles and standardize
   fail-closed `verify-full` TLS.
5. Write and rehearse separate backup/restore and production migration/cutover
   runbooks.
6. Define host users, non-privileged file groups, numeric identity handling,
   SSH ownership, secrets, and ACLs.
7. Pin runtime/dependency versions and stop installing dependencies in each
   scheduled run.
8. Create the canonical schedule with locking, timeouts, observability, and
   rollback.
9. Add healthchecks, log retention, disk monitoring, resource controls, and a
   full reboot/recovery test.
10. Reconcile or archive contradictory docs, commit the approved runbook, and
    test it on a blank staging VM.

## Acceptance test before calling the guide final

A reviewer who did not author the guide should be able to build a blank staging
VM using only committed material and approved secrets, then demonstrate:

- every referenced file, branch, image, and script exists;
- no command reports a misleading success such as “No services to build”;
- the large disk is persistent and contains all intended Docker/containerd
  data after reboot;
- Redis and PostgreSQL are unreachable from unauthorized networks;
- Redis loads the intended configs and migrated state;
- PostgreSQL rejects non-TLS connections and rejects an untrusted or
  wrong-host certificate;
- no application logs in as a database superuser;
- every container runs with its intended UID/GID and can access only required
  mounts;
- SSH jobs read the private key and verify approved host fingerprints;
- dependencies and images are immutable and can be rebuilt from lockfiles;
- schedules are installed once, cannot overlap unexpectedly, and alert on
  failure/staleness;
- backups restore successfully to a separate test target;
- a host reboot recovers storage, networks, stateful services, dashboard, and
  schedules;
- the migration has recorded validation totals, a go/no-go gate, and a tested
  rollback;
- the same procedure cannot accidentally mix DEV, STAGING, and PROD resources.

Until those tests pass, the document should be labeled a working draft rather
than the final server setup procedure.
