# Fleet migration prompt — dev/release paradigm, one app at a time

Paste the block between the rules into a fresh Claude Code session opened **in the
target app's repo**. Fill in the one `<APP>` placeholder at the top. Nothing else in
the block is app-specific.

Queue (one at a time, order per doc 2.1's blast-radius suggestion, adjusted freely):
`part-source-pipeline → acumatica_sync → hhm_rpp_siemens → hhm_rpp_ge →
hhm_rpp_philips → reports → incident-engine → ops-dashboard → pg_manage_v2 →
redis-admin`.
Done: **data_acquisition** (2026-08-24, the pilot), **monday** (2026-08-25, rollout
#2 — first app scheduled in the svc crontab, first non-logger app shape).

---

I want to migrate **`<APP>`** to our dev/release paradigm — the same migration
data_acquisition (pilot, 2026-08-24) and monday (2026-08-25) completed. One app at
a time; this session is only about this app.

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
3. **monday is the second reference (dev clone `~/apps/monday`)** — use it when the
   app's shape differs from the pilot's: no vendored file logger (run record is a
   DB table + boot-line provenance, not `util.app_run_logs`), external-API
   credentials verified in preflight (authenticated read-only checks), entrypoint
   repair of OUTPUT dirs rather than log dirs, a release script whose excludes are
   report/CSV bulk rather than log bulk. **Copy the scripts from whichever
   reference is closer in shape and adapt the app-specific lists** (writers, tar
   excludes, required env keys, preflight checks) — build.sh / build-release.sh /
   preflight-check.sh are meant to be copied, not re-derived.
4. `data_acquisition/docs/docker_server_full_setup_2.1.md` — server-wide facts
   (users, groups, secrets, networks). Its per-app sections describe the
   PRE-paradigm state for un-migrated apps; that is the state you are changing.
5. This app's own CLAUDE.md/README/docs are **evidence of current state, not the
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
`RELEASE_SHA` (or `dev-tree`) in **whatever run record the app actually writes** —
the `util.app_run_logs` note for logger apps; for an app whose sink is a shared
table you may not alter, the stamped `.env` plus a boot console line captured by
the cron `.out` files is the accepted form (monday / `stats.job_runs` precedent);
cron entries are hardened (absolute paths, `flock -n`, `-T`, direct argv, bounded
`.out` files) at unchanged cadences.

**Pilot lessons — check each of these explicitly; every one cost us a debugging
session or was caught only by verification:**

- **Freeze the live tree first.** `/opt/apps/<APP>` is bind-mounted into every
  scheduled run — NO behavioral commits land there. Sequence: commit docs/push in
  the live tree → freeze it → create the dev clone → all code work in the clone →
  production keeps running old code until `build-release.sh` replaces it in one
  step.
- **Find ALL the file writers, not just loggers.** Grep for module-scope `require`
  of any root-level logger AND for `writeFileSync|createWriteStream|appendFile`
  across jobs/tools (data_acquisition had a legacy winston `logger.js` required by
  ~10 job files writing a gitignored `./logs`; monday had NO logger but wrote
  `files/`, `data_outputs/`, and repo-root reports). The writer list drives three
  things that must stay in sync: entrypoint repair (dev), release-script `mkdir`
  (release), and the tar excludes. A vendored `utils/logger` may be entirely dead
  code — prove which sinks are LIVE before conforming anything to them.
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
- **The schedule may not be where the paradigm says — and may be DEAD.** This
  host's job apps (hhm_rpp_*, incident-engine) run from **matt-teixeira's USER
  crontab**; data_acquisition and monday are the paradigm exceptions (svc crontab).
  monday's schedule had been deliberately stopped days before its migration and
  existed in NO crontab at all — its cadences were reconstructed from the run
  record (`GROUP BY` minute-of-hour over the history). So: FIRST establish when
  the app last actually ran from its run table, then ask the operator whether any
  stop was deliberate and which job families come back (monday's
  `new_avconn_tickets` had been dead 4 months and stayed dead). If suspending a
  live user crontab, `cron-suspend.sh` clears the WHOLE thing — keep the window
  short, restore from an edited copy where ONLY this app's entries changed, and
  count entries before/after (the pilot dropped one and only the verification
  diff caught it).
- **Verify with a DB baseline, not a checklist.** Before cutover, capture per-family
  run counts and warn/error sums from the app's ACTUAL run record
  (`util.app_run_logs` or `stats.job_runs`) for a fixed window — for a dead
  schedule, the last healthy week. After two full cron cycles, compare: same
  families, same volumes, only the released SHA, zero `dev-tree`. Daily jobs
  verify on their own clock (next morning) — say so rather than calling it done.
  Expect a first-cycle surge if a backlog accumulated; judge by family/SHA/status,
  not first-cycle volume.
- **Back up the release copy's `.env` outside `/opt/apps` before the first wipe**,
  and remember the old `/opt/apps/<APP>` may be an unpushed git repo — push
  EVERYTHING before the wipe makes it unrecoverable.
- **Check `/opt/apps/<APP>/node_modules` ownership before the first release.**
  `build-release.sh` deliberately preserves it as an install cache, but a stale
  ROOT-owned husk (monday had one from its cache-mount era) makes svc's npm
  install die — `sudo rm -rf` it once, before the first release.
- **Never `source` an app's `.env` in scripts.** monday's held `$$` inside
  Acumatica URIs — bash expands that to a PID, and `set -a` then exports the
  mangled value OVER compose's own interpolation. Read single keys with grep
  (the `env_val()` helper in either reference preflight); both references'
  build.sh now do exactly this.
- **Don't cargo-cult over this app's strengths.** data_acquisition kept (and you
  should keep where present): the run_outcome/v1 exit-code contract
  (ops-dashboard + incident-engine consume it — never regress to exit-0-on-kill),
  deny-by-default `.dockerignore` with baked entrypoint, no-default build ARGs.
  Add SIGTERM/SIGINT flush-once handlers if missing (signal → finalize with a
  once-guard → honest non-zero exit), and verify them with a real kill test.
- **Found a loaded footgun? Propose removal, but expect "keep it".** monday's
  `.env` carries an active Azure-PROD DB fallback the owner chose to keep. Either
  answer is fine — what is NOT fine is silence. Document the kept hazard as a
  KNOWN WART in the app's CLAUDE.md (what it is, what must not be touched), and
  where cheap add a preflight guard (monday errors if `PGHOST` goes empty while
  `PG_HOST` is set).

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

**Standing decisions — settled fleet-wide on earlier migrations. Do not re-ask;
apply them. Only surface a decision if this app genuinely breaks the pattern:**

- **New or rebuilt schedules go into the SHARED SVC CRONTAB** (cadence sections,
  hardened entries; monday 2026-08-25 was the first). Existing user-crontab
  schedules stay where they are until the separate consolidation follow-up
  (data_acquisition BACKLOG 6f) — do not move them as part of a migration.
- **No schema changes to shared tables for provenance.** The stamped `.env` +
  boot-line pattern is the accepted alternative (monday precedent).
- **Dead job families stay dead** unless the owner names them for resurrection.
- **Hazard/dead-code removal needs explicit per-item owner sign-off**; the default
  is keep-and-document (known-wart pattern above). Post-cutover cleanup (e.g. the
  vendored `utils/` museum) is deferred, not bundled into the migration.
- **Preflight externals:** authenticated checks wherever a read-only probe exists
  (PG from a sibling container on `pg_net` — never `docker exec pg_db psql`;
  Monday.com `me` query); presence-only where a real check would log into or
  mutate a production system (Acumatica login, Teams webhooks) — the read-only
  smoke job covers those.
- **Rotation script** (`/opt/resources/scripts/rotate-envs-20260817.sh`, owner
  Matt) rewrites BOTH copies (`/opt/apps/<app>/.env` and `~/apps/<app>/.env`) for
  every app in its list, matching on the VALUE equal to its reference. So
  "registered" = the app is in that list AND its password value matches the
  reference — verify both, and flag drift instead of editing the script yourself.

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
- **Save the first round-trip: paste the schedule state WITH the prompt.** The
  session cannot read other users' crontabs, and both migrations so far stalled
  the audit on exactly that. Append to your first message the output of:
  `crontab -l`, `sudo crontab -u svc -l`, and (if the app's last run looks stale)
  `sudo crontab -u jonathan-pope -l` / `sudo crontab -u root -l`.
- **Your fixed touchpoints per app** (monday needed exactly these; everything else
  the session does itself):
  1. Answer the audit's sudo forensics if asked (other users' crontabs, journal).
  2. Rule on the app-specific decision list the audit ends with.
  3. `sudo rm -rf /opt/apps/<APP>/node_modules` if the audit finds it root-owned.
  4. `bash ~/apps/<APP>/build-release.sh` — the first release, and once more for
     the doc-closeout commit after the banner comes off.
  5. Paste the cron block via `sudo crontab -u svc -e`, then confirm the entry
     count the session gives you.
- After each app: keep `/opt/run-logs/<app>` (svc:docker 2775) and rotation-script
  coverage on the checklist. The script now handles both copies automatically for
  listed apps; adding a NEW app to its list is your edit, not the session's.
- Timing note from monday: audit → cutover → two-cycle verify fit in one session;
  daily jobs verify the next morning, and the banner-off + closeout release waits
  for them.
