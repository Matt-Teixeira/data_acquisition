# Second Audit of `docker_server_full_setup_2.0.md` — live verification on acq-vm-0

Audit date: 2026-07-27
Audited draft: [`docker_server_full_setup_2.0.md`](./docker_server_full_setup_2.0.md)
Prior audit validated: [`docker_server_full_setup_2.0_audit.md`](./docker_server_full_setup_2.0_audit.md) (Codex)

## Scope and method

Unlike the Codex audit (static, no Docker socket access), this audit verified claims
against the **live server**: running containers, live Redis/Postgres config, images,
crontab, file permissions, git branches, and per-app `.env` contracts (variable names
and non-secret values only). Nothing was modified.

Operating context supplied by Matt: **no PROD server exists yet** — only dev and
staging servers are being built. Findings are graded against that reality, not against
a hypothetical production cutover.

Server identity as observed: hostname `acq-vm-0`, single 2 TB root disk (no `/mnt/sdc`),
Docker 29.4.3 / Compose v5.1.3, Docker root at `/var/lib/docker` (no `daemon.json`).
Live workload: pg_db (postgres:16), 4 Redis instances, ops-dashboard, and a full
half-hourly acquisition crontab. `redis-PROD` holds live state (DBSIZE 1711) — this
box is doing real production work even though it is nominally dev/staging.

## Executive summary

- The Codex audit is **substantially correct**. Of its 8 release-blocking and 15
  high-priority findings, I confirmed nearly all against live state. Three are
  overstated or wrong in their *impact* (RB-2, H-9, H-10 — details below), and RB-1/RB-7
  need reframing given that PROD doesn't exist yet.
- Live verification surfaced **new findings Codex could not see**, the most important
  being: **Redis is silently running on default config** (the broken `conf/*.conf`
  directory mounts don't crash Redis — they read as an *empty file*, so `appendonly yes`
  and the save rules in `config/*.config` are simply not in effect on any instance,
  including `redis-PROD`).
- The guide's biggest structural problem for the stated goal ("align the doc with how
  apps run now") is that its `ENV` convention describes an **aspiration, not the
  running system**. acq-vm-0 is simultaneously: `RUN_ENV=dev`, database `staging`,
  images tagged `:staging`, branches split between `DEV_docker` and `STAGING_docker`,
  and serving live "prod" Redis state. A fresh server built from the doc with any single
  `ENV` value cannot reproduce this box.
- A concrete doc-edit checklist is in **Part 3**; server-side fixes (where reality, not
  the doc, is wrong) are in **Part 4**.

---

## Part 1 — Validation of the Codex audit

### Release-blocking findings

| # | Verdict | Notes |
|---|---|---|
| RB-1 | **Confirmed, reframe** | No `origin/PROD_docker` exists on any repo — expected, since no PROD server exists yet (per Matt). The real, current-scope defect stands: compose files hardcode `${NODE_MOD_CACHE_DEV}` / `${DATA_STORE_DEV}` and `:staging` image tags regardless of `ENV`, so the doc's "set `ENV` once" convention is not implemented by anything. See N‑3. |
| RB-2 | **Confirmed, impact corrected** | `conf/prod.conf` etc. are root-owned **empty directories** (Docker auto-created them); real configs sit unused in `config/*.config`. But Codex's predicted failure ("will fail or restart-loop") is wrong: all four Redis containers are Up/healthy for weeks. `fopen()` on a directory succeeds and reads as empty, so Redis loads an **empty config** and runs on defaults. Live proof on redis-PROD: `CONFIG GET appendonly` → `no` (config file says `yes`); `CONFIG GET save` → default `3600 1 300 100 60 10000` (config says `900 1 / 300 10 / 60 10000`). Silent misconfiguration — worse than a crash. See N‑1. |
| RB-3 | **Confirmed** | `hhm_rpp_ge/docker-compose.yaml` `app_tools` has `image: hhm_rpp:staging` and **no `build:` key**; Philips/Siemens intentionally reuse the same image and have no Dockerfile. `docker compose build` in all three repos is a no-op. The image on the box (`hhm_rpp:staging`, built 2026-06-03) was built out-of-band. The doc must document the one real build (from `hhm_rpp_ge/docker/Dockerfile`, tagged `hhm_rpp:staging`) and the ordering. |
| RB-4 | **Confirmed** | reports compose runs `aux:staging` (exists, built 2026-06-10, gosu entrypoint) — the doc's `docker build -t reports:svc .` produces an image nothing uses, and no `reports:svc` image exists on the box (proof the doc's path was never exercised). acumatica compose runs stock `node:lts` as `user: "1006:987"`; its tracked Dockerfile/entrypoint are unused and no `acu-sync:svc` image exists. The doc's entrypoint matrix line "acumatica_sync ✅ baked" is wrong for the running system. |
| RB-5 | **Confirmed, with live evidence** | Live working state: `id_dev` is `640 jonathan-pope:docker` — **group-read via `docker` group is what makes it work** for `svc` (uid 105, member of docker). The doc's `chmod 600 id_dev` would break every SFTP/rsync job unless ownership were also moved to the container run user. Also: live `known_hosts` is `644` (not the doc's `660`) and `config` is `664` (not `640`). The doc's permission block matches neither the working system nor a coherent target. The bundle-provisioning gap (how key/config/known_hosts arrive on a new server) is real. |
| RB-6 | **Confirmed** | `/opt/apps/incident-engine-deploy` exists on this box and *is* a linked git worktree (detached at `e3acf72`), and the live cron entry matches the doc. But the doc never creates it — `git worktree add` and deploy-`.env` provisioning are missing steps. |
| RB-7 | **Confirmed as gaps, rescope** | Since no PROD cutover is imminent, treating STEP 4/5 as a full production-cutover runbook is premature. But the core criticisms hold even for dev/staging rebuilds: no readiness gate (`pg_isready` vs "wait a few seconds"), no row-count/DBSIZE validation beyond eyeballing, no final-delta step, no statement of which jobs must be stopped where. Keep STEP 4/5 but label them "seed a new dev/staging server from the current source" and defer the cutover runbook to a separate doc written when a PROD server is actually planned. |
| RB-8 | **Confirmed as fact; severity depends on NSG** | Live: pg 5432, Redis 6379–6382, ops-dashboard 8080 all bound `0.0.0.0` (and `[::]`). Docker's published ports bypass ufw-style host firewalls. I cannot see the Azure NSG from the host — if the NSG only allows team IPs, exposure is mitigated but still worth tightening (Redis has **no auth** — the `requirepass` line is commented out in the configs, which aren't even loaded; see N‑1). Recommendation stands: don't publish Redis at all (apps reach it over `redis_net`), bind pg/dashboard to specific interfaces or keep NSG-restricted, and record the NSG rules in the doc. |

### High-priority findings

| # | Verdict | Notes |
|---|---|---|
| H-1 | **Confirmed** | `CREATE SERVICE ACCOUT USER` (line 68) is bare text inside a bash block; `source ~/.bashrc` doesn't refresh group membership (`newgrp docker` or re-login does). Doc creates `jonathan-pope` but never `matt-teixeira` (uid 1006, referenced later as UID_2). Live `svc` **is** in the docker group (`docker:x:987:jonathan-pope,matt-teixeira,svc`) but the doc's `adduser --system ... svc` never adds it — group-read of the SSH key and group-write of shared dirs depend on that membership. |
| H-2 | **Confirmed** | `PGUSER=postgres` in the `.env` of data_acquisition, all three RPPs, acumatica_sync, monday, reports, part-source-pipeline (and `PG_USER=postgres` in odd-jobs, acquisition-v2). Only incident-engine (`incident_engine_rw`) and ops-dashboard (`ops_dashboard_ro`) use dedicated roles. |
| H-3 | **Confirmed** | [`db/pgPool.js`](../db/pgPool.js#L9-L31) and vendored [`utils/db/pg-pool.js`](../utils/db/pg-pool.js): `require` → `rejectUnauthorized: false`; `verify-*` with missing CA **falls back to unverified with only a console warn**. And every app that isn't incident-engine runs `PG_SSLMODE=require` (in `.env`, and monday/reports additionally force it in compose), so certificate verification is effectively off fleet-wide except incident-engine (`verify-full`). The doc's Step 5 example (`rejectUnauthorized: true`) describes code that isn't what runs. |
| H-4 | **Confirmed** | Both factual points check out: `verify-ca` does not validate hostname (use `verify-full` for the identity test), and PostgreSQL ≥10 reloads SSL cert/key on `pg_reload_conf()` — restart is a choice, not a requirement. The `sed` on `pg_hba.conf` is brittle as described. |
| H-5 | **Confirmed** | Password on the `docker run` command line; same superuser password fanned out to ~8 app `.env` files. `POSTGRES_PASSWORD_FILE` is the low-effort fix. |
| H-6 | **Confirmed, low current impact** | No `daemon.json` and Docker root is `/var/lib/docker` on this box (no second disk — the doc's "skip if no second disk" applies, but its "sanity check: /mnt/sdc/docker" line reads as unconditional and would "fail" here). `docker-disk-migration.md` does not exist anywhere under `/opt/apps` — the doc references a doc that isn't in the repo. The Docker 29 containerd-image-store caveat is relevant: this box runs 29.4.3, so on the *next* fresh install with a data disk, verify where image data actually lands before trusting `data-root` alone. |
| H-7 | **Confirmed, softened** | The keyring/list-file recipe is the older style but *worked* (box has current Docker 29.4.3). Update to the deb822 method when convenient; pinning policy is a fair ask, not a blocker for dev/staging. |
| H-8 | **Confirmed** | `node:lts` resolves to v24.16.0 today and is used by ~6 compose services and 3+ Dockerfiles; `node:16.20.2` (EOL) pinned for the cred tool. Mutable-tag risk is real; own compose comments already suggest pinning (`# image: node:22-bookworm`). |
| H-9 | **Confirmed mechanics, impact overstated** | The script does `rm -rf /opt/apps/data_acquisition/node_modules` — but under the current layout that repo-local dir is a stray (real deps live in `/opt/resources/node_mod_cache/data_acquisition`, bind-mounted over `/workspace/node_modules`), and the container installs into a **tmpfs**, so "nothing lands on the host" is accurate. The doc's note ("produces temporary node_modules — safe to delete after run") is stale — the script already self-cleans. Real issues: hardcoded `APP_DIR`, EOL node:16 image, full repo mounted rw with full `.env`. |
| H-10 | **Impact largely wrong, doc still confusing** | Codex assumed every cron run does `npm ci`. The **live crontab does not**: every job is `docker compose run --rm app_tools bash -lc "npm run <job>"` against the pre-warmed shared cache. `npm ci` is a one-time/manual warm-up step. The doc's two near-identical commands ("first run" vs "normal run" differing only in `--no-audit --no-fund`) are the actual defect — the "normal run" shown (with `npm ci`) is *not* what production cron does. Rewrite that block to: warm cache once with `npm ci`, then `npm run <job>` alone thereafter. The shared-cache concurrency caveat (don't run `npm ci` while jobs are running) is worth one sentence. |
| H-11 | **Confirmed, and worse** | The doc installs no schedules except incident-engine's, yet the **live crontab is the de-facto product** of this whole setup: ~50 entries across data_acquisition (8 HHM jobs at :00/:30, MMB schedules at :16/:46 with `sleep` staggering, VPN resets, offline alerts), hhm_rpp_ge and hhm_rpp_philips (:15/:45 with staggering), system_reset_totalizer at :18/:48, a mail-spool trim, and incident-engine at :25/:55. None of hhm_rpp_siemens / acumatica / monday / reports / part-source-pipeline currently have entries in this crontab. `cron-jobs.txt` is confirmed legacy (63 `/home/prod` lines vs 23 `/opt/apps` lines). No overlap protection (`flock`) anywhere — half-hourly cadence + `--rm` makes pile-ups survivable but not impossible. The doc needs a "STEP 9: install the crontab" section containing the real schedule, its owner (currently `matt-teixeira`'s crontab), and which apps intentionally have no schedule. |
| H-12 | **Confirmed** | No backup/restore anywhere: no backup entries in the crontab, no dump tooling in the doc. For a box holding live `redis-PROD` state and the working staging DB, at least a nightly `pg_dump` + Redis RDB copy off-host is warranted. |
| H-13 | **Confirmed, plus see N‑2** | No log rotation for `/opt/run-logs` or Docker json-file logs — and live evidence shows the pain is already here, just in a different place than Codex looked (dev-mode logs accumulate *inside the repos*: >1 GB / tens of thousands of files in `data_acquisition/utils/logger/`, 16k files in hhm_rpp_philips). |
| H-14 | **Confirmed** | All seven bullets check out against `ops-dashboard/docker-compose.yaml` and `.env.example` (`PG_SSLMODE=require` default). Given no-PROD context, the pragmatic subset: pin the image, add a healthcheck, and confirm NSG restricts 8080. |
| H-15 | **Confirmed, one sharp edge** | `acumatica_sync` runs as `1006:987` — that is **matt-teixeira's uid**, not `svc` (105). Files it writes are owned by a human account, and on another server uid 1006 could be anyone. monday/part-source-pipeline/reports hardcode 105/987 as build args or in the Dockerfile; incident-engine/ops-dashboard hardcode `user: "105:987"` in compose. Works on this box (ids verified: svc=105, docker=987), breaks silently on any host with different ids. Parameterize or at least add a preflight assert to the doc. |

### Codex app-by-app reconciliation table

Spot-checked every row; all factually accurate, including: hhm_rpp_ge **does** have a
tracked `docker/Dockerfile` + `docker/entrypoint.sh` and monday **does** have a tracked
root `entrypoint.sh` + real compose `build:` (producing `monday:staging`) — so the
draft's entrypoint matrix (⚠️ rows for hhm_rpp_ge and monday, and the "add one" action
item) is **stale and should be rewritten**. One correction:

- **part-source-pipeline hyphen/underscore mismatch is intentional and working**, not a
  latent bug: `APP_NAME='part_source_pipeline'` → logger writes
  `/opt/run-logs/part_source_pipeline` *inside the container*, which compose maps from
  host `/opt/run-logs/part-source-pipeline`. A log file is present on the host. Worth a
  one-line comment in the compose file, nothing more.

---

## Part 2 — New findings from live verification (not in the Codex audit)

### N-1 — Redis is running on defaults; intended persistence config is silently ignored (act now)

Extends RB-2 with live evidence and a different failure mode. All four Redis containers
mount an (auto-created, empty) *directory* at `/usr/local/etc/redis/redis.conf`. Redis
opens it, reads zero bytes, logs "Configuration loaded", and runs healthy — on stock
defaults:

- `appendonly no` (intended: `yes`) — AOF durability off on **redis-PROD with 1711 live keys**
- default RDB save rules instead of the intended tighter ones
- no `requirepass` (also true of the intended configs — the line is commented out)

Fix on the server (and in the doc): change the compose mounts to the real files
(`./config/<env>.config`), remove the junk `conf/` directory tree, and recreate the
containers **carefully** (stop → confirm a fresh RDB snapshot exists → recreate → verify
`CONFIG GET appendonly` returns `yes`). Use long-form volume syntax with
`create_host_path: false` so a bad path fails loudly instead of auto-creating a directory.

### N-2 — Run logs actually land inside the repos, not in /opt/run-logs (dev mode)

The vendored logger ([`utils/logger/log.js:18-27`](../utils/logger/log.js#L18-L27))
switches on `RUN_ENV`: `dev` → `./utils/logger/`, `staging`/default → `/opt/run-logs/<app>/`.
Nearly every app on this box has `RUN_ENV=dev`, so:

- `/opt/run-logs/<app>` is **empty** for data_acquisition, all RPPs, monday, reports,
  acumatica, ops-dashboard. Only incident-engine (staging), acquisition-v2, odd-jobs and
  part-source-pipeline (prod logger) write there.
- `data_acquisition/utils/logger/` holds **>1 GB** of per-run JSON (directory inode is
  4 MB — tens of thousands of files, still growing today); `hhm_rpp_philips` has ~16.5k
  files, `hhm_rpp_ge` ~2.9k. Untracked only thanks to `.gitignore`'s `*.json`.

Consequences: the doc's "canonical run-logs location is `/opt/run-logs/<app>`" is only
true for staging-mode apps; the STEP 8 `chmod g+rwX utils/logger` step exists precisely
because dev-mode logs go there (the doc never says so); and there is zero rotation.
Recommended: decide one target (`/opt/run-logs` for all container runs would be
simplest — the dev/staging split predates containerization), or document the split
honestly, and add a cleanup/rotation cron either way.

### N-3 — The server's environment identity is mixed; the doc's single `ENV` knob can't reproduce it

Observed on acq-vm-0 simultaneously:

| Axis | Value |
|---|---|
| Checked-out branches | `DEV_docker` (data_acquisition, acumatica_sync) / `STAGING_docker` (RPPs ×3, monday, reports, part-source-pipeline) / `main` (incident-engine, ops-dashboard, acquisition-v2, imprivata-poc) / `DEV` (redis-admin) / `STAGING` (pg_manage_v2) |
| Image tags | everything `:staging` |
| Compose volume vars | everything `${..._DEV}` |
| `RUN_ENV` | `dev` |
| Database | `staging` (no `dev` database exists in pg_db, despite doc 2.6 creating both) |
| Redis | apps point at `redis-PROD`/live instances; live prod state present |
| Crontab | full production acquisition schedule, live |

The doc's CONVENTIONS block ("set `ENV` once; branches, volume vars and everything
follow") describes none of this. For the doc to be the runbook for "this and similar
servers," it must either (a) genuinely parameterize compose/env by environment (bigger
refactor), or (b) drop the abstraction and state per-server truth: which branch each
repo tracks on the dev box vs the staging box, that image tags are `:staging`
everywhere for now, that volume vars are the `_DEV`-suffixed names regardless of server,
and that `RUN_ENV` controls logger routing (N‑2), not deployment. Option (b) matches
"align the doc with the way apps are running now" and can be done today.

### N-4 — Doc build/tag commands don't match what compose consumes

Beyond RB-3/RB-4: the doc says `docker build -t monday:svc .` but monday's compose has a
real `build:` producing `monday:staging` (just run `docker compose build`). The doc's
`reports:svc` / `acu-sync:svc` tags exist nowhere on the box. Every per-app section
should use the single command that produces the image its compose actually runs, and
name that image explicitly.

### N-5 — STEP 7 APPS list omits apps that exist on the box

`/opt/run-logs` and `/opt/resources/node_mod_cache` contain `acquisition-v2` and
`odd-jobs` dirs; neither is in the doc's `APPS` list. acquisition-v2 is the strangler-fig
replacement for data_acquisition, currently **paused** (its totalizer cron line was
rolled back to data_acquisition on 2026-07-13 and left commented in the crontab). The
doc should list both with a one-line status (acquisition-v2: staged replacement, currently
paused; odd-jobs: legacy — mounts all of `/opt/resources:ro`, uses old image conventions —
retire or document).

### N-6 — Doc Step 5 (app SSL config) uses variable names no app uses

The example uses `PG_HOST/PG_PORT/PG_DB/PG_USER/PG_PW`; the fleet uses libpq-style
`PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD` plus `PG_SSLMODE`/`PG_SSL_PATH`. Combined
with H-3 (the example's `rejectUnauthorized: true` isn't what `require` mode does), this
section documents an app-config contract that doesn't exist. Rewrite it around the real
`.env` keys and the real `buildSsl()` behavior — or better, fix the code to fail closed
and then document that.

### N-7 — Minor inconsistencies worth one-line fixes

- monday's `.env` contains both `PGUSER=postgres` and `PG_USER=avantehs_admin` — two
  conventions in one file; only one is read. Delete the dead one.
- Legacy debris still present and now doc-contradicted: `/opt/resources/entrypoint.sh`
  (deprecated global entrypoint) and `/opt/resources/run-logs/` (with a stray `sudo`
  subdir). Safe to archive/remove per the doc's own guidance — after confirming nothing
  references them (nothing in the live crontab or compose files does).
- `README.md`, `docs/docker_setup.md`, `docs/run-notes.md`, `docs/docker-runtime.md`
  still describe the pre-vendoring / `Dockerfile.runtime` / ssh-copy-entrypoint world
  (confirmed: README tells you to clone `AvanteHS-RTT/utils` and says app_tools builds
  `Dockerfile.runtime`). Codex's "documentation integrity" list is accurate. Archive or
  update them; two contradictory generations of docs in one repo is how the next server
  gets built wrong.
- `docker/Dockerfile.runtime` and `docker/New_Dockerfile` are still tracked alongside the
  real `docker/Dockerfile` — delete or move to an `attic/`.
- Both this doc and the Codex audit (and the draft itself) are **untracked** in git;
  commit them once reviewed.

---

## Part 3 — Concrete edit checklist for `docker_server_full_setup_2.0.md`

In doc order. (E = edit for correctness, R = rewrite to match reality, A = add missing content.)

1. **CONVENTIONS** (R): replace the `ENV` abstraction with per-server truth (N‑3):
   branch map per repo, `:staging` tags everywhere, `_DEV` volume-var names, what
   `RUN_ENV` actually controls, and a note that PROD naming is reserved for a future
   server. Add the `RUN_LOGS_DIR` format note (full `host:container` spec, consumed raw
   by compose).
2. **STEP 1** (E): keep the data-root block but mark the `/mnt/sdc` sanity check
   conditional; note Docker 29 containerd-store caveat; either write
   `docker-disk-migration.md` or drop the reference; prefer the deb822 install method.
3. **STEP 1.1** (E): fix `CREATE SERVICE ACCOUT USER` (make it a comment, fix typo);
   replace `source ~/.bashrc` with re-login/`newgrp docker`; add `matt-teixeira`
   creation (or generalize to "each admin user"); add `sudo usermod -aG docker svc`
   (live state depends on it — H‑1/RB‑5).
4. **STEP 2** (E): use `POSTGRES_PASSWORD_FILE`; replace "wait a few seconds" with a
   `pg_isready` loop; reorder 2.4 after the container exists; create only the database(s)
   the server actually uses (this box: `staging` only — no `dev` DB exists).
5. **STEP 3** (R): fix the Redis config story per N‑1 — correct mount paths to
   `./config/<env>.config` (or rename files to match compose), long-form volumes with
   `create_host_path: false`, post-start verification (`CONFIG GET appendonly` = `yes`),
   and decide/document `requirepass`. Note ports published and the NSG expectation.
6. **STEP 4/5** (R): rescope as "seeding a new dev/staging server" (RB‑7); add DBSIZE /
   row-count verification and the note that Redis must be stopped before the RDB swap
   (already present) plus *verify what Redis loads on start given AOF settings*.
7. **STEP 5.7** (A): note that this SQL block is a point-in-time changelog; future
   changes belong in versioned migration files.
8. **STEP 6.2** (A): replace "copy/paste of saved .env state" with the actual `.env` key
   list per app (names only) and where the secrets live.
9. **STEP 8 / run commands** (E): rewrite the two `npm ci` variants per H‑10: warm the
   cache once (`npm ci --omit=dev`), then normal runs are `npm run <job>` only — matching
   the live crontab. Update the `update_db_creds.sh` note per H‑9 (script self-cleans via
   tmpfs; the `rm -rf` targets the stray repo-local dir).
10. **SSL / Step 5 app config** (R): rewrite around real env keys and real `buildSsl()`
    behavior (N‑6, H‑3); switch the verification test to `verify-full`; correct the
    restart claim (reload suffices); make the `pg_hba.conf` edit verifiable
    (`pg_hba_file_rules`).
11. **PER-APP ENTRYPOINT matrix** (R): update to observed truth — hhm_rpp_ge ✅ tracked
    `docker/entrypoint.sh` (baked into shared `hhm_rpp:staging`); monday ✅ root
    `entrypoint.sh` + compose build → `monday:staging`; acumatica ⚠️ tracked but **unused**
    (runs stock node:lts as `1006:987` — decide: adopt the Dockerfile or delete it);
    reports ⚠️ tracked but compose runs `aux:staging` (align image names). Drop the stale
    "add one" action item.
12. **SHARED SSH BUNDLE** (R): document the *working* permission model (owner + group
    `docker`, `id_dev` 640 group-readable, why `chmod 600` breaks it), and add the
    provisioning step for a new server (where key/config/known_hosts come from,
    fingerprint verification).
13. **RPP sections** (E): remove the no-op `docker compose build` from Philips/Siemens;
    add the one real GE build step and ordering (RB‑3); remove the stale entrypoint
    warning; drop the redundant per-app `mkdir` lines or keep them and drop STEP 7's bulk
    list (one mechanism, not two).
14. **acumatica/monday/reports sections** (E): fix build commands/tags per N‑4.
15. **STEP 7** (E): add `acquisition-v2` and `odd-jobs` with status labels (N‑5).
16. **NEW — STEP 9: SCHEDULES** (A): paste the real crontab (or a cleaned manifest of
    it), state the owning user, the stagger design (:00/:30 HHM, :15/:45 RPP, :16/:46
    MMB, :25/:55 incident-engine), which apps have no schedule, and the acquisition-v2
    rollback note. Optionally add `flock -n` per job family. Retire `cron-jobs.txt`.
17. **NEW — backups & rotation** (A): minimal viable ops: nightly `pg_dump` + RDB copy
    off-host, rotation for `/opt/run-logs` **and** the dev-mode `utils/logger` dirs
    (N‑2), Docker log-driver rotation in `daemon.json`.
18. **Housekeeping** (A): archive/update the contradictory older docs (N‑7); commit this
    doc and the setup guide.

## Part 4 — Server-side fixes to consider (reality is wrong, not the doc)

Priority order:

1. **Redis config mounts** (N‑1) — silent misconfiguration of live prod state; fix and
   recreate containers during a quiet window.
2. **Log accumulation in repos** (N‑2) — >1 GB and growing in data_acquisition alone;
   add rotation/cleanup now, decide the canonical target later.
3. **Per-app Postgres roles** (H‑2) and **fail-closed TLS with `verify-full`** (H‑3) —
   the incident-engine role/TLS pattern is the template; roll it out app by app.
4. **Redis auth + stop publishing Redis ports** (RB‑8) — apps use `redis_net`; published
   ports appear unnecessary except for developer tooling (which the NSG should scope).
5. **acumatica_sync identity** (H‑15) — move off `1006:987` (a human uid) to `svc`,
   ideally by adopting its unused Dockerfile/entrypoint like its siblings.
6. **Backups** (H‑12) — nightly pg_dump + Redis RDB off-host.
7. **monday dead env var, /opt/resources legacy debris, stray Dockerfiles** (N‑7).
