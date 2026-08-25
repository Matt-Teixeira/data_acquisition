# Fleet migration prompt — dev/release paradigm, one app at a time

Paste the block between the rules into a fresh Claude Code session opened **in the
target app's repo**. Fill in the one `<APP>` placeholder at the top. Nothing else in
the block is app-specific.

Queue (one at a time, order per doc 2.1's blast-radius suggestion, adjusted freely):
`monday → part-source-pipeline → acumatica_sync → hhm_rpp_siemens → hhm_rpp_ge →
hhm_rpp_philips → reports → incident-engine → ops-dashboard → pg_manage_v2 →
redis-admin`. (data_acquisition: done 2026-08-24, the pilot.)

---

I want to migrate **`<APP>`** to our dev/release paradigm — the same migration
data_acquisition completed on 2026-08-24 as the pilot. One app at a time; this
session is only about this app.

**Reference material (read before touching anything):**

1. `/opt/apps/data_acquisition/docs/migration_CLAUDE.md` — the paradigm spec.
   Part 1 = the conventions, Part 3 = the migration checklist ("Aligning an existing
   app to this paradigm") with its ordered **Known dependencies** — treat those
   orderings as law.
2. **data_acquisition itself is the local reference implementation** — its
   `CLAUDE.md`, `build.sh`, `build-release.sh`, `preflight-check.sh`,
   `docker/entrypoint.sh`, `docker-compose.yaml`, `.env.example`, and
   `cron-bk/crontab.restore-2026-08-24.cron` (dev clone: `~/apps/data_acquisition`).
   Prefer its versions over mmb-rpp's where they differ — the differences are
   deliberate, hard-won fixes (listed below).
3. `data_acquisition/docs/docker_server_full_setup_2.1.md` — server-wide facts
   (users, groups, secrets, networks). Its per-app sections describe the
   PRE-paradigm state for un-migrated apps; that is the state you are changing.
4. This app's own CLAUDE.md/README/docs are **evidence of current state, not the
   spec**. Expect them to document defects as standards. When they disagree with
   the paradigm docs, they are wrong until proven otherwise — say so explicitly in
   the audit rather than silently following either.

**The target state, in one paragraph:** the editable git clone lives at
`~/apps/<APP>`; `/opt/apps/<APP>` is build output produced ONLY by
`build-release.sh` (clean-tree guard above the wipe, `#RELEASE:` overrides applied
to the deployed `.env`, `RELEASE_SHA` stamped); images tag by identity —
`<app>:<username>` for dev builds, `<app>:svc` for the release; production runs as
`svc` via the entrypoint default, logs to `/opt/run-logs/<APP>` through a
`${LOG_DIR:-<dev path>}` mount that FAILS SAFE to the dev path; every run records
`RELEASE_SHA` (or `dev-tree`) in its logs and `util.app_run_logs` row; cron entries
are hardened (absolute paths, `flock -n`, `-T`, direct argv, bounded `.out` files)
at unchanged cadences.

**Pilot lessons — check each of these explicitly; every one cost us a debugging
session or was caught only by verification:**

- **Freeze the live tree first.** `/opt/apps/<APP>` is bind-mounted into every
  scheduled run — NO behavioral commits land there. Sequence: commit docs/push in
  the live tree → freeze it → create the dev clone → all code work in the clone →
  production keeps running old code until `build-release.sh` replaces it in one
  step.
- **Find ALL the loggers before touching log paths.** Grep for module-scope
  `require` of any root-level logger (data_acquisition had a legacy winston
  `logger.js` required by ~10 job files, writing to a gitignored `./logs` that
  existed in neither new copy). Every directory any logger writes must exist in
  BOTH copies — entrypoint repair for dev, release-script `mkdir` for the release.
- **Gitignored bulk passes the clean-tree guard but ships via tar.** Run
  `git status --ignored` and put every ignored dir/pattern into the tar excludes
  (data_acquisition's `logs/` held 93k files). Use NARROW patterns — a bare
  `*.json` exclude strips `package.json` and breaks the release build. Verify
  excludes by diffing `tar -tf` output, never by eyeballing patterns.
- **The svc HOME trap bites BuildKit.** Plain docker commands tolerate svc's
  `/nonexistent` home; `docker compose build` does not (`mkdir /nonexistent:
  permission denied`). Use the pilot's fix — build as svc with
  `HOME=/opt/apps/.svc-home` (already exists, svc:docker 700). Never `HOME=/tmp`
  (the reference's documented wart: `/tmp/.docker` svc:700 breaks docker for
  everyone else). mmb-rpp's build-release.sh still carries that wart — don't copy
  it.
- **The schedule may not be where the paradigm says.** This host's job apps
  (hhm_rpp_*, incident-engine, formerly data_acquisition) run from
  **matt-teixeira's USER crontab**, not svc's. Snapshot with `crontab -l` (and
  check `sudo crontab -u svc -l` too), suspend with
  `data_acquisition/scripts/cron-suspend.sh` semantics (it clears the WHOLE user
  crontab — other apps' entries go quiet with it; keep the window short), and
  restore from an edited copy where ONLY this app's entries changed. Count entries
  before and after — the pilot dropped one (`system_reset_totalizer`, line 84,
  past where the first read paged) and only the verification diff caught it.
- **Verify with a DB baseline, not a checklist.** Before cutover, capture per-family
  run counts and warn/error sums from `util.app_run_logs` for a fixed window. After
  two full cron cycles, compare: same families, same volumes, only the released SHA,
  zero `dev-tree`. This diff is what catches dropped entries and behavior drift.
- **Back up the release copy's `.env` outside `/opt/apps` before the first wipe**,
  and remember the old `/opt/apps/<APP>` may be an unpushed git repo — push
  EVERYTHING before the wipe makes it unrecoverable.
- **Don't cargo-cult over this app's strengths.** data_acquisition kept (and you
  should keep where present): the run_outcome/v1 exit-code contract
  (ops-dashboard + incident-engine consume it — never regress to exit-0-on-kill),
  deny-by-default `.dockerignore` with baked entrypoint, no-default build ARGs.
  Add SIGTERM/SIGINT flush-once handlers if missing (signal → finalize with a
  once-guard → honest non-zero exit).

**App-shape caveats — verify what is actually here, then adapt:**

- **Shared images:** hhm_rpp_ge builds `hhm_rpp:<tag>` consumed by philips and
  siemens (no Dockerfiles of their own, on purpose). Re-tagging a SHARED image by
  `USER_ID` affects all three apps — migrate the image owner (ge) and consumers as
  a coordinated set, or keep the shared tag and note the deviation. Same question
  for reports' `aux:` image. STOP and present options before changing a shared tag.
- **Long-running services** (ops-dashboard; possibly others): the release-copy /
  `RELEASE_SHA` / tags-by-identity parts apply; the cron-hardening parts do not.
  A service needs a restart step in the release flow instead.
- **Apps without their own image** (incident-engine runs stock node:lts with a
  `user:` pin; it also already deploys from a separate `/opt/apps/incident-engine-deploy`
  worktree): reconcile with the existing deploy mechanism rather than layering a
  second one.
- **Admin/infra repos** (pg_manage_v2, redis-admin, branch `STAGING` not
  `STAGING_docker`): mostly host tooling; take only the pieces that fit (release
  provenance, preflight) and say which pieces you're skipping and why.
- An app may not use Redis, may have no run groups, may not read
  `/opt/resources/acqu_files`. Where the checklist says "if the app does X",
  check whether it does.

**Shared-state warning:** dev-clone runs hit the SAME staging DB, data mounts, and
Redis as production. A dev run is a real run. Pick smoke jobs deliberately and say
what state each will touch before running it.

**Working constraints:**

- `sudo` has no TTY in your session — hand me exact commands and I run them.
- Small commits, one concern each, real reasoning in the messages. Push as you go.
- Do not push to shared/protected branches or merge without asking.
- Verify against the database and filesystem, not what a log or doc claims.
- Update the app's own CLAUDE.md as each step lands (mid-migration banner FIRST,
  before any code change; corrected per-commit; banner off only after cutover
  verifies). Delete any rival migration checklist in favor of Part 3.
- When done, update `data_acquisition/docs/docker_server_full_setup_2.1.md`
  (this app's section + the entrypoint/build matrix row + the header's
  "migrated so far" list) and `data_acquisition/BACKLOG.md` item 6, and note the
  next app in the queue.

**What I want first:** audit this app against Part 3's checklist plus the pilot
lessons above, and REPORT THE GAPS BEFORE CHANGING ANYTHING. For each gap: what is
here now, what it should be, whether it is broken or merely non-conforming, and
which items are inert until an earlier one lands. Then propose the commit/cutover
sequence (Known dependencies are fixed; sequence the rest), the smoke jobs you'd
use and what shared state they touch, and the verification plan (preflight zero
warnings; dev round-trip; guard negative-test; release round-trip; DB baseline
diff over two cron cycles). I pick the order before you start.

---

## Notes for the operator (not part of the prompt)

- Run migrations one at a time; let each soak a couple of cron cycles before
  starting the next.
- The hhm_rpp trio is really ONE migration in three repos — budget it that way.
- After each app: re-run `build-release.sh` for doc-closeout commits the same way
  the pilot did, and keep `/opt/run-logs/<app>` + rotation-script registration on
  the checklist (both copies' `.env`s go stale together).
