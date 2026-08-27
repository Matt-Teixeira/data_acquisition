# CLAUDE.md — data_acquisition

> Migrated to the fleet Docker/release paradigm **2026-08-24** (pilot app; cutover
> verified over two full cron cycles). Conventions reference: `docs/migration_CLAUDE.md`
> Parts 1+3. Older setup docs (`setup.md`, `docs/docker_server_full_setup_2.1.md`) remain
> authoritative for *server-wide* provisioning but are superseded by the paradigm docs
> for *app-level* Docker/release conventions.

**data_acquisition** is a Node.js run-once pipeline fleet: HHM equipment data pulls
(GE / Philips / Siemens over lftp/rsync/ssh), MMB log acquisition (run groups 0–7),
Philips MRI rsync, althea env pulls, VPN/tunnel resets, offline-alert heartbeats, and
the system-reset totalizer. Dispatch is `index.js <run_group> [schedule] [manufacturer]
[modality]`, cron-scheduled (see *Scheduling*). Run-once by design — triggered on a
schedule, never a long-running service.

---

# PART 1 — SHARED APP ARCHITECTURE (fleet conventions, with this app's deltas)

## Dev copy vs release copy

- **Dev clone** — your own checkout (e.g. `~/apps/data_acquisition`). Image
  `data-acqu:<your-username>`, runs as you, logs stay in-tree.
- **Release copy** — `/opt/apps/data_acquisition`, produced ONLY by `build-release.sh`.
  Never edit it, never `git pull` in it — it is not a git repo, it is build output.
  Image `data-acqu:svc`, runs as `svc`, logs to `/opt/run-logs/data_acquisition`,
  `RELEASE_SHA=<commit>` stamped into its `.env`.

## Standardized Docker setup (5 files)

| File | This app's specifics |
| ---- | -------------------- |
| `docker/Dockerfile` | node:lts + gosu + job tooling (lftp/rsync/sshpass/mdbtools/expect). Build args `USER_ID, DOCKER_GID, UID_0 (svc), UID_1, UID_2` — **no defaults on purpose**: a missing value fails the build instead of baking a wrong uid. `LABEL version="${USER_ID}"`. **Delta from reference:** the entrypoint is COPY'd into the image (self-contained), paired with a deny-by-default `.dockerignore`. |
| `docker/entrypoint.sh` | `RUN_USER` (default `svc`) → gosu. While still root, repairs the structured log dir (`utils/logger/logs`; `logs/` repair removed with winston 2026-08-27) — but only when root-owned, so a deliberately-chowned production dir is left alone. |
| `docker-compose.yaml` | Service to use is **`app_tools`** (`data-acqu:${USER_ID}`). The `app` service is deprecated. Mounts: `./:/workspace` (node_modules rides along in-tree), `${LOG_DIR:-./utils/logger/logs}` (fails SAFE to the dev path), `${DATA_STORE_DEV}:/workspace/files`, `/opt/resources/ssh:ro`. Networks: `pg_net` + `redis-admin_redis_net` (external). |
| `build.sh` | One root `npm install` inside a throwaway node:lts container as the host user (in-tree `node_modules`, per-copy), then `docker compose build app_tools`. |
| `build-release.sh` | Mirrors the WORKING TREE to `/opt/apps/data_acquisition`. Clean-tree guard (untracked files count) sits above the wipe; `--allow-dirty` is the emergency override — never habit. Applies `#RELEASE:` overrides, stamps `RELEASE_SHA`, builds as svc. (No longer recreates `logs/` — winston retired 2026-08-27.) |

## Running

```bash
# Development — from YOUR clone, as yourself
RUN_USER=<you> docker compose run --rm app_tools node index.js <run_group> [args]

# Production — from the release copy; RUN_USER omitted (entrypoint defaults to svc)
cd /opt/apps/data_acquisition && docker compose run --rm app_tools node index.js <run_group>
```

Run groups (see `package.json` scripts for the full argv mapping): `hhm null <GE|Philips|Siemens> <CT|CV|MRI>`,
`mmb <0-7>`, `philips`, `demo_systems`, `althea_env`, `ip_reset`, `offline_alert`,
`update_ipsec`, `system_reset_totalizer`, `update_db_creds`, `ip_sec`.

## Environment variables

Template: `.env.example` (tracked; `.env` is gitignored). Identity keys carry `#RELEASE:`
overrides — **only identity, never PG*/REDIS_* (those describe the server)**:

| Key | Dev | Release |
| --- | --- | ------- |
| `USER_ID` | your username | `svc` (drives image tag + log-file tag + boot label) |
| `LOG_DIR` | `./utils/logger/logs` | `/opt/run-logs/data_acquisition` |
| `LOGGER_MODE` | `log_and_console` | `log` |

`RELEASE_SHA` is injected by `build-release.sh` — never set it by hand; dev runs log
`dev-tree`. Retired keys (do not reintroduce): `IMAGE_TAG`, `RUN_ENV`, `RUN_LOGS_DIR`,
`NODE_MOD_CACHE_DEV`, `LOGGER`, pinned `RUN_USER`.

App-specific keys: `PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE/PG_SSLMODE/PG_SSL_PATH`
(note: NOT the fleet's `PG_HOST` names), `REDIS_HOST/REDIS_PORT/REDIS_PW`, `APP_SECRET`,
`SSH_KEY` (file under `/opt/resources/ssh/`), `DATA_STORE_DEV`, `VNS3_IP/VNS3_PW`
(ip_reset/tunnel jobs only), `PHILIPS_MRI_SHELL_TIMEOUT_S`.

## Logging — ONE logger writes files (winston side-logger retired 2026-08-27)

1. **Structured run log** (`utils/logger/log.js`) — THE run record: events in
   memory → `LOG_DIR/data_acquisition-log.${USER_ID}.<run_id>.json` +
   `util.app_run_logs` (verbose + warn/error subset). The boot `env_note`
   records `USER_ID`, `LOGGER_MODE`, `RELEASE_SHA`. The terminal `run_outcome`
   event and graded exit codes
   (**run_outcome/v1**: 0 success/skipped, 1 failed, 2 partial/self-log-failure, 3 usage)
   are consumed by ops-dashboard and incident-engine — do not change their shape.
2. **Breadcrumb logger** (`logger.js` at repo root) — console-only since
   2026-08-27 (was the winston side-logger writing `./logs/adp.*` files, ~70%
   of them empty and none operationally read). Same `log(level, jobId, …)`
   signature at its ~43 call sites; error/warn always print to console (→ the
   bounded cron `.out` in production), info/debug only under
   `LOGGER_MODE=log_and_console`. It writes NO files: `./logs` is gone from
   entrypoint repair, build-release recreation, and preflight.

SIGTERM/SIGINT flush the structured log's both sinks (file + DB) exactly once
and exit non-zero (`E_SIGNAL`) — a killed run is a failed run, never exit 0.

## Scheduling

**This app's schedule lives in matt-teixeira's USER crontab** (alongside hhm_rpp_ge,
hhm_rpp_philips, and incident-engine) — NOT the shared `svc` crontab, which holds
mmb-rpp/odd-jobs/etc. Consolidating into the svc crontab per the fleet paradigm is a
pending follow-up (BACKLOG 6f). The installed entries are recorded in
`cron-bk/crontab.restore-2026-08-24.cron`; since it is a personal crontab,
`crontab <that-file>` is a safe install method (the never-install-from-file rule
protects the SHARED svc crontab only — there, always `sudo crontab -u svc -e`).

Entry conventions (all 24 entries follow them): run from `/opt/apps/data_acquisition`,
absolute `/usr/bin/docker` + `/usr/bin/flock`, `-T` under cron, `flock -n` per job
(skip, never queue), output to bounded `>/opt/run-logs/data_acquisition/cron.<job>.out`,
no `RUN_USER`, no `HOME`. Verify a schedule from `util.app_run_logs`, not cron's own
logs — and note a run's identity/commit: production rows read `svc | <sha>`; a
`dev-tree` row on a schedule means cron is running the wrong copy.

## Secrets

Host-owned credentials live root-only under `/opt/resources/secrets/` and are copied
into each copy's `.env`. **Both copies go stale together** on rotation — the dev clone
and the release copy must both be registered with the rotation script for `PGPASSWORD`
and `REDIS_PW`. A sudden auth failure across apps usually means a rotation happened, not
a code change; `preflight-check.sh` catches this with REAL authenticated checks (Redis
authed PING; Postgres from a sibling container — loopback psql lies).

## Preflight

```bash
bash preflight-check.sh   # exit 0 + ZERO warnings = good to run
```

---

# PART 2 — APP SPECIFICS / OPERATIONS

- **Job shell-outs are cwd-relative** (`./read/sh/...`, `./jobs/mmb/read/sh/...`) —
  always launch with cwd = repo root (compose sets `working_dir: /workspace`).
- `read/exec-phil_cv_unzip.js` and `read/exec-phil_cv_data_grab.js` contain a dead
  `RUN_ENV` switch whose result is unconditionally overwritten with `${cwd}/files` —
  do not "fix" the env vars expecting a behavior change.
- `run_scripts/update_db_creds.sh` bypasses compose AND the entrypoint (raw node:16
  container); its log mount is wired by hand to the container's fixed log path.
- Dev-clone runs hit the SAME staging DB, `/opt/resources/acqu_files`, and Redis
  (`redis_dev-0-4` cursors) as production — a dev run is a real run against shared
  state; choose test jobs accordingly (`offline_alert` is the cheap one).
- Verify any run from the DB, not the log file:
  ```sql
  SELECT (verbose_log->0->'note'->>'RELEASE_SHA') sha, COUNT(*), MAX(inserted_at)
  FROM util.app_run_logs WHERE app_name='data_acquisition'
    AND inserted_at > now() - interval '2 hours' GROUP BY 1;
  ```
  `dev-tree` appearing on a schedule means cron is running the wrong copy.
