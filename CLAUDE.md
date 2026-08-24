# CLAUDE.md — data_acquisition

> **⚠️ MID-MIGRATION (started 2026-08-24).** This app is being aligned to the fleet
> Docker/release paradigm. For conventions, `docs/migration_CLAUDE.md` (Parts 1 and 3) is
> authoritative; the sections below are corrected as each migration step lands. Cutover
> status and sequencing: `docs/MIGRATION-RUNBOOK-data_acquisition.md`. Older setup docs
> (`setup.md`, `docs/docker_server_full_setup_2.1.md`) remain authoritative for
> *server-wide* provisioning but are superseded by the paradigm docs for *app-level*
> Docker/release conventions. This banner comes off when the cutover verifies.

**data_acquisition** is a Node.js run-once pipeline fleet: HHM equipment data pulls
(GE / Philips / Siemens over lftp/rsync/ssh), MMB log acquisition (run groups 0–7),
Philips MRI rsync, althea env pulls, VPN/tunnel resets, and offline-alert heartbeats.
Dispatch is `index.js <run_group> [schedule] [manufacturer] [modality]`, scheduled from
the shared `svc` crontab. Run-once by design — triggered on a schedule, never a
long-running service.

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
| `docker/entrypoint.sh` | `RUN_USER` (default `svc`) → gosu. While still root, repairs BOTH log dirs (`utils/logger/logs` and `logs/`) — but only when root-owned, so a deliberately-chowned production dir is left alone. |
| `docker-compose.yaml` | Service to use is **`app_tools`** (`data-acqu:${USER_ID}`). The `app` service is deprecated. Mounts: `./:/workspace` (node_modules rides along in-tree), `${LOG_DIR:-./utils/logger/logs}` (fails SAFE to the dev path), `${DATA_STORE_DEV}:/workspace/files`, `/opt/resources/ssh:ro`. Networks: `pg_net` + `redis-admin_redis_net` (external). |
| `build.sh` | One root `npm install` inside a throwaway node:lts container as the host user (in-tree `node_modules`, per-copy), then `docker compose build app_tools`. |
| `build-release.sh` | Mirrors the WORKING TREE to `/opt/apps/data_acquisition`. Clean-tree guard (untracked files count) sits above the wipe; `--allow-dirty` is the emergency override — never habit. Applies `#RELEASE:` overrides, stamps `RELEASE_SHA`, recreates `logs/`, builds as svc. |

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

## Logging — TWO loggers, know which one you're reading

1. **Structured run log** (`utils/logger/log.js`): events in memory →
   `LOG_DIR/data_acquisition-log.${USER_ID}.<run_id>.json` + `util.app_run_logs` (verbose
   + warn/error subset). The boot `env_note` records `USER_ID`, `LOGGER_MODE`,
   `RELEASE_SHA`. The terminal `run_outcome` event and graded exit codes
   (**run_outcome/v1**: 0 success/skipped, 1 failed, 2 partial/self-log-failure, 3 usage)
   are consumed by ops-dashboard and incident-engine — do not change their shape.
2. **Winston side-logger** (`logger.js` at repo root): free-text job detail →
   `./logs/adp.${USER_ID}_<ISO>.log`. Required at module scope by ~10 job files, so
   `logs/` must exist or jobs die on first `log()` call (entrypoint/build-release
   guarantee it).

SIGTERM/SIGINT flush both sinks exactly once and exit non-zero (`E_SIGNAL`) — a killed
run is a failed run, never exit 0.

## Scheduling

Shared `svc` crontab: `sudo crontab -u svc -e` (NEVER `crontab -u svc <file>` — that
wipes every other app's entries). Entries run from `/opt/apps/data_acquisition`, use
absolute `/usr/bin/docker` + `/usr/bin/flock`, `-T` under cron, `flock -n` per job,
output to bounded `>/opt/run-logs/data_acquisition/cron.<job>.out`. Verify a schedule
from `util.app_run_logs`, not cron's own logs.

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
