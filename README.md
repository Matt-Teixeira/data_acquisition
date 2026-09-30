# data_acquisition

Dockerized HHM / MMB data-acquisition jobs: half-hourly cron-driven pulls from imaging
systems (GE / Philips / Siemens CT·CV·MRI), MMB schedules, VPN IP maintenance, and
offline alerting. Node.js jobs dispatched through `index.js` (`npm run <job>`), writing
to the shared Postgres (`pg_db`, database `staging`) and Redis.

## Run model (current, verified 2026-07-27)

- **Image:** `data-acqu:staging`, built from [docker/Dockerfile](docker/Dockerfile)
  (node:lts + lftp/rsync/mdbtools tooling, baked gosu entrypoint that drops to
  `RUN_USER`, users created from `UID_*`/`DOCKER_GID` build args). Build with
  `docker compose build app_tools`.
- **Invocation:** one-shot `docker compose run --rm app_tools bash -lc "npm run <job>"`
  against a pre-warmed `node_modules` cache
  (`/opt/resources/node_mod_cache/data_acquisition`). Warm once with
  `npm ci --omit=dev`; scheduled runs never reinstall.
- **`utils/` is vendored** in this repo — do not clone the old `AvanteHS-RTT/utils`.
- **Logs:** with `RUN_ENV=dev`, per-run JSON lands in `utils/logger/` (pruned nightly);
  every run also self-logs to `util.app_run_logs` (what ops-dashboard reads).
- **SSH bundle:** jobs that SFTP/rsync mount `/opt/resources/ssh` read-only
  (`SSH_KEY` in `.env`).

## Docs

| Doc | What it is |
|---|---|
| `pg_manage_v2/docs/runbook/full_setup_3.0.md` (in the pg_manage_v2 repo) | **The server build guide** — full server setup for this and all sibling apps; section 4.1 is this app |
| [docs/schedules.md](docs/schedules.md) | Canonical cron schedule manifest (live crontab, stagger design) |
| [docs/entrypoint.md](docs/entrypoint.md) | Per-app baked entrypoint standard |
| docs/attic/ | Deprecated docs from the pre-vendoring era (kept for history) |

## Quick start (this app only)

```bash
cd /opt/apps/data_acquisition          # branch: DEV_docker on acq-vm-0
# .env from the secret store (key list in the setup guide, STEP 6)
docker compose build app_tools
chmod -R g+rwX utils/logger && chgrp -R docker utils/logger
docker compose run --rm app_tools bash -lc "npm ci --omit=dev --no-audit --no-fund"
docker compose run --rm app_tools bash -lc "npm run <job_name>"
```
