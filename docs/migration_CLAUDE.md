
# CLAUDE.md

**mmb-rpp** is a Node.js data pipeline that monitors log files from MRI imaging equipment.
It incrementally reads new bytes, parses readings with per-vendor regex models, processes
them, and bulk-inserts to PostgreSQL. Run-once by design — triggered on a schedule, not a
long-running service.

> **How this file is organised**
>
> **Part 1 — Shared app architecture.** Conventions every app in the fleet uses: the Docker
> file pattern, the user/ownership model, the release workflow, the logger, the DB layer.
> Little here is mmb-rpp-specific; it should read the same in any sibling app
> (`alert-processor`, `reports`, `odd-jobs`, …). Change these in one app and consider
> syncing the others.
>
> **Part 2 — mmb-rpp specifics.** This app's domain: the READ→PARSE→PROCESS→PERSIST
> pipeline, EDU/MAG categories, Redis filesize tracking, target tables, equipment quirks,
> and day-to-day operations.
>
> **Part 3 — Migrating an app into this paradigm.** The reusable playbook for moving a
> sibling app onto the Part 1 pattern. Keep it until every app is migrated.
>
> **Part 4 — Remaining work.** The live to-do list for *this* migration. Transient — delete
> it first, once mmb-rpp is on PROD.
>
> No part references a later one, so they can be deleted from the bottom up without breaking
> what remains. When you delete a part, delete its bullet above too.

---

# PART 1 — SHARED APP ARCHITECTURE

*Fleet-wide conventions. Should read the same in any sibling app — keep them in sync.*

## Standardized Docker setup (5 files)

Every app uses the same file pattern.

**Dockerfile**

- Base image: `node:lts`
- Installs `gosu` for runtime user switching
- Creates the `docker` group plus the application users `svc` and `jonathan-pope`
- Uses the local `entrypoint.sh` at `/workspace/entrypoint.sh` (user switching via gosu)
- Build args: `USER_ID`, `DOCKER_GID`, `UID_0` (svc), `UID_1` (jonathan-pope)
- **Dependencies are NOT installed in the Dockerfile** — that is `build.sh`'s job, keeping the image
  cache-friendly and letting `node_modules` live on the bind-mounted host directory.

**entrypoint.sh**

- Switches to the user named by the `RUN_USER` environment variable; defaults to `svc`
- Uses `gosu` to exec the command as the target user
- Lives in the app root, bind-mounted to `/workspace/entrypoint.sh` in the container
- **Repairs the log directory while still root**, before `gosu` drops privileges. When a
  bind-mount source does not exist on the host, Docker creates it as `root:root`, which
  leaves the app unable to write — and it fails inside `createWriteStream`, *before* any
  logging exists to record why. The entrypoint `mkdir -p`s the directory and chowns it to
  `$RUN_USER:docker`, but **only when it is root-owned**, so a directory somebody
  deliberately chowned (e.g. `/opt/run-logs/<app>` as `svc:docker`) is left alone.

**docker-compose.yml**

- Image name `<app>:${USER_ID}` (USER_ID loaded from `.env`)
- User selected dynamically at runtime via `RUN_USER` (defaults to `svc`)
- `env_file: .env`
- The three standard volume mounts (below)
- Connects to the external `pg_net` network

**build.sh**

- Runs a single `npm install` at the project root. `utils/` has no `package.json` of its own
  and resolves up to the root `node_modules`, so it needs no install of its own
- Installs as the current host user (not root) so `node_modules` ownership matches the host
- Sources `.env` so the `USER_ID` build-arg matches the tag compose interpolates
- Builds the image, passing the dynamic UIDs/GID from the host

**build-release.sh**

- Deploys a release copy to `/opt/apps/<app>` and applies the `#RELEASE:` overrides
- **`#RELEASE:` convention:** `.env` lines prefixed `#RELEASE:KEY=VALUE` are release-copy
  overrides. The script operates on the *copied* `.env`: for each `#RELEASE:KEY=VALUE` it
  replaces the active `KEY=` line with VALUE, then strips all `#RELEASE:` markers. The dev
  tree keeps both lines as a single source of truth; the deployed `.env` ends up with clean
  release values.
- Current use: `USER_ID=jonathan-pope` in dev becomes `USER_ID=svc` in the release copy.
  Environment-specific values (`PG_*`, `REDIS_*`) get **no** `#RELEASE:` override — they are
  properties of the server, not the release.

**Clean-tree guard — why a release can refuse to run**

The script mirrors the **working tree** via tar-pipe, not a git ref. Releasing from a dirty
tree therefore puts code in `/opt/apps/<app>` that exists in no commit: unreproducible,
untraceable, with nothing to roll back to. A guard enforces this, and it sits **above** the
`rm -rf "$DEST"` step so a refusal can never leave a half-wiped release directory.

| Tree state | Behaviour |
| ---------- | --------- |
| Clean (matches `HEAD`) | Proceeds; prints `commit: <sha>` in the banner |
| **Dirty** — uncommitted *or untracked* files | **Refuses, exit 1.** Nothing copied, `$DEST` untouched |
| Clean but unpushed | Proceeds with a warning |

Dirty blocks because the release would be untraceable. Unpushed only warns — that release
*is* traceable locally, just not reproducible by anyone else. Relevant while `docker` has no
upstream.

```bash
bash build-release.sh                  # normal: refuses if dirty
bash build-release.sh --allow-dirty    # emergency override (ALLOW_DIRTY=1 also works)
```

If it refuses, commit or stash first — do not reach for `--allow-dirty` out of habit. The
whole point is that `/opt/apps/<app>` should always correspond to a commit.

**Release provenance — `RELEASE_SHA`**

The release banner alone is not a record; it scrolls away. So `build-release.sh` also stamps
the released commit into the **deployed** `.env`:

```
# Injected by build-release.sh — do not edit by hand.
RELEASE_SHA=a9f7f8b
```

`index.js` reads it into the boot `env_note`, which means **every run log and every
`util.app_run_logs` row identifies the commit that produced that data.** Never set it by hand
in a dev tree — it is absent there, and `index.js` logs `dev-tree` instead (`|| 'dev-tree'`,
so dev runs don't reintroduce an `undefined` in that log line).

The stamping step is idempotent, so repeated releases replace the line rather than stacking.

Ask which commit produced a run — or what production has been running:

```sql
-- what code produced recent runs?
SELECT (verbose_log -> 0 -> 'note' ->> 'RELEASE_SHA') AS release_sha,
       (verbose_log -> 0 -> 'note' ->> 'schedule')    AS run_group,
       COUNT(*) AS runs, MIN(inserted_at) AS first_seen, MAX(inserted_at) AS last_seen
FROM util.app_run_logs
WHERE app_name = 'mmb-rpp'
GROUP BY 1, 2 ORDER BY 4 DESC;
```

Rows showing `dev-tree` came from someone's working tree, not a release. That is expected for
dev testing, but a `dev-tree` row appearing on a schedule means cron is running the wrong copy.

> Still not recorded: the image label. `LABEL version="${USER_ID}"` in the Dockerfile stores
> *identity* (`svc`), not a version, so `docker inspect` cannot identify a stray container's
> code. A `git_commit` label would close that; `RELEASE_SHA` covers the runtime case, which is
> the one that matters for tracing data.


## Standard volume mounts

| Mount                                       | Purpose                                            | Mode |
| ------------------------------------------- | -------------------------------------------------- | ---- |
| `./:/workspace`                             | Live source code (includes entrypoint.sh)          | rw   |
| `${LOG_DIR}:/workspace/utils/logger/logs`   | Log output — **path depends on environment**        | rw   |
| `/opt/resources:/opt/resources:ro`          | Read-only data: source log files, SSL certs, etc.  | ro   |

**The log mount is environment-dependent**, so dev noise never lands in the production
record:

| Environment | `LOG_DIR` | Result |
| ----------- | --------- | ------ |
| Dev tree | `./utils/logger/logs` | logs stay in the project (gitignored) |
| Release copy | `/opt/run-logs/<app>` (via `#RELEASE:LOG_DIR`) | `svc`-owned production history |

`/opt/run-logs/<app>` therefore holds **only** scheduled/production runs. A non-`svc`-owned
file appearing there means someone ran a dev command against the release copy. Compose
defaults to the dev path (`${LOG_DIR:-./utils/logger/logs}`), so a missing `LOG_DIR` fails
safe rather than writing into production.


## Host prerequisites (before the first run)

```bash
# 1. Production log directory — create and chown BEFORE the first release run.
#    entrypoint.sh only repairs a root-owned directory; it deliberately will not
#    re-chown one you set deliberately, so set this one correctly up front.
sudo mkdir -p /opt/run-logs/<app>
sudo chown svc:docker /opt/run-logs/<app>
sudo chmod 2775 /opt/run-logs/<app>      # setgid keeps group=docker on new files

# 2. Shared resources present under /opt/resources/
#    (whatever the app reads: ssl/pg_ssl.crt if using SSL, source data dirs, etc.)

# 3. .env populated (USER_ID is mandatory — it drives the image tag)

# 4. REDIS_PW copied from the root-only host secret, where Redis sets requirepass:
#    sudo cat /opt/resources/secrets/redis_auth.conf
```

The **dev** log directory needs no prep — `entrypoint.sh` creates and chowns it on first run
(and `log.js` `mkdirSync`s it for non-Docker runs). It is gitignored, so a fresh clone starts
without it by design.

The external `pg_net` network is persistent once created and does not require a pre-run check or
recreation step. (mmb-rpp additionally requires the external `redis-admin_redis_net`.)


## Running

```bash
# Development — from the dev tree, as yourself (UID matches host file permissions)
RUN_USER=<you> docker compose run --rm <app> node index.js <arg>

# Production — from the release copy, RUN_USER omitted so entrypoint.sh defaults to svc
cd /opt/apps/<app> && docker compose run --rm <app> node index.js <arg>
```

All apps are **run-once** (not long-running services), designed to be triggered on a schedule
via host cron or a systemd timer.

Two habits worth keeping:

- **Run dev commands from the dev tree, production from `/opt/apps/<app>`.** They are separate
  copies with separate `.env` files; running a dev command inside the release copy writes dev
  output into the production log directory and reports the wrong `USER_ID`.
- **Omit `RUN_USER` in production** rather than setting it to `svc` explicitly, so there is one
  place that decides the production identity (`entrypoint.sh`).

See Part 2 for this app's schedule argument.


## The svc account, and the HOME trap

`svc` is a **system account with no host home directory**:

```
svc:x:105:106::/nonexistent:/usr/sbin/nologin
```

That surprises people, because `/home/svc` *does* exist **inside** the image — the Dockerfile
creates it with `useradd -m`. So the same username has a home directory in one context and not
the other. There are three distinct `HOME`s in play, and conflating them causes real failures:

| Context | `HOME` | Notes |
| ------- | ------ | ----- |
| Inside the container | `/home/svc` | `entrypoint.sh` sets `HOME=/home/$RUN_USER`; the dir exists in the image. Correct as-is. |
| Host — cron | unset → `/nonexistent` | Fine. The docker CLI tolerates a nonexistent `HOME` (verified: `docker compose version` exits 0). |
| Host — `build-release.sh` | `/tmp` (explicit) | Works, but is the sole reason `/tmp/.docker` exists, owned `svc:svc` mode `700`. |

**Do not "fix" a missing `HOME` by pointing it at `/tmp`.** It looks harmless and is the
obvious reflex, but `/tmp` is shared: the resulting `/tmp/.docker` is unreadable by every other
user, so the same command run by a human then fails with

```
WARNING: Error loading config file: open /tmp/.docker/config.json: permission denied
docker: unknown command: docker compose
```

— which reads like a broken docker install rather than a permissions problem. Leave `HOME`
alone unless something actually needs it, and if a tool does need a writable home, give it a
private directory rather than `/tmp`.

`/usr/sbin/nologin` is not a problem for cron: cron uses `SHELL` from the crontab (or `/bin/sh`),
not the account's login shell.

> **Known wart:** `build-release.sh` sets `HOME=/tmp` where it probably does not need to, since
> the docker CLI works without it and npm caching happens inside a container
> (`NPM_CONFIG_CACHE`), not on the host. Untested to remove — it needs a release run to verify,
> so it is left as-is deliberately rather than changed blind.


## Scheduling: cron jobs under svc

Every app is **run-once**, so production means a schedule. All apps share `svc`'s crontab:

```bash
sudo crontab -u svc -e    # edit — this is the source of truth
sudo crontab -u svc -l    # list every app's schedule in one place
```

**Edit with `-e`, never install from a file.** `crontab -u svc <file>` *replaces* the entire
crontab, so it would wipe every other app's entries. `-e` opens the existing content, which is
what makes a shared crontab safe for several people to maintain.

The shared crontab is deliberate, not incidental: `-l` shows every app's cadence together,
which is the only convenient way to reason about apps that are prerequisites of other apps.
The schedule is **host configuration, not app code** — it lives here, not in any app repo, so
changing a cadence needs no release. Individual apps document their own entries (see Part 4
for mmb-rpp's) but the crontab is what actually runs.

**Organised by cadence, not by app.** Two sections — `1. DAILY OR MORE FREQUENT` and
`2. LESS THAN DAILY` — with entries in **chronological** order inside each: sub-daily jobs by
their minute within the hour, infrequent jobs by day and time. Reading top to bottom therefore
tells you what runs next, which is the question you actually have when looking at this file.

An app with jobs at different frequencies appears in **both** sections, with its name as a
`-----` subheading. That is intentional: what matters here is what is about to run, not who owns
it. It also means the old "one section per app" rule does not survive an app growing a second
job at a different cadence — which is exactly what happened to odd-jobs.

There is **no `PATH=` or `SHELL=` line** in the crontab, so cron's built-in default (typically
`/usr/bin:/bin`) applies. Bare `docker` works because of that; entries use absolute
`/usr/bin/docker` and `/usr/bin/flock` anyway so nothing depends on it, and so no app can
silently break the others by adding or retuning a shared `PATH=` later.

Two known weaknesses of this approach, both cheap to live with at 2–3 maintainers:

- **No version history** — no record of who changed what. Snapshot it if you want a diffable
  record: `sudo crontab -u svc -l > /opt/resources/cron/svc.crontab.bak`
- **Concurrent edits lose silently** — if two people run `-e` at once, the last save wins with
  no warning. Coordinate before editing.

Rules that apply to every entry:

- **Run from the release copy, never the dev tree.** `cd /opt/apps/<app> && ...`. A dev tree has
  a different `.env` (`USER_ID`, `LOG_DIR`) and writes into the wrong log directory. A
  `RELEASE_SHA` of `dev-tree` in `app_run_logs` is the symptom.
- **Omit `RUN_USER`.** `entrypoint.sh` defaults to `svc`; one place decides the identity.
- **Do not set `HOME`.** See *The svc account, and the HOME trap* above.
- **Use absolute paths.** cron's `PATH` is minimal (typically `/usr/bin:/bin`). There is a
  `PATH=` line at the top of the crontab, but note it is **shared by every app's entries** —
  as are `SHELL=` and any other variable set there. Don't retune them for one app; call
  `/usr/bin/docker` and `/usr/bin/flock` explicitly instead.
- **Wrap in `flock -n` if overlap can corrupt state.** `-n` skips the tick rather than queueing.
  Any app that advances a cursor *after* doing work (as the Redis filesize pattern does) will
  double-process if two runs overlap.
- **Capture output to a bounded file, not `/dev/null`.** Both log sinks already record a run —
  but only *once node starts*. A failure before that (bad image, missing network, dead daemon,
  wrong path) produces no log anywhere. Redirect to `<something>.out` with a single `>` so each
  file holds the last invocation and cannot grow without bound.
- **Stagger entries.** Container startup is a few seconds; don't line up eight of them on the
  same minute.

Verify a schedule is actually running from the database rather than from cron's own logs, since
`app_run_logs` proves the app *ran*, not merely that cron fired:

```sql
SELECT (verbose_log -> 0 -> 'note' ->> 'RELEASE_SHA') AS release_sha,
       COUNT(*) AS runs, MAX(inserted_at) AS last_run
FROM util.app_run_logs
WHERE app_name = '<app>' AND inserted_at > now() - interval '2 hours'
GROUP BY 1;
```


## Logging (`utils/logger/`)

- `makeAppRunLog()` — creates a `run_log` with a UUID and opens the file stream
- `addLogEvent(type, run_log, func, tag, note, err)` — queues a structured event in memory
- `writeLogEvents()` — flushes the JSON log to `utils/logger/logs/` inside the container. On the
  host that path is whatever `LOG_DIR` points at: the project tree in dev,
  `/opt/run-logs/<app_name>` for a release (see *Standard volume mounts*)
- `dbInsertLogEvents()` — persists the full verbose log plus a warn/error subset to `app_run_logs`
- **Always call `writeLogEvents()` and `dbInsertLogEvents()` before the job finishes.**
- Event types: `I` (INFO), `W` (WARN), `E` (ERROR)
- Event tags: `cal` (CALL), `det` (DETAILS/DETECTION), `cat` (CATCH), `seq` (SEQUENCE HALTED), `qaf` (QA FAILURE)
- `LOGGER_MODE=log` → file only; `LOGGER_MODE=log_and_console` → file + console
  (console output is limited to error stacks plus first/last event stats)
- Express/HTTP apps skip local file logging and write to the database only
- **Keep the logger identical across apps** — it is shared behaviour, not app-specific.
  Read a run by opening the log file rather than changing what the logger prints:
  ```bash
  # dev
  cat ./utils/logger/logs/<app>-log.<USER_ID>.<run_id>.js | python3 -m json.tool | less
  # release
  cat /opt/run-logs/<app>/<app>-log.svc.<run_id>.js | python3 -m json.tool | less
  ```
- **Never open a run log in an editor.** The files hold JSON but are named `.js`, so an editor
  with format-on-save rewrites them into JS literal notation — unquoted keys, single quotes —
  and they stop parsing as JSON. It is silent and it edits the production record. Two of four
  cron logs were rewritten this way before anyone noticed. Read them with `cat`, as above.
- `makeAppRunLog()` also `mkdirSync`s the log directory. That covers non-Docker runs; it
  **cannot** fix the Docker case, because a bind mount always exists by then (root-owned if
  Docker created it) — that is `entrypoint.sh`'s job.
- A killed run still produces both sinks thanks to the `gracefulShutdown` handlers in
  `index.js` (SIGTERM/SIGINT flush both sinks, disconnect redis, then exit).


## Database (`utils/db/`)

- `pg-pool.js` — pg-promise connection pool
- `sql/sql.js` — `QueryFile` references, organized by application
- `sql/pg-helpers.js` — `TableName` + `ColumnSet` definitions for bulk inserts across schemas
- Bulk inserts use `pgp.helpers.insert(data, pg_column_sets.<...>)`
- **SSL is ENABLED** in `pg-pool.js`: `require: true`, `rejectUnauthorized: true`, with the CA
  read from `PG_SSL_PATH`. On this server that is the self-signed cert for the local container
  at `/opt/resources/ssl/pg_ssl.crt`. The path must resolve or `pg-pool.js` throws at
  require-time — before any logging exists to record why.


## Environment variables

`USER_ID`, `APP_NAME`, `LOGGER_MODE`, `LOG_DIR`, `PG_HOST`, `PG_PORT`, `PG_DB`, `PG_USER`,
`PG_PW`, `PG_SSL_PATH`; runtime-only: `RUN_USER`. Individual apps add their own on top.

A template lives in **`.env.example`** — `.env` itself is gitignored, so that file is the
tracked record of what a new deployment needs.

`USER_ID` does triple duty: image tag (`<app>:${USER_ID}`), log-file tag
(`<app>-log.${USER_ID}.<run_id>.js`), and boot-log label.

Two keys carry a `#RELEASE:` override — the only things that should differ between a dev tree
and a release, since everything else describes the *server*, not the release:

| Key | Dev | Release |
| --- | --- | ------- |
| `USER_ID` | your username | `svc` |
| `LOG_DIR` | `./utils/logger/logs` | `/opt/run-logs/<app>` |

`RELEASE_SHA` is **injected by `build-release.sh`** into the deployed `.env`, never set by
hand — it records which commit a release came from. See *Release provenance* above.


## Secrets

Credentials that are properties of the host, not the app, live in root-only files under
`/opt/resources/secrets/` and are copied into each app's `.env`. Retrieve them with `sudo`;
they are deliberately unreadable by the app user.

A **rotation script** rewrites the relevant `.env` key for the apps listed inside it when a
secret rotates. As of 2026-08-21 that is
`/opt/resources/scripts/rotate-envs-20260817.sh`, owned by `matt-teixeira` and readable only by
him. It is **not scheduled** — no `svc` crontab entry, no `/etc/cron.d` entry, no systemd timer —
so rotation is a deliberate act by its owner, not standing automation, and "registered" means
*your app's `.env` paths appear inside that file*. Ask its owner to add them; there is no
self-service registry.

Two consequences worth knowing:

- **Both copies need listing.** `PG_*` and `REDIS_*` carry no `#RELEASE:` override, so the dev
  tree's `.env` and `/opt/apps/<app>/.env` hold the same value and both go stale. A rewrite of
  only one leaves the other broken until the next release.
- **A sudden auth failure across several apps** usually means a rotation happened and this app
  was not listed, rather than a code change. An *unlisted* app fails silently and indefinitely:
  odd-jobs sat on a rotated `PG_PW` for three weeks, its runs writing file logs and reporting
  success while every database call failed authentication.


## Termination convention

Functions **halt by returning, never by throwing** — no exceptions propagate up the stack, so a
job fails gracefully instead of aborting the run. Every early return logs an `addLogEvent`
first, so a halt is always visible in the run log.

The *return shape* is per-app and does not need to match: mmb-rpp's pipeline functions return
**`null`** to halt, while odd-jobs' jobs return a **boolean** `job_status` that `index.js` turns
into a closing INFO or WARN event. Either satisfies the convention; what matters is that nothing
throws past the job boundary and that every halt is logged.

A run that processes many configs therefore keeps going when one of them cannot proceed: one
bad config produces a WARN or ERROR and the rest still complete. Expect a non-zero
warning count on a healthy run, and judge health by *which* warnings appear rather than
whether any did.

---

# PART 2 — MMB-RPP SPECIFICS

*This app's domain logic and operations. Everything below is particular to mmb-rpp.*

## Pipeline: READ → PARSE → PROCESS → PERSIST

1. **READ** (`read/`) — tracks filesize deltas in Redis; `tail -c<delta>` reads only new bytes;
   **halts if filesize hasn't grown**.
    - `exec-check-filesize.js`, `get-filesize-delta.js`, `exec-tail.js`
2. **PARSE** (`parse/`) — extracts `[START CAPTURE BLOCK]…[END CAPTURE BLOCK]`, applies regex models.
    - `parse-capture-blocks.js`, `parse-readings.js`; models in `parse/_helpers/regex-models.js`
3. **PROCESS** (`process/`) — MAG only; normalizes rows, builds datetime objects. EDU skips this.
    - `process-rows.js`, `generate-dt-object.js`
4. **PERSIST** — bulk insert; updates Redis filesize only **after** a successful insert.
    - Tables: `mmb_ge_mm3`, `mmb_ge_mm4`, `mmb_siemens`, `mmb_siemens_non_tim`, `mmb_edu2`, `edu.v1`, `edu.v3`


## Data categories

- **EDU** — education/training systems: direct insert, no processing
- **MAG** — magnetic/MRI systems: requires processing before insert


## Schedule argument

- **Dev:** device ID — `SME01096`, `SME21933`, `RTT12345`
- **Prod/Staging:** run group number `0`–`7`

```bash
RUN_USER=jonathan-pope docker compose run --rm mmb-rpp node index.js SME01096   # dev device
RUN_USER=jonathan-pope docker compose run --rm mmb-rpp node index.js 0          # prod run group
```


## Redis

- Dual-connection pattern: `host: process.env.REDIS_HOST || process.env.REDIS_IP`
  (Docker uses `REDIS_HOST` container name; legacy falls back to `REDIS_IP`).
- **Requires the extra external network `redis-admin_redis_net`** (in addition to `pg_net`).
- Key/value: key `${sme}.${file_name}.log` (e.g. `SME01096.v2_edu2.log`), value = filesize in bytes.
- Extra env: `REDIS_HOST`, `REDIS_IP`, `REDIS_PORT`, `REDIS_PW`.
- **Auth:** staging/prod set `requirepass` on the default user, so `REDIS_PW` alone is
  enough — no ACL username. `index.js` passes it as `password` at the **top level** of the
  `createClient` config, *not* inside `socket` (node-redis 4.x). It is spread conditionally,
  so a non-auth instance still connects with `REDIS_PW` unset.
- Password source: root-only `/opt/resources/secrets/redis_auth.conf` on the host, synced
  into each registered app's `.env` by the host rotation script.
- Debug (auth required):
  ```bash
  docker exec -it <redis_container> redis-cli -a "$REDIS_PW" --no-auth-warning
  > GET SME01096.v2_edu2.log
  > KEYS SME01096.*
  ```


## mmb-rpp environment variables

On top of the shared keys (Part 1), mmb-rpp requires `REDIS_HOST`, `REDIS_PORT`, and
`REDIS_PW` — see *Redis* above. Everything else follows the fleet conventions.


## File paths

- Source logs (read-only mount): `/opt/resources/acqu_files/${SME_ID}.${file_name}.log`
  — a **flat** path. Note the mount also holds per-system *directories*
  (`SME09713/host_logfiles/...`) that are a different dataset this pipeline does not read.
- App logs: `${LOG_DIR}/${APP_NAME}-log.${USER_ID}.${run_id}.js` — i.e.
  `./utils/logger/logs/...` in dev, `/opt/run-logs/mmb-rpp/...` for a release


## Equipment quirks

Some equipment reports different fields, units, or granularity than its siblings. Handled via
multiple regex profiles rather than one permissive pattern — GE MM3 has profiles A–F plus a
UNIFIED pattern, and a device's `regex_models` config array selects which apply.

Known per-device quirks (previously tracked in `dev-notes.txt`, folded in here when that file
was removed — the devices below still have live configs):

- **Analog `Signal Name` / `Units` differ at row 18.** These three report
  `'Spare Cmp 1a' : 'Volts?'` where all other systems report `'SC Pressure' : 'Mpa'`:
  - `SME01134` (GE Signa Excite)
  - `SME01882` (GE Signa Excite)
  - `SME02582` (Signa Excite)
- **Carries minute-level data and lacks `HE Level` in COLDHEAD:**
  - `SME01134`, `SME01882`, `SME02582` (as above), plus `SME02483` (GE Echospeed)

`SME02483` (GE Echospeed) was flagged as an open caveat in the original notes with no detail
recorded — treat it as suspect if its rows look wrong.

**Siemens cluster dropping most of its capture blocks (found 2026-08-21, UNRESOLVED).**
`SME13604`, `SME13605`, `SME13606`, `SME13607` and `SME11246` each skip ~30 capture blocks per
run while inserting only ~2 rows — together roughly 75% of all `qaMatches 0 MATCHES` warnings
across the whole fleet. The other ~130 devices insert cleanly, so this is a regex-profile
mismatch on one cluster rather than a pipeline fault, but those five are effectively not being
captured. The four consecutive `SME1360x` IDs suggest a single site or model revision.

To investigate: `tail` one of their source files, compare a capture block against the
`regex_models` its config lists, and check whether a different Siemens profile matches. Note
their source files contain NUL and form-feed bytes between captures. Those survive into the
log JSON and break PostgreSQL's `->>` extraction outright (*"unsupported Unicode escape
sequence: \\u0000 cannot be converted to text"*), so read those run logs from the file with
Python rather than querying `util.app_run_logs`.


## Pre-flight check

```bash
# Automated environment validation
bash preflight-check.sh
```

This script validates:
- **Host directories**: whatever `LOG_DIR` points at (writable), `/opt/resources/acqu_files/`
  (exists) — it reads `LOG_DIR` from `.env` rather than assuming `/opt`, so it checks the
  directory the run will actually use
- **Docker**: daemon running, user in docker group, compose available
- **Networks**: `pg_net` and `redis-admin_redis_net` exist
- **Configuration**: `.env` has all required variables (including `REDIS_PW`)
- **Application files**: `index.js`, `Dockerfile`, `entrypoint.sh`, utils/ structure
- **Dependencies**: root `node_modules` present (an unexpected `utils/node_modules` warns,
  since it would shadow the root install)
- **External services**: both PostgreSQL and Redis reachable **and authenticating** — a real
  authenticated `PING` for Redis, and for Postgres a real SSL connection with credentials
  from a **sibling container** on `pg_net`. Container-on-network presence is reported too,
  but proves nothing about credentials.

  > The Postgres check must not use `docker exec <pg_container> psql`. `pg_hba.conf` trusts
  > `local` and `127.0.0.1/32`, so that path succeeds with a deliberately **wrong** password.
  > A rotated `PG_PW` hid for three weeks behind a check built that way. Connecting from a
  > sibling container forces the `hostssl … scram-sha-256` rule the app itself uses.
  > Requires the `postgres:16` image locally (already present as `pg_db`'s own image); if it
  > is missing the check **warns** rather than passing, since an unverified check must never
  > look like a passing one.

Exit codes:
- `0` = All checks passed (or warnings only)
- `1` = Critical errors found

A clean run should report **zero warnings**. Treat a persistent warning as a bug in the check
itself and fix it — a check that always warns trains people to ignore its output, which is
exactly how a real Redis `NOAUTH` failure once hid behind a green result.


## Quick Reference: Common Operations

### Daily Operations
```bash
# Run pre-flight check
bash preflight-check.sh

# Build/rebuild image (after code changes or dependency updates)
bash build.sh

# Run single device (dev/testing) — from the dev tree
RUN_USER=<user> docker compose run --rm mmb-rpp node index.js SME01096

# Run production group — from the RELEASE copy, defaults to svc
cd /opt/apps/mmb-rpp && docker compose run --rm mmb-rpp node index.js 0

# Check recent logs — dev
ls -lt ./utils/logger/logs/ | head -5

# Check recent logs — production
ls -lt /opt/run-logs/mmb-rpp/ | head -5

# View formatted log (either path)
cat <log-file>.js | python3 -m json.tool | less
```

### Debugging Redis
```bash
# Load creds, then connect (staging/prod require auth)
set -a; . ./.env; set +a
docker exec -it -e RPW="$REDIS_PW" "$REDIS_HOST" redis-cli -a "$RPW" --no-auth-warning

# Check filesize for device
GET SME01096.v2_edu2.log

# List all keys for device
KEYS SME01096.*

# Delete key (reset filesize — next run reprocesses from 0, watch the 400k guard)
DEL SME01096.v2_edu2.log
```

### Debugging Database
```bash
# Connect to PostgreSQL container (PG_DB is 'staging' here, not 'dev')
docker exec -it pg_db psql -U postgres -d staging

# Check recent runs — note the column is inserted_at, not created_at
SELECT app_name, run_id, inserted_at,
       json_array_length(verbose_log)     AS events,
       json_array_length(warn_error_logs) AS warns_errors
FROM util.app_run_logs
WHERE app_name = 'mmb-rpp'
ORDER BY inserted_at DESC LIMIT 5;

# Check data inserts
SELECT COUNT(*) FROM mag.ge_mm3 WHERE system_id = 'SME01096';
SELECT * FROM edu.v2 WHERE system_id = 'SME01096' ORDER BY capture_datetime DESC LIMIT 10;
```

### Pre-run triage: which configs will actually process?

Roughly half the configs on staging have no source file, so a run's warning count is
expected to be non-zero. To predict a run before making it, compare each config's
on-disk filesize against its Redis value: `delta <= 0` halts (not grown), `delta > 400_000`
halts (guard), and anything between processes. This is how the group-0 run was predicted
exactly (37 process / 7 missing file / 1 guard).


### Inspect and rebuild
```bash
# Check Docker networks
docker network inspect pg_net
docker network inspect redis-admin_redis_net

# Check running containers
docker ps | grep -E "(mmb-rpp|pg_db|redis)"

# Rebuild from scratch
docker compose down
bash build.sh
RUN_USER=<user> docker compose run --rm mmb-rpp node index.js SME01136
```

For symptoms and fixes, see **Troubleshooting** below.

---

## Troubleshooting

- **`EACCES` writing a log:** the log directory is root-owned and `entrypoint.sh` could not
  repair it. Check `ls -ld $LOG_DIR` and chown to `<user>:docker`
- **File not found (`stat: cannot statx ...`):** the config references a source file that is
  not on this host. `ls -la /opt/resources/acqu_files/ | grep <SME>`. The job logs an ERROR and
  halts gracefully; it does not abort the run
- **Redis connection:** `docker ps | grep redis`; `docker network inspect redis-admin_redis_net`
- **Redis `NOAUTH`/`WRONGPASS`:** `REDIS_PW` missing or stale in `.env` — see the Redis section
- **PostgreSQL connection:** `docker ps | grep pg_db`; `docker network inspect pg_net`
- **`no partition of relation ... found for row`:** the target table's newest monthly partition
  has lapsed. Applies to `util.app_run_logs` and ~24 other partitioned tables. **This is not a
  fault in your app** — those partitions are provisioned by **odd-jobs' `pg-part-arch`**, which
  runs monthly and creates the following month. If you hit this, that job failed or has not run;
  fix it there rather than working around it locally
- **Release refuses to build:** the working tree is dirty — see *Clean-tree guard*

### Common fixes

Run `bash preflight-check.sh` first; it diagnoses most of these.

**Log directory permission errors:**
```bash
# Production log dir (must be svc-owned; entrypoint.sh will not re-chown a deliberate owner)
sudo chown -R svc:docker /opt/run-logs/mmb-rpp && sudo chmod 2775 /opt/run-logs/mmb-rpp

# Dev log dir — normally self-healed by entrypoint.sh; only needed if it was chowned
# to someone other than you
sudo chown -R $USER:docker ./utils/logger/logs && sudo chmod 2775 ./utils/logger/logs
```

**Missing Docker networks:**
```bash
# PostgreSQL network (required)
docker network create pg_net

# Redis network (required for mmb-rpp)
docker network create redis-admin_redis_net
# Note: Typically created by redis-admin service
```

**Redis `NOAUTH` / `WRONGPASS`:**
```bash
# Staging/prod Redis sets requirepass. The password lives in a root-only host secret:
sudo cat /opt/resources/secrets/redis_auth.conf
# Copy the value into .env as REDIS_PW=<value>

# Verify without exposing it:
bash preflight-check.sh   # look for "Redis auth OK (PING -> PONG)"
```
The host rotation script rewrites each registered app's `.env` when the password
rotates — mmb-rpp is registered under the key `REDIS_PW`.

**Missing dependencies:**
```bash
# Installs at the root only — utils/ resolves up to the root node_modules
bash build.sh
```

**External service not found:**
```bash
# Check if services are running
docker ps | grep -E "(pg_db|redis)"

# Inspect network connectivity
docker network inspect pg_net
docker network inspect redis-admin_redis_net
```

---

# PART 3 — MIGRATING AN APP INTO THIS PARADIGM

*Reusable playbook. Keep this as long as sibling apps still need migrating
(`alert-processor`, `alert-notify`, `reports`, `odd-jobs`, `aws-ff`, …). It describes the
**structural** work of moving an app onto the pattern in Part 1, and deliberately records no
per-migration status — that belongs in a transient section, not here.*

## Aligning an existing app to this paradigm

Walk the app against this list. Every item is a misalignment actually hit while migrating
mmb-rpp or odd-jobs — none is hypothetical. Part 1 explains the *why* for each; this is the
*what to check*. **Read "Known dependencies" first**: most of the list is order-independent,
but a few edges are not, and they are cheaper to read than to rediscover.

> **Handing this to another app?** `MIGRATION-HANDOFF.md` in this repo root holds a
> paste-ready opening prompt for a Claude session in the app being migrated. Attach this
> CLAUDE.md alongside it (or point at this repo's `docker` branch). It is kept as a separate
> file on purpose: CLAUDE.md is auto-loaded into every session working on **this** app, and
> instructions addressed to a *different* app's agent do not belong in that context.

### Known dependencies

Most items below are independent and can be done in whatever order suits the app. These
edges are not: they are **app-independent**, they recurred on the second migration, and
getting them backwards costs a debugging session rather than a re-edit. Do these in order,
and keep the ones marked ONE COMMIT atomic.

1. **`entrypoint.sh`'s log-dir repair BEFORE the `LOG_DIR` flip.** Docker creates a missing
   bind-mount source as `root:root`, and a root-owned `utils/logger/logs` may already be
   sitting in the tree from an earlier era. Either way the first dev run after the flip dies
   `EACCES` inside `createWriteStream` — before any logging exists to record why. odd-jobs
   had exactly that directory, dated a month before the flip, so this fired for real.

2. **`LOG_DIR` + `#RELEASE:LOG_DIR` + the `./utils/logger/logs` tar exclude — ONE COMMIT.**
   Dev log files are named `*.js`, so `build-release.sh`'s `*.log` exclude does not catch
   them; split the commit and the first dev run's logs ship into the release. Verify by
   diffing `tar -tf` listings with and without the exclude, not by reading the pattern.

3. **The clean-tree guard before any further release.** Two orderings, both required: inside
   the script it must sit above the `rm -rf "$DEST"` so a refusal cannot leave a half-wiped
   release directory, and chronologically it must precede the next release — every release
   cut before the guard exists is one that could have shipped uncommitted code.

4. **The `RELEASE_SHA` stamp + the `index.js` boot `env_note` — ONE COMMIT.** Neither half
   does anything alone: the stamp writes a key nothing reads, the `env_note` logs
   `undefined` on every run.

5. **`.env.example` before, or with, the first new required key.** `.env` is gitignored, so a
   key added without it is recorded nowhere in git — `LOG_DIR` was the first. A release built
   from a fresh clone then silently inherits compose's dev-path default instead.

6. **A `preflight-check.sh` credential check + the client code that sends it — ONE COMMIT.**
   Requiring the key first makes preflight demand something nothing reads; adding the client
   field first leaves the credential unverified. Note the useful sequence odd-jobs landed on:
   preflight first PINGed *unauthenticated*, matching what the client actually did, which is
   what exposed that Redis had been rejecting every command; the check flipped to
   authenticated in the same commit as the client fix.

7. **The app's own `CLAUDE.md` gets a mid-migration note FIRST, and is corrected as each
   step lands — not at the end.** It is auto-loaded as project instructions, so until it is
   marked, every step is judged against a document describing the app as it was before the
   migration started. See *The app's own CLAUDE.md is not the authority* below.

### Files

| File | Must be true | Why it bites |
| ---- | ------------ | ------------ |
| `Dockerfile` | Build arg is **`USER_ID`**, not `VERSION`. `LABEL version="${USER_ID}"`. Installs `gosu`. Creates `docker` group + `svc` and per-dev users with `-m`. | An app still on `VERSION` builds an untagged image and compose interpolation silently yields `app:`. |
| `Dockerfile` | **No `COPY`/`ADD`.** Deps are `build.sh`'s job; source arrives via bind mount. | With no COPY, BuildKit transfers 2 bytes of context and `.dockerignore` is unnecessary. **If you add a COPY, add a `.dockerignore` in the same commit** or you bake in host-built `node_modules` and `.env`. |
| `entrypoint.sh` | Defaults `RUN_USER` to `svc`; `exec gosu`. Repairs the log dir **while still root**, but only when it is root-owned. | Docker creates a missing bind-mount source as `root:root`, so the app dies `EACCES` inside `createWriteStream` — before any logging exists to say why. |
| `docker-compose.yml` | `image: <app>:${USER_ID}`; log mount is `${LOG_DIR:-./utils/logger/logs}`; `env_file: .env`; external networks declared. | A hardcoded `/opt/run-logs/<app>` mount puts dev runs into the production log record. |
| `build.sh` | **One** `npm install` at the root. Sources `.env` so the `USER_ID` build-arg matches the tag. Runs as the host user. | A second install in `utils/` is a no-op (no `package.json` there) that walks up and reinstalls the root. |
| `build-release.sh` | Exists. Has the **clean-tree guard** above the `rm -rf "$DEST"`. Stamps `RELEASE_SHA` into the deployed `.env`. Excludes `./utils/logger/logs` from the mirror. | It mirrors the *working tree*, not a git ref — a dirty release is untraceable. Dev log files end in `.js`, so a `*.log` exclude does not catch them. |
| `.env` | `USER_ID`, `LOGGER_MODE`, `LOG_DIR` + `#RELEASE:` overrides for `USER_ID` and `LOG_DIR`. No `#RELEASE:` on `PG_*`/`REDIS_*` — those describe the server. | |
| `.env.example` | **Tracked.** `.env` is gitignored, so without it a fresh clone has no record of required keys. | |
| `index.js` (or entry) | Boot `env_note` logs `USER_ID`, `LOGGER_MODE`, `RELEASE_SHA` (defaulting to `dev-tree` when unset). `SIGTERM`/`SIGINT` handlers flush both log sinks before exit. | Without the handlers a killed run leaves a 0-byte log and no `app_run_logs` row — zero diagnostics exactly when you need them. Logging vars that no longer exist records `undefined` every run. |
| `utils/logger/log.js` | Filename uses `${USER_ID}`; mode check is `LOGGER_MODE`; `mkdirSync` before `createWriteStream`. | Keep this file **identical across apps** — it is shared behaviour. Sync changes rather than forking. |
| `CLAUDE.md` (the app's own) | Carries a mid-migration note pointing at the reference for conventions, and each section is corrected as its step lands. Any rival migration checklist deleted in favour of Part 3. | It is auto-loaded as **project instructions**, so a stale copy outranks this file in the session that is supposed to be fixing it. It will document defects as standards — a hardcoded production log mount, a no-op `npm install`, "4 files" instead of five. |
| `preflight-check.sh` | Validates whatever `LOG_DIR` points at, not a hardcoded path. **Real authenticated connections for every service the app uses — Postgres as well as Redis** — not container-on-network checks. Root `node_modules` missing is an **error**. | A container-presence check reported green while every Redis command failed `NOAUTH`. The same gap on the Postgres side hid a rotated `PG_PW` for three weeks: preflight confirmed the key was non-empty and `pg_db` was on `pg_net` while every query failed auth. **Connect from a sibling container over `pg_net`** — `pg_hba` trusts loopback, so `docker exec <pg> psql` returns success even with a deliberately wrong password, and any diagnosis made that way is worthless. |

### The app's own CLAUDE.md is not the authority

Worth stating plainly, because the tooling implies the opposite. Every app carries its own
CLAUDE.md and it is **auto-loaded as project instructions** — presented as something to
follow exactly — while this file arrives in that session as an attachment. In a migration
that ranking is inverted: the local file describes the app *before* the work, so it is the
artifact being corrected, not the specification.

Two failure modes follow, both seen on the odd-jobs migration:

- **Defects documented as standards.** Its volume-mount table described the unconditional
  `/opt/run-logs/<app>` mount — the exact bug that had been putting dev runs into the
  production log record — and its `build.sh` section required an `npm install` in a directory
  with no `package.json`, in three separate places. An agent conforming the code to that
  document would have preserved both.
- **Rival checklists.** It had its own "Migrating an app to this structure" section
  competing with Part 3. Two checklists means two answers; delete the local one.

The fix is ordering, not effort: mark the local file mid-migration *before* the first code
change, correct each section in the commit that makes it true, and delete any rival
checklist. Reconciling only at the end means every intermediate step was measured against
the pre-migration description.

### Host

- `/opt/apps/<app>` — release copy, `svc:docker`
- `/opt/run-logs/<app>` — **`svc:docker`, mode `2775`**, created before the first release run.
  `entrypoint.sh` deliberately will not re-chown a directory somebody set intentionally.
- `/opt/resources/secrets/` — root-only. Register the app with the rotation script for **every**
  secret it consumes — `PG_PW` counts, not just `REDIS_PW`. An unregistered app keeps a stale
  credential silently: odd-jobs sat on a rotated `PG_PW` for three weeks, its runs writing file
  logs and reporting success while every database call failed auth.

### Schedule

- Entries go in the **shared svc crontab** via `sudo crontab -u svc -e`. Never
  `crontab -u svc <file>` — that replaces the whole crontab and wipes other apps.
- Insert the entry into the right **cadence section** (`1. DAILY OR MORE FREQUENT` /
  `2. LESS THAN DAILY`), in chronological position within it — not into a per-app block. An app
  with jobs at two cadences belongs in both sections, under a `-----` subheading each time.
- **Absolute paths**: `/usr/bin/docker`, `/usr/bin/flock`. No `PATH=` is set in the crontab, so
  cron's default is doing the work otherwise.
- `docker compose run --rm -T` — `-T` is required under cron.
- Run from `/opt/apps/<app>`, omit `RUN_USER`, do not set `HOME`.
- `flock -n` if the app advances a cursor *after* doing work (overlap would double-process).
- Redirect to a bounded per-entry `.out` file rather than `/dev/null`, at least until proven.

### Verify

```bash
bash preflight-check.sh                                   # expect ZERO warnings
bash build.sh && RUN_USER=<you> docker compose run --rm <app> node index.js <arg>
#   -> log lands in ./utils/logger/logs, RELEASE_SHA reads 'dev-tree',
#      and NOTHING appears in /opt/run-logs/<app>
bash build-release.sh                                     # banner prints the current SHA
cd /opt/apps/<app> && docker compose run --rm <app> node index.js <arg>
#   -> log lands in /opt/run-logs/<app> owned svc:docker, RELEASE_SHA = that commit
```

Then confirm the **deployed copy is the code you think it is** — three separate findings during
the odd-jobs migration were "the release copy is not what I released":

```bash
grep '^RELEASE_SHA=' /opt/apps/<app>/.env          # matches the commit you meant to ship?
diff -r --brief --exclude=node_modules --exclude=.git --exclude=.env \
     /opt/apps/<app> /path/to/dev/tree              # any output = drift
(cd /opt/apps/<app> && bash preflight-check.sh)     # exercises the release-copy branch
```

A release builds the **image**; it does not run the app, so it produces no run log. The first
`<app>-log.svc.*` appears only when you actually run the released copy.

Then confirm in the database, not just from the run log — the log states intent, the tables
are the fact:

```sql
SELECT (verbose_log->0->'note'->>'RELEASE_SHA') sha, COUNT(*), MAX(inserted_at)
FROM util.app_run_logs WHERE app_name='<app>'
  AND inserted_at > now() - interval '1 hour' GROUP BY 1;
```

> **Part 1 is copied, not shared.** Each app carries its own CLAUDE.md, so Part 1 exists in as
> many copies as you have apps and *will* drift. When you change a convention, change it in the
> app you are working on and note that the others need syncing — same caveat as `utils/`.


## Migration: utils/ from shared to app-specific (REFERENCE)

**Status:** ✅ Complete on `docker` branch (2026-07-01)

This section documents the migration process for reference (already completed).

### Background

Previously, `utils/` was a **nested git repository** (branch `odd-jobs_dockerized`) shared across multiple apps:
- mmb-rpp (this app)
- alert-processor
- alert-notify
- reports
- preflight-check
- odd-jobs
- aws-ff

This created tight coupling and made it difficult to version utils independently per application.

### Migration Process

Follow these steps to convert utils from a shared submodule to an app-specific tracked directory:

#### 1. Snapshot current utils state
```bash
# Document current branch and commit
cd utils/
git log -1 --oneline
git branch
cd ..

# Create a backup
cp -r utils/ utils-backup/
```

#### 2. Remove git tracking from utils
```bash
# Remove the nested .git directory
rm -rf utils/.git
rm -f utils/.gitignore  # optional, can keep if useful

# Now utils/ is just a regular directory
```

#### 3. Clean up non-mmb-rpp resources

Remove SQL directories and files for other applications:
```bash
cd utils/db/sql/

# Keep only mmb-rpp SQL files
rm -rf alert-notify/
rm -rf alert-processor/
rm -rf aws-ff/
rm -rf odd-jobs/
rm -rf preflight-check/
rm -rf reports/

# Only mmb-rpp/ directory should remain
ls -la  # Should show: mmb-rpp/, pg-helpers.js, sql.js

# Also remove pg-helpers_hhm.js (unused by mmb-rpp, contains log event table defs)
cd ..  # back to utils/db/sql/
rm -f pg-helpers_hhm.js
```

#### 4. Update sql.js to remove other apps

Edit `utils/db/sql/sql.js` to export only mmb-rpp queries:
```javascript
const { QueryFile } = require('pg-promise');
const { join: joinPath } = require('path');

const sql = (file) => {
    const fullPath = joinPath(__dirname, file);
    return new QueryFile(fullPath, { minify: true });
};

module.exports = {
    mmb_rpp: {
        get_edu_configs: sql('mmb-rpp/get-edu-configs.sql'),
        get_edu_dev_config: sql('mmb-rpp/get-edu-dev-config.sql'),
        get_mag_configs: sql('mmb-rpp/get-mag-configs.sql'),
        get_mag_dev_config: sql('mmb-rpp/get-mag-dev-config.sql'),
    },
};
```

#### 5. Update pg-helpers.js to remove unused tables/columns

Remove column sets and table definitions that mmb-rpp never uses:
- Keep: `util.app_run_logs`, `mag.*`, `edu.*` (used by logger and data pipeline)
- Remove: `alert.*`, `log.*` (used by alert-processor, alert-notify)

Edit `utils/db/sql/pg-helpers.js`:
- Remove `log:` section from `pg_tables`
- Remove `alert:` section from `pg_tables`
- Remove `alert:` section from `pg_column_sets`

Keep only what mmb-rpp actually uses for data inserts.

#### 6. Remove unused utils modules

mmb-rpp only uses three utils modules:
```bash
# index.js imports:
# - ./utils/db/pg-pool
# - ./utils/db/sql/pg-helpers
# - ./utils/db/sql/sql
# - ./utils/logger/enums
# - ./utils/logger/log
```

**Remove these unused directories:**
```bash
cd utils/
rm -rf vpn/
rm -rf config-processor/
rm -rf units/
```

**Keep only:**
- `utils/db/` — Database connection pool, SQL queries, pg-promise helpers
- `utils/logger/` — Structured logging system (enums, log.js)
- `utils/sh/` — Shell script execution helper (used by read/ pipeline)

#### 7. Track utils in main repository

```bash
# From repository root
git add utils/
git commit -m "Migrate utils from shared submodule to app-specific directory

- Removed nested .git (was tracking odd-jobs_dockerized branch)
- Removed SQL files for other apps (alert-*, reports, odd-jobs, etc.)
- Cleaned up pg-helpers to only include mmb-rpp table definitions
- Simplified sql.js to only export mmb-rpp queries
- [List any removed utils modules]

This makes utils independently versioned for mmb-rpp."
```

#### 8. Update CLAUDE.md references

Update any documentation describing `utils/` as a shared repository — it is now app-specific
and independently versioned per app.

#### 9. Verify functionality

```bash
# Build and test
bash build.sh
RUN_USER=jonathan-pope docker compose run --rm mmb-rpp node index.js SME01096

# Check logs for any missing module errors
ls -lt /opt/run-logs/mmb-rpp/ | head -3
```

#### 10. Repeat for other applications

Use this same process as a reference when migrating other apps (alert-processor, alert-notify, etc.) to have their own app-specific utils directories.

### Post-Migration Notes

- Each app now maintains its own `utils/` with only the resources it needs
- Changes to utils in one app won't affect others
- Updates to shared patterns (logger, db connection) must be manually synced if desired
- Consider extracting truly common code to a proper npm package if sharing becomes necessary again

---

## Pre-Deployment Checklist (Staging/Prod)

Before deploying to staging or production environments, complete these tasks:

### 1. ✅ Complete utils migration (see above)
- [ ] Remove nested .git from utils/
- [ ] Clean up SQL files (keep only mmb-rpp/)
- [ ] Remove unused modules (vpn/, config-processor/, units/)
- [ ] Update sql.js to export only mmb-rpp queries
- [ ] Clean up pg-helpers.js (remove alert.*, log.* definitions)
- [ ] Commit and verify builds successfully

### 2. 🔍 Review TODOs in codebase
Current TODOs to address or document:
- `index.js:43` — Investigate adding safety writeLogEvents on process exit
- `index.js:215,224,230` — Clarify return vs process.exit behavior in error paths
- `parse/parse-capture-blocks.js` — Convert capture_reading regex from .* to .+
- `parse/_helpers/regex-models.js` — Convert to Set (if applicable)

### 3. 🔒 Security & Configuration
- [ ] Verify `.env` is properly gitignored (contains credentials)
- [ ] Ensure production `.env` has correct values:
  - `LOGGER_MODE=log` (file-only, no console spam)
  - `USER_ID` matches the production image tag / run user (`#RELEASE:USER_ID=svc`)
  - `PG_SSL_PATH` configured for production database
  - `REDIS_HOST` points to production Redis container
  - `REDIS_PW` set — required wherever Redis sets `requirepass`
- [ ] Review PostgreSQL SSL configuration in `utils/db/pg-pool.js`
- [ ] Confirm no hardcoded credentials in codebase

### 4. 🐳 Docker & Infrastructure
- [ ] Verify external networks exist: `pg_net`, `redis-admin_redis_net`
- [ ] Create log directory with correct ownership:
  ```bash
  sudo mkdir -p /opt/run-logs/mmb-rpp
  sudo chown <prod_user>:docker /opt/run-logs/mmb-rpp
  ```
- [ ] Verify `/opt/resources/` mount contains:
  - `acqu_files/` directory with source log files
  - `ssl/pg_ssl.crt` (if using SSL)
- [ ] Verify `entrypoint.sh` exists in app root (tracked in git)
- [ ] Test build on target environment: `bash build.sh`
- [ ] Verify container user switching works (svc vs jonathan-pope)

### 5. 📊 Database & Redis
- [ ] Verify target tables exist:
  - `mag.ge_mm3`, `mag.ge_mm4`, `mag.siemens`, `mag.siemens_non_tim`
  - `edu.v1`, `edu.v2`, `edu.v3`
  - `util.app_run_logs`
- [ ] Confirm SQL query files reference correct schemas/tables
- [ ] Test Redis connection and key pattern: `<sme>.<file_name>.log`
- [ ] Initialize Redis with correct filesizes or ensure jobs can handle empty keys

### 6. 📁 Source Data Files
- [ ] Verify log files exist in `/opt/resources/acqu_files/`
- [ ] Confirm file naming convention: `<SME_ID>.<file_name>.log`
- [ ] Test file permissions (readable by container users)
- [ ] Document any equipment-specific quirks (see Equipment quirks)

### 7. 🧪 Testing
- [ ] Smoke test with dev device ID:
  ```bash
  RUN_USER=<user> docker compose run --rm mmb-rpp node index.js SME01096
  ```
- [ ] Verify log output in `/opt/run-logs/mmb-rpp/`
- [ ] Check database inserts completed successfully
- [ ] Confirm Redis filesize updated only after successful insert
- [ ] Test prod run group:
  ```bash
  docker compose run --rm mmb-rpp node index.js 0
  ```

### 8. ⏰ Scheduling (Production Only)
- [ ] Set up cron jobs or systemd timers for run groups 0-7
- [ ] Stagger execution to avoid resource contention
- [ ] Configure monitoring/alerting for job failures
- [ ] Document schedule in operations runbook

### 9. 📝 Documentation
- [ ] Update operations runbook with:
  - Deployment steps
  - Rollback procedure
  - Troubleshooting guide (see bottom of this file)
  - Contact information
- [ ] Document run group assignments (which devices in each group)
- [ ] Create incident response plan for data pipeline failures

### 10. 🔄 Post-Deployment Validation
- [ ] Monitor first production run for errors
- [ ] Verify data appears in database tables
- [ ] Check application logs for warnings/errors
- [ ] Compare data volume/patterns with legacy system (if applicable)
- [ ] Validate Redis state matches expectations

---

## Bringing up a migrated app on a new server

```bash
# 1. Pull the migrated branch
cd /path/to/<app>
git fetch origin
git checkout docker
git pull origin docker

# 2. Verify utils/ is tracked, not a submodule
ls -la utils/                  # should NOT contain .git
git ls-files utils/ | head -5  # should list tracked files

# 3. Validate the environment before building
bash preflight-check.sh

# 4. Install dependencies and build (as the host user, never root)
bash build.sh

# 5. Smoke test as yourself against a single known-good target
RUN_USER=<you> docker compose run --rm <app> node index.js <arg>

# 6. Confirm the run log and check for warnings/errors
ls -lt ./utils/logger/logs/ | head -3
```

Then, once the dev-side smoke test is clean:

- Cut a release with `bash build-release.sh` and re-run as `svc` from `/opt/apps/<app>`. A dev
  run passing does **not** prove the release path works — it exercises different ownership, a
  different `.env`, and a different log directory.
- Document any server-specific quirks discovered.
- Merge to your production branch.

---

# PART 4 — REMAINING WORK: mmb-rpp MIGRATION

*Transient. This is the only part tied to the current state of **this** migration — delete it
first, once mmb-rpp is on PROD. Parts 1–3 stay useful afterwards.*

## Current Status: Staging Validated End-to-End (2026-08-19)

**Branch:** `docker`  
**Migration Status:** ✅ Complete (utils/ migrated to app-specific)  
**Staging Status:** ✅ Full pipeline verified on this server

### Staging Validation Results (2026-08-19)

The full READ → PARSE → PROCESS → PERSIST pipeline was exercised on staging and
confirmed working:

| Test | Result |
| ---- | ------ |
| Single device `SME01136` (edu2 + siemens_non_tim) | 7 rows per config, both sinks, 0 warnings |
| Run group `0` (45 configs) | **293 rows / 37 devices in 12.8s** |
| Incremental re-run 30 min later | 1 new row per config (delta tracking correct) |

Two fixes landed that made the group run viable — before them, `index.js 0` ran
9 minutes and had to be killed, leaving zero diagnostics:

1. **`delta > 400_000` guard re-enabled** in `runJob` READ. It fired once on group 0
   and is the reason the run takes seconds instead of minutes. Do not comment this
   out again without a plan for large-file devices.
2. **`gracefulShutdown` added** — module-level `active_run_log` / `active_redis_client`
   refs plus `SIGTERM`/`SIGINT` handlers that flush `writeLogEvents` +
   `dbInsertLogEvents`, disconnect redis, then exit. Previously a killed run left a
   0-byte log file and no `util.app_run_logs` row. (gosu execs node, so node is PID 1
   and receives the signal directly.)

### Known Staging Environment Gaps (not code defects)

These were found during validation and are environmental — they do not block deploys,
but they shape what a "green" run means here:

- **~48% of configs have no source file.** 255 of 529 configs reference a
  `<SME>.<file_name>.log` that does not exist under `/opt/resources/acqu_files/`.
  Those jobs log an ERROR from `execCheckFilesize` and halt gracefully. Group 0 alone
  has 7. The mount also contains 197 *directories* (`SME09713/host_logfiles/...`) in a
  different shape that this pipeline does not read.
- **224 mag configs have a NULL `schedule`** — they match no run group `0`–`7` and
  therefore never execute in a scheduled run.
- **Monthly partitions are provisioned only ~1 month ahead.** `util.app_run_logs` (and
  roughly 24 other partitioned tables) are RANGE-partitioned on a timestamp; inserts
  fail with *"no partition of relation found for row"* once the newest partition's
  upper bound passes. Tracked separately as an ops concern.
- **GE MM3 parse misses.** Group 0 produced 16 `qaMatches 0 MATCHES` warnings across 9
  devices — a capture block whose readings don't match the device's configured regex
  profile. These are per-block, not per-job: every affected device still inserted rows.
  Consistent with the documented A–F profile variation (see Equipment quirks), but there
  is no historical baseline on this box to confirm it is pre-existing.


## To-do

Ordered. Items 1–3 are what actually stands between here and a merged migration.

- [x] **1. Re-release so `/opt/apps/mmb-rpp` matches `HEAD`.** Done 2026-08-20 at `beb8d57`.
      Verified: `.env` transformed to `USER_ID=svc` / `LOG_DIR=/opt/run-logs/mmb-rpp` /
      `RELEASE_SHA=beb8d57` with all `#RELEASE:` markers stripped, dev logs excluded from the
      mirror, and a release run as svc wrote `mmb-rpp-log.svc.*` to `/opt/run-logs/mmb-rpp`
      with `RELEASE_SHA=beb8d57` recorded in `app_run_logs`. Re-run `build-release.sh` after any
      further commits — a stale release copy means cron executes stale code.
- [x] **2. Schedule run groups 0–7 via cron as svc.** Done 2026-08-20, verified over 6
      consecutive cycles — all 8 groups every cycle, each starting within ~2s of schedule, all
      on `RELEASE_SHA=beb8d57`. **All seven column sets now hold data**, including the four
      never previously written: `edu.v1` (330 rows), `mag.ge_mm4` (986), `mag.siemens` (2,566),
      and `mag.siemens_non_tim`. See *Cron schedule* below for the installed entries and the
      observed per-cycle behaviour.
- [ ] **3. Merge `docker` → `STAGING`.** Note the branch is several commits ahead of
      `origin/docker` and unpushed; push before merging so the release is reproducible by
      someone else.
- [ ] **4. Register mmb-rpp with the host Redis rotation script** (key `REDIS_PW`), and confirm
      with whoever owns `/opt/resources/secrets/` which sibling apps on this box need the same.
      Without registration, the next rotation breaks every run at the READ stage.
- [ ] **5. Verify data against the legacy system** once groups 1–7 have run, before trusting
      the pipeline for reporting.

### Deferred by decision

- **Monthly partitions provisioned only ~1 month ahead** — `util.app_run_logs` plus roughly 24
  other partitioned tables. Inserts fail with *"no partition of relation found for row"* once
  the newest partition lapses. Explicitly deferred on 2026-08-20 as an ops-wide concern, not an
  mmb-rpp bug. Re-raise rather than assuming it is handled.
- **No `git_commit` image label** — `LABEL version="${USER_ID}"` records identity (`svc`), not a
  version, so `docker inspect` cannot identify a stray container's code. `RELEASE_SHA` covers
  the runtime case, which is the one that matters for tracing data.
- **`index.js` TODOs** — `index.js:215,224,230` (return vs `process.exit` in error paths),
  `parse/parse-capture-blocks.js` (`capture_reading` regex `.*` → `.+`),
  `parse/_helpers/regex-models.js` (convert to Set).

## Cron schedule (run groups 0–7)

These are mmb-rpp's entries in the **shared svc crontab** — see *Scheduling: cron jobs under
svc* in Part 1 for the conventions. Add them with `sudo crontab -u svc -e` (never install from
a file; that would wipe the other apps' entries). They live here rather than in the repo,
because the schedule is host configuration — changing a cadence should not require a release.

**Installed and verified 2026-08-20.** Groups 1-7 at `:17`/`:47` offset 10s apart; group 0 in
its own slot at `:20:30`/`:50:30`.

```cron
17,47 * * * * sleep 0  && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.1.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 1 >/opt/run-logs/mmb-rpp/cron.1.out 2>&1
17,47 * * * * sleep 10 && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.2.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 2 >/opt/run-logs/mmb-rpp/cron.2.out 2>&1
17,47 * * * * sleep 20 && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.3.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 3 >/opt/run-logs/mmb-rpp/cron.3.out 2>&1
17,47 * * * * sleep 30 && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.4.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 4 >/opt/run-logs/mmb-rpp/cron.4.out 2>&1
17,47 * * * * sleep 40 && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.5.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 5 >/opt/run-logs/mmb-rpp/cron.5.out 2>&1
17,47 * * * * sleep 50 && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.6.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 6 >/opt/run-logs/mmb-rpp/cron.6.out 2>&1
17,47 * * * * sleep 60 && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.7.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 7 >/opt/run-logs/mmb-rpp/cron.7.out 2>&1

# OFFSET - group 0 runs in its own minute slot, carried over from the legacy prod schedule
20,50 * * * * sleep 30 && cd /opt/apps/mmb-rpp && /usr/bin/flock -n /tmp/mmb-rpp.0.lock /usr/bin/docker compose run --rm -T mmb-rpp node index.js 0 >/opt/run-logs/mmb-rpp/cron.0.out 2>&1
```

Why it looks like this:

- **`:17`/`:47`.** Source captures land at `:15`/`:45`, so this picks them up ~2 minutes later.
  Inherited from the legacy pre-Docker schedule, which used the same offsets.
- **10s stagger via `sleep`.** Cron granularity is one minute, so sub-minute offsets need a
  `sleep` prefix. Groups 1-7 start `:17:00` through `:18:00`. They overlap (a group takes
  ~13s), which is fine — different groups touch different configs and different Redis keys.
- **Group 0 in its own slot.** Carried over from legacy prod. Keeps the historically slowest
  group from contending with the rest; it has 2m17s of clear air after group 7 finishes.
- **`-T`** disables TTY allocation, required under cron. Matches the odd-jobs convention.
- **Absolute `/usr/bin/docker` and `/usr/bin/flock`.** Bare names work today because `/usr/bin`
  is on cron's default `PATH`, but the crontab's `PATH=` line is shared by every app — one app
  retuning it would break the others silently. Part 1 requires absolute paths; these entries
  were brought in line rather than softening that rule.
- **`flock -n` skips rather than queues.** Redis advances only after a successful insert, so
  two overlapping runs of the *same* group would both read the same delta and double-insert.
- **Output to `cron.<N>.out`, single `>`.** Both real log sinks already capture a run, but a
  failure *before* node starts leaves no log anywhere. Overwriting keeps these bounded.
- **No `HOME`, no `RUN_USER`** — see Part 1.

### Observed behaviour (first 6 cycles, 2026-08-20/21)

| cycle | events | rows | warn | err | parse-miss |
| ----- | -----: | ---: | ---: | --: | ---------: |
| 23:30 (first) | 39,185 | **14,780** | 14,585 | 31 | 7,104 |
| 00:00 | 3,860 | 255 | 570 | 31 | 249 |
| 00:30 | 3,780 | 249 | 490 | 31 | 210 |
| 01:00 | 3,769 | 248 | 484 | 31 | 208 |
| 01:30 | 3,768 | 246 | 495 | 31 | 213 |
| 02:00 | 3,780 | 243 | 531 | 31 | 229 |

The first cycle drains the accumulated backlog, then it settles at ~245 rows/cycle. All 8
groups ran in all 6 cycles, each starting within ~2s of schedule.

**`err` is 31 every cycle and that is expected** — it is exactly the count of configs whose
source file does not exist on this host (see *Known staging environment gaps*). Treat a change
in that number as the signal, not the number itself.

**Parse misses are concentrated, not systemic.** ~210/cycle sounds alarming next to ~245 rows,
but 136 devices insert cleanly and only 33 skip anything. Five Siemens devices —
`SME13604`, `SME13605`, `SME13606`, `SME13607`, `SME11246` — account for ~75% of all skips,
each dropping ~30 blocks while inserting only 2 rows. That is a regex-profile mismatch on one
cluster, not a pipeline fault. See *Equipment quirks*; these five are unresolved.

### Expected outcome per group

Predicted by comparing each config's on-disk filesize against its Redis value. Use this to
tell a genuine failure from an expected halt — **a non-zero halt count is normal**, see
*Termination convention* in Part 1.

| grp | configs | will process | no source file | not grown | >400k guard |
| --- | ------- | ------------ | -------------- | --------- | ----------- |
| 0 | 45 | 37 | 7 | 0 | 1 |
| 1 | 51 | 38 | 4 | 7 | 2 |
| 2 | 45 | 37 | 7 | 1 | 0 |
| 3 | 44 | 33 | 2 | 9 | 0 |
| 4 | 52 | 44 | 5 | 3 | 0 |
| 5 | 22 | 20 | 1 | 1 | 0 |
| 6 | 25 | 23 | 1 | 1 | 0 |
| 7 | 21 | 16 | 4 | 1 | 0 |

Snapshot taken 2026-08-20; the "not grown" counts drift as source files gain data.

**All seven column sets are exercised across the eight groups**, and **group 1 alone hits all
seven** (`edu.v1`, `edu.v3`, `mmb_edu2`, `mmb_ge_mm3`, `mmb_ge_mm4`, `mmb_siemens`,
`mmb_siemens_non_tim`). Group 0 is only `mmb_ge_mm3` + `edu.v3`, so every run so far has said
nothing about the other five — group 1 is the highest-value one to watch first.

### Validation after install

After two full cycles (~1 hour), confirm every group ran and none is silently halting:

```sql
SELECT (verbose_log -> 0 -> 'note' ->> 'schedule')    AS run_group,
       (verbose_log -> 0 -> 'note' ->> 'RELEASE_SHA') AS release_sha,
       COUNT(*) AS runs,
       SUM(json_array_length(warn_error_logs)) AS warns_errors,
       MAX(inserted_at) AS last_run
FROM util.app_run_logs
WHERE app_name = 'mmb-rpp' AND inserted_at > now() - interval '2 hours'
GROUP BY 1, 2 ORDER BY 1;
```

Expect eight rows (`0`–`7`), each with `release_sha` matching the deployed commit and roughly
two runs per group. Things to react to:

- **A missing group** — cron did not fire, or `flock` skipped every tick. Check
  `/opt/run-logs/mmb-rpp/cron.<N>.out` and `journalctl -u cron`.
- **`release_sha` = `dev-tree`** — cron is running a dev tree, not the release copy.
- **Zero rows at all** — the crontab is not installed, or installed under the wrong user.
- **Row counts far above the prediction** above — something reset Redis and configs are
  reprocessing from zero.

Then confirm data actually landed in the tables that had never been written before:

```sql
SELECT 'mag.siemens' t, COUNT(*) FROM mag.siemens
UNION ALL SELECT 'mag.siemens_non_tim', COUNT(*) FROM mag.siemens_non_tim
UNION ALL SELECT 'mag.ge_mm4', COUNT(*) FROM mag.ge_mm4
UNION ALL SELECT 'edu.v1', COUNT(*) FROM edu.v1
UNION ALL SELECT 'edu.v2', COUNT(*) FROM edu.v2
UNION ALL SELECT 'edu.v3', COUNT(*) FROM edu.v3
UNION ALL SELECT 'mag.ge_mm3', COUNT(*) FROM mag.ge_mm3;
```


### Rollback Plan (If Needed)
If the migration causes issues on staging:
```bash
# The utils-backup/ directory was gitignored, so it only exists on dev
# If needed, the old nested git setup can be restored from the previous commit
git log --oneline --grep="Migrate utils" -1  # Find migration commit
git revert <commit_hash>  # Revert if necessary
```

---


