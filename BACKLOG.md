# Operations Backlog

Living list of things to address, kept here because data_acquisition is the de-facto
base of operations. Started 2026-08-20 from the post-migration health audit (the
staging DB + Redis wipe/rebuild/migration of 2026-08-19). Add new items at the
bottom of the relevant section; mark done with date rather than deleting.

Conventions: each item has an owner, a trigger/deadline if one exists, and the
evidence or doc section it came from. "Doc 2.1" = `docs/docker_server_full_setup_2.1.md`.

---

## 1. Host-key handling for new/changed systems (new since migration)

**Symptom (2026-08-20 audit):** 905 rsync failures across 11 systems in the first
17 h after the prod inventory landed — `No ED25519 host key is known for <ip> …
Host key verification failed`. Strict checking is doing its job; the migrated
inventory contains IPs the Apr-03 `/opt/resources/ssh/known_hosts` has never seen.

Affected systems (fail every cycle until keyed):
`SME21284 SME21824 SME20556 SME21580 SME22407 SME22721 SME13615 SME22722 SME12631 SME01097 SME18352`

- [ ] **1a. Clear the current backlog of 11** — **import ran 2026-08-20 18:23**
      (prod → staging: 395 hashed lines appended, 289 local intact, ownership/mode
      preserved, no regression — still exactly 7 failing IPs overnight, nothing
      new). **Finding: this was never a known_hosts gap prod could fill** — none of
      the 7 IPs exist in prod's `~/.ssh/known_hosts` (its 395 entries are
      ecdsa/ssh-rsa, zero ed25519, zero matches via `ssh-keygen -F`), and 9 of the
      11 systems have NULL `ip_address` in `public.systems` (rsync targets come
      from migrated Redis/config state). Remaining question is prod-side: does
      prod acquire these systems at all, and from which account/known_hosts?
      Checks for Matt on prod: `ssh-keygen -F 10.154.16.180 -f
      /home/prod/.ssh/known_hosts` (expect miss); look for other accounts'
      known_hosts (`sudo ls /root/.ssh /home/*/.ssh`); check prod's own success
      for SME21284/SME01097. If another account holds the keys → rerun
      `known_hosts_migrate.sh` with `SRC` pointed there. If prod doesn't reach
      them → fold these 11 into **item 4a** (inventory drift) and close 1a.
      Owner: Matt (prod shell required).
      **Update 2026-08-21: folded into 4a** (worksheet clusters B+C — the import
      revealed 4 of them are re-keyed hosts, the rest never-keyed collectors) and
      **parked with it** by owner decision. Close both together when 4a resumes.
- [x] **1b. Standing procedure** — done 2026-08-20, reshaped per owner direction to
      a **prod-side push** mirroring `redis_migrate.sh`: new
      `scripts/known_hosts_migrate.sh` (runs on the source server; validates,
      ships+md5-checks, backs up on target, append-only exact-line-dedupe merge,
      atomic install, prints rollback). Doc 2.1: SHARED SSH BUNDLE gained the
      "Incremental import after a migration" subsection (covers bulk + single-host)
      and now names odd-jobs as the second bundle consumer; new §5.8 makes the
      import a standard post-seed step; STEP 4 repointed at the now-tracked
      `scripts/redis_migrate.sh`. Merge logic fixture-tested (dup/new/CRLF/
      malformed-abort/@marker); remote leg exercised by 1a's dry run.
- [x] **1c. Fix error classification** — done 2026-08-21: `host_key_unknown`
      root-cause entry added to `util/tools/connection_regex.js` in the SSH-key
      block (below `host_key_changed`, which must match first — the
      identification-changed banner also contains "Host key verification
      failed"). Covers (i) the category and (ii) the informative message that
      lands in `connection_error`; bonus: as a key-class (non-connection) error
      it stops the pointless tunnel-reset retry these failures used to trigger.
      Six-case ordering test passed (real blob, scp form, MITM banner,
      plain reset, publickey, timeout). (iii) resolved as **not a gap on mmb**:
      NULL categories there are success rows (138) and never-attempted
      placeholders (85); zero failed rows lack a category. Residual: 47
      failed-NULL rows on the **hhm** table, most likely the decrypt-era
      failures that aborted before classification — recheck after a clean day
      and open a fresh item only if new ones appear.
- [x] **1d closed 2026-08-21:** hardened in place (`4904948`) rather than repointed —
      the two scripts serve different purposes (directory mirror vs single file),
      so `read/sh/rsync_mmb.sh` kept its args/semantics and gained the modern
      pattern: 600 temp key copy + `ssh -F /opt/resources/ssh/config` (strict,
      central known_hosts), replacing the inline accept-new. All 10 Philips
      collector IPs pre-verified present in known_hosts; first post-fix burst
      (13:28): **9/9 acquisitions successful, 9 systems, zero host-key errors** —
      identical results, now actually verified. Future unknown collectors fail
      loudly as `host_key_unknown` (1c) instead of being silently trusted.
      Original finding:
- [historical] **1d as found:** `jobs/philips_mri/rsync_philips-mri.js:82` invokes the legacy
      `./read/sh/rsync_mmb.sh`, which hardcodes `StrictHostKeyChecking=accept-new`
      and skips `-F /opt/resources/ssh/config` — and since the bundle mounts `:ro`,
      the accepted key is never persisted, so those hosts are blind-accepted every
      cycle (standing MITM exposure; also masks host-key gaps for Philips systems).
      Fix: repoint the job to the hardened `jobs/mmb/read/sh/rsync_mmb.sh` (arg
      orders differ — legacy `$1=user $2=ip $3=dest`, hardened
      `$1=sme $2=remote_path $3=dest $4=ip $5=user`), re-verify host-key coverage
      on the next burst, then delete the legacy script (annotated in place
      2026-08-20). Owner: Matt/Claude.

## 2. credential_decrypt failures on hhm (root cause known)

**Symptom:** ~128 decrypt errors/h; hhm pipeline succeeding for only 9 systems vs
134 on mmb. **Root cause (Matt, 2026-08-20): `run_scripts/update_db_creds.sh` was
not run after the migration** — the migrated credentials are still encrypted under
the old key.

- [x] **2a. Run `./run_scripts/update_db_creds.sh`** — done 2026-08-20 ~14:59 UTC
      after two script fixes (commit `44c303f`: run-logs mount for the
      RUN_ENV=staging logger; read via the PG_SSLMODE-aware pool instead of
      pgPool_old). Table snapshot taken first
      (`hhm_credentials-pre-reencrypt-20260820-1458.dump`); all 24 rows converted
      (uniform 32-char → 68–80-char ciphertext).
- [x] **2b. Verified on the 15:00 cycle (2026-08-20):** `credential_decrypt`
      errors 0 (was ~128/h); hhm succeeded for **65 distinct systems in one burst**
      vs 9 across the prior 17 h; remaining hhm errors are ordinary connectivity
      noise. Runbook addendum added as doc 2.1 **§5.7** (snapshot → convert →
      run-once warning → length check → verify), so the next seed can't repeat this.

## 3. Redis auth is now universal — retire the redis-STAGING exception

**Decision (Matt, 2026-08-20): staging is not special.** All four instances,
including `redis-STAGING`, now require AUTH (live since the 2026-08-19 rebuild).
This reverses the 2026-08-18 "permanently passwordless" decision recorded in
doc 2.1 and the audit briefs.

- [x] **3a. Commit the redis-admin changes** — done 2026-08-20: redis-admin
      `0e7d280` (staging.config include, compose auth mount + healthcheck, README,
      activate_redis_auth.sh with all-four AUTHED + odd-jobs/mmb-rpp on the
      propagation list + a skip-guard so a not-cloned app path can't abort a
      rotation mid-run). backup.sh's authenticated four-instance SAVE committed as
      pg_manage_v2 `0dee893` (Matt had already fixed it live — Aug 19/20 backups OK).
- [x] **3b. Update doc 2.1** — already done in `738dc1c` (pre-dated this item):
      STEP 3 table, auth paragraph + odd-jobs caveat, all-four verification loop,
      SECURITY BASELINE, FOLLOW-UPS #9 rewritten. Verified 2026-08-20.
- [x] **3c. odd-jobs auth coordination** — closed 2026-08-20: Matt talked with
      Jonathan; he is aware his apps must authenticate, and odd-jobs + mmb-rpp
      `.env`s are now on `activate_redis_auth.sh`'s propagation list (his `.env`
      updates on his side pending, per agreement). Residual watch: if his updates
      slip past the Sep 1 14:00 UTC `pg-part-arch` run, the partition watchdog
      (Sep 3) is the net.
- [x] **3d. Update standing references** — done 2026-08-20: audit prompt
      known-decisions bullet rewritten; session memory updated.

## 4. Interpreting the residual rsync noise + the history reset

Two separate things were bundled under "item 4" in the audit; neither is damage:

**4a. A stable set of dark systems.** ~2,750 of the rsync errors come from a fixed
set of systems (SME18353, SME20288, SME20292, SME20295, SME20296, …) failing at an
identical rate every cycle — machines the freshly-migrated prod inventory says to
poll, but which are unreachable (prod itself has carried systems dark since Jul 7).
This is **inventory-vs-reality drift, not a code or migration problem**: the
inventory now faithfully mirrors prod, including prod's stale entries. It is
doc 2.1 §5.5 (decision B0a) showing up in the error stream.

- [ ] **PARKED by owner 2026-08-21** — evidence is captured and waiting in
      `INVENTORY_RECONCILIATION_2026-08-21.md` (27 stable-failing systems in 7
      clusters with per-cluster recommendations, the four questions only Matt can
      answer, and the open B0a policy options). 1a folds in here (its 7-IP
      question = clusters B+C). Nothing is time-critical: the failures are
      steady-state noise (~1,500 events/day), all honestly classified since 1c,
      and the fleet's healthy majority is unaffected. When resumed: answer the
      worksheet's four questions, snapshot, then act per cluster.
      Owner: Matt (+ whoever owns prod inventory). No deadline.

**4b. The observability history reset (expected, one-time).** `util.app_run_logs`
now begins 2026-08-19 19:15. Anything that reads history restarted from zero:
ops-dashboard trends, incident-engine watermarks/baselines, and any before/after
comparison. Nothing to fix — just remember that "since when?" answers start at the
wipe, and that incident-engine dedup/aggregation state reset with the DB.

- [x] **4b closed 2026-08-21:** Matt re-provisioned per doc 2.1 §5.9 (password
      files recreated from `.env`s — they had never existed on this host — then
      the five role/schema scripts). Verified: grant matrix correct for all four
      roles (incl. the by-design shapes: reports_rw INSERT-not-SELECT,
      ops_dashboard_rw function-execute-only); `incidents` schema back (3
      tables); **first incident-engine run in 2 days succeeded at 13:25**
      (materialize from epoch watermark, 759 incidents assessed/written, zero
      errors). §5.9 rewritten as the complete as-executed sequence (`478b0aa`).
      Residual: ops-dashboard refresh is still blocked — but by item 5 below,
      not by grants. Original finding:
- [historical] **4b as found:** the reseed destroyed all three app
      roles' grants and the `incidents` schema (prod's DB never had it; roles
      survive but grants die with recreated objects — silently). Impact:
      **incident-engine failed every :25/:55 run for ~2 days** (`permission denied
      for schema util`, disk-logs only — it can't even self-log to the DB, which
      is why nothing showed red); **ops-dashboard served data frozen at
      2026-08-19 16:29** while returning 200s (`"stale":"last refresh failed:
      permission denied"` in its payload); **reports_rw** broken-but-latent (no
      schedule here). Fix = the four superuser commands now written up as
      **doc 2.1 §5.9** (incident-engine schema + owner-role first, then
      ops-dashboard readonly, then reports; stored /root/*_pw values reused so
      `.env`s stay valid; DB-03 caution on the reports script — non-transactional,
      read any midway error rather than re-running blind). Owner: **Matt** (sudo
      for the password files). Verify after: three `SET ROLE` probes pass, next
      incident-engine run logs an outcome, dashboard `asOf` goes current.

## 5. mmb-rpp writes NUL-poisoned JSON into util.app_run_logs (found 2026-08-21)

mmb-rpp (Jonathan's app, deployed to `/opt/apps/mmb-rpp` ~2026-08-19 20:27 with the
migration) logs raw machine-file excerpts — a `"reading"` field containing form-feeds
and `NUL` runs — into the shared `util.app_run_logs` (~4 rows/h, 235 rows so far).
Postgres' `json` type stores it, but consumers that extract those strings as text
throw `unsupported Unicode escape sequence`. **Impact today: ops-dashboard's refresh
fails on it** (dashboard frozen at 2026-08-19 16:29 even after the 4b grant fix —
payload says `"stale":"last refresh failed: unsupported Unicode escape sequence"`).
incident-engine proved immune (13:25 run scanned the full table cleanly). Rows stay
inside the dashboard's 30-day lookback until ~2026-09-19, so producer-side fixes
alone won't unfreeze it.

- [x] **5a. done 2026-08-21** — ops-dashboard `9d33d08`: `SAFE_JSON` conditional
      neutralizer (LIKE pre-check → replace the NUL escape with the
      replacement-char escape; same length, cast-safe) applied at every
      shared-table query's json SOURCE. Key discovery: on the `json` type even
      bare `->0` navigation throws on a poisoned value, so per-slice guards are
      impossible — sanitize the whole column first. Verified: full query battery
      passes over live poisoned rows; 171/171 tests; container restarted;
      **dashboard live again** (`asOf` current, `stale` gone, mmb-rpp on the
      grid honestly showing ERROR).
- [x] **5b. DROPPED (owner decision 2026-08-21)** — Jonathan's logger stays as-is;
      no coordination. Consequence accepted: mmb-rpp keeps writing NUL-poisoned
      rows (~4/h). 5a makes the dashboard immune; the poison is inert unless a
      future consumer extracts those json values without the SAFE_JSON guard —
      **any new consumer of `util.app_run_logs` must copy the pattern**.
- [x] **5c. done 2026-08-21** — one-time in-place cleanup: 57 `verbose_log` +
      57 `warn_error_logs` rows sanitized (same replacement-char substitution,
      cast-validated, one transaction), zero residual. Point-in-time only, per
      5b's drop — new poisoned rows accumulate again and that's accepted.

## 6. Dev/release paradigm pilot: data_acquisition (started 2026-08-24)

Aligning this app to the fleet paradigm (`docs/migration_CLAUDE.md`; reference =
mmb-rpp) as the pilot — other apps follow one at a time if it verifies. Owner: Matt.
Sequencing + manual-step map: `docs/MIGRATION-RUNBOOK-data_acquisition.md`.

- [x] **6a. Phase A+B done 2026-08-24** — paradigm docs committed, `STAGING_docker`
      pushed (was 19 ahead), live tree at `/opt/apps` FROZEN (old code, cron
      untouched); dev clone at `~/apps/data_acquisition` carries 10 alignment
      commits: entrypoint log-dir repair, `data-acqu:${USER_ID}` tags (IMAGE_TAG
      retired), LOG_DIR mount + fail-safe logger (RUN_ENV/RUN_LOGS_DIR/LOGGER
      retired for USER_ID+LOGGER_MODE — incl. the winston `logger.js`), SIGTERM/
      SIGINT graceful shutdown (E_SIGNAL, once-guarded), build.sh (in-tree
      node_modules; shared cache mount retired), build-release.sh (guard above
      wipe, #RELEASE transform, RELEASE_SHA stamp, extra tar excludes for ./logs
      93k files etc.), preflight-check.sh (authed Redis PING + sibling-container
      pg check), CLAUDE.md, proposed hardened crontab in `cron-bk/*.cron`.
- [x] **6b. Phase C mostly done 2026-08-24** — preflight 42 OK / 0 warn / 0 err;
      image `data-acqu:matt-teixeira` built; dev smoke (`offline_alert`) exit 0
      with `RELEASE_SHA=dev-tree`, log in-tree, `/opt/run-logs` untouched; guard
      negative-test refused a dirty tree. package-lock reformatted by npm 10
      (content-identical, verified by normalized md5) and committed.
- [x] **6c. done 2026-08-24** — `mmb 7` smoke (smallest group, 21 configs): outcome
      identical to production's own runs (same 4 stable-failing systems
      SME16377/16380/18352/21824, warn/error count in the normal band), winston adp
      log written with the USER_ID tag, DB row tagged `dev-tree`. SIGTERM mid-run:
      flush exactly once (1 row), fatal `E_SIGNAL`, honest exit 1. Note: a TERM
      landing in the entrypoint window (before node is PID 1) is silently dropped
      by bash-as-PID1 — the run then completes normally; acceptable (docker's
      stop-grace SIGKILL still bounds it; only the in-flight-flush guarantee needs
      node running). Owner also flagged **logger.js (winston) as deprecated in
      intent** — removal of it + its ~10 require sites folded into 6f.
- [x] **6d. done 2026-08-24 (evening)** — cutover complete. Discoveries en route:
      (1) the schedule never lived in svc's crontab — data_acquisition + hhm_rpp_* +
      incident-engine run from **matt-teixeira's USER crontab** (suspended wholesale
      via scripts/cron-suspend.sh; hardened restore file =
      `cron-bk/crontab.restore-2026-08-24.cron`); (2) the svc **HOME trap bites
      BuildKit**: first release died on `mkdir /nonexistent` — fixed with a private
      persistent `HOME=/opt/apps/.svc-home` (better than the reference's `HOME=/tmp`
      wart; mmb-rpp's own build-release.sh still carries that wart — tell Jonathan);
      (3) release verified: RELEASE_SHA=b93b3c1, USER_ID=svc, zero tree drift,
      release-copy preflight 0/0, svc smoke run logged `b93b3c1|svc` in the DB.
- [x] **6e. done 2026-08-24 21:05** — two full cycles verified from the DB: every
      family (hhm ×24, mmb 0–7 ×3 each, ip_reset ×9, offline_alert ×6, althea ×3,
      philips ×3) on `b93b3c1`, zero `dev-tree`; warn/error volumes match the
      pre-cutover baseline (hhm 263→295, ip_reset 483→505, mmb 352→354, philips
      6→6); incident-engine running clean. **One miss caught by the baseline
      diff:** `system_reset_totalizer` (18,48, old crontab line 84) was dropped
      from the first restore install — hardened entry added to the restore file;
      re-install pending (see 6g). CLAUDE.md banner removed; Scheduling section
      corrected to the user-crontab reality.
- [ ] **6g. Post-verify tail** — (1) Matt re-installs the updated restore
      crontab (picks up system_reset_totalizer; expect 24 entries); (2) one more
      `build-release.sh` when no data_acquisition container is running, to bring
      /opt/apps to the doc-closeout HEAD.
- [ ] **6f. Follow-ups** — dev VM `.env` needs `USER_ID` (+ retired keys removed)
      on next pull; prune-run-logs.sh covers neither `~/apps` dev logs nor
      `logs/` adp files (retention TBD); `app` compose service is deprecated,
      deletion descoped; dead `RUN_ENV` switches in `read/` cleanup candidate;
      register the dev clone's `.env` with the rotation script alongside the
      release copy's; **remove logger.js (winston — deprecated per owner
      2026-08-24) and its ~10 require sites**, folding anything useful into
      utils/logger — until then it stays functional (dirs auto-created,
      USER_ID tag); **consolidate the user-crontab schedules (this app,
      hhm_rpp_*, incident-engine) into the shared svc crontab** per the
      paradigm — coordinate with the boss, since his svc crontab has its own
      cadence-section organization.
- [x] **6h. Fleet rollout #2: monday — migrated 2026-08-25.** Same sequence as the
      pilot, one session: live tree frozen (CLAUDE.md banner) → dev clone
      `~/apps/monday` → 7 commits (entrypoint repairs `files/`+`data_outputs/`
      instead of log dirs — monday has NO file logger; `monday:${USER_ID}` tags,
      IMAGE_TAG + `.env` RUN_USER pin retired; build.sh in-tree deps, shared
      node_mod_cache mount retired; build-release.sh with guard-above-wipe +
      RELEASE_SHA stamp read by a boot console line, NOT a stats.job_runs column
      — shared-table schema deliberately left alone; SIGTERM/SIGINT → honest
      error row + exit 1, verified by kill test; preflight with authed
      sibling-container PG + read-only Monday.com `me` query, 46/0/0 both
      copies) → release 277df1d (zero drift, no gitignored bulk shipped) → svc
      smoke → **5 hardened entries installed in the shared svc crontab** (first
      paradigm app scheduled there; monday's old schedule had been deliberately
      stopped 2026-08-19, cadences reconstructed from stats.job_runs). Two-cycle
      verify green: all families on 277df1d, zero dev-tree, backlog drained
      (he_data caught up 144 items). Dead job new_avconn_tickets (since
      2026-04-21) not scheduled. PENDING: overnight verify of the two dailies
      (04:20/07:25 UTC, 2026-08-26) then banner-off + final doc re-release;
      register both monday `.env` copies with the rotation script (PGPASSWORD).
      **Next app in the queue: part-source-pipeline** (per doc 2.1 rollout
      order; monday was the blast-radius-lowest and is done).
- [x] **6i. Fleet rollout #3: part-source-pipeline — migrated 2026-08-25.** Same
      sequence, one session: `.env` backed up outside /opt/apps → live tree
      frozen (CLAUDE.md created WITH banner — the app had none) → dev clone
      `~/apps/part-source-pipeline` → 11 commits (entrypoint repairs `files/` +
      the log mount; `psp:${USER_ID}` tags, IMAGE_TAG + compose `RUN_USER: svc`
      pin retired; build.sh in-tree deps, shared node_mod_cache mount retired;
      build-release.sh with DEST hardcoded to the hyphen repo name — APP_NAME
      is the underscore container path, deriving would mis-release; LOG_DIR
      flip with fixed logger path + USER_ID filename tag, RUN_ENV retired;
      SKIP_SFTP=1 switch incl. compose passthrough — first smoke attempt showed
      compose drops undeclared vars; SIGTERM/SIGINT flush-once handlers,
      verified by kill test; preflight with authed sibling-container PG + HCA
      OData `$top=1` probe at 90s — Acumatica computes the inquiry before
      applying `$top`, 30s falsely failed; allowlist .dockerignore) → release
      68876cb (zero drift, tar excludes verified by listing, 51/0/0 preflight
      both copies) → svc smoke runs recorded in util.app_run_logs (the app's
      FIRST-EVER rows there — OPS-03's self-log had never run in production)
      with RELEASE_SHA=68876cb. **Schedule deliberately DORMANT** (owner
      decision 2026-08-25): no cron entries installed; pre-migration hourly
      hca_sync (stopped 2026-08-19) stays stopped; vendor SFTP keyless, so
      inv_feed_sync can only run with SKIP_SFTP=1. Rotation script already
      covers both `.env` copies (verified in-list + value-matched).
      **Next app in the queue: acumatica_sync** (per doc 2.1 rollout order).
- [x] **6j. Fleet rollout #4: acumatica_sync — migrated 2026-08-25.** Same
      sequence, one session: `.env` + pre-migration `acumatica_systems` dump
      backed up to `~/env-backups/` → live tree frozen (all branches verified
      pushed) → dev clone `~/apps/acumatica_sync` → 6 commits on
      STAGING_docker (CLAUDE.md banner-first — app had none, only a README +
      a markdown-in-.sh run doc, both rivals resolved; `acu-sync:${USER_ID}`
      tags, IMAGE_TAG + `.env` RUN_USER retired; in-tree deps, shared
      node_mod_cache mount retired; pointless `/opt/run-logs` container mount
      dropped — the app has NO file writers, so deps #1/#2 (log-dir repair /
      LOG_DIR flip) were N/A; deny-by-default .dockerignore; build-release.sh
      + boot line + **first-ever run record**: `stats.job_runs` rows, monday
      pattern, + SIGTERM/SIGINT kill-row handlers; preflight with authed
      sibling-container PG check, Acumatica presence-only per standing
      decision). Verified: preflight 36 OK/0 warn both copies; dev smoke
      `dev-tree` (5 real updates, table-dump diff exact); kill test wrote the
      error row, exit 1; dirty-tree refusal; tar-listing == git ls-files +
      .env; release smoke as svc (105:987) on `RELEASE_SHA=0e2a704`.
      **Stays UNSCHEDULED** (owner decision 2026-08-25, schedules.md already
      listed it as intentionally schedule-free). `.env` cleaned (dead keys +
      commented Azure passwords removed, owner-approved). Root-owned
      node_modules husk removed pre-release (the monday trap, dodged).
      Rotation script covers both copies (in-list + value-matched; dev clone
      picked up automatically by its ~/apps path glob).
      **Next app in the queue: hhm_rpp_siemens** (per doc 2.1 rollout order —
      NOTE: it consumes hhm_rpp_ge's shared `hhm_rpp:` image and has no
      Dockerfile of its own; per the shared-image caveat, decide the tag
      strategy with the ge/philips set before changing anything).
- [x] **6k. Fleet rollout #5: hhm_rpp_siemens — migrated 2026-08-25.** Same
      sequence, one session. Headline discovery: the app had **NEVER run on
      this box** — zero `util.app_run_logs` rows ever, `log.siemens_*` tables
      empty, no cron entry in ANY crontab — while data_acquisition fetched its
      source files every 30 min since June; so no freeze/suspend window and no
      DB baseline existed (verification was forward-predicted from config: 11
      CT + 1 MRI systems, SIEMENS_CV dead at 0 systems and kept dead by owner
      decision). Shared-image tag question resolved per the prior session's
      plan: compose keeps `hhm_rpp:${IMAGE_TAG}` byte-identical (documented
      transitional wart); ge's migration builds `hhm_rpp:svc` + `staging`
      alias, siemens flips in that cutover, philips retires the alias in its
      own. Consequence: **no entrypoint log-dir repair possible** (gosu
      entrypoint is baked in ge's image) — dep #1 landed host-side instead
      (build.sh + preflight create the dev log dir; missing dev LOG_DIR is a
      preflight ERROR here, not a warning). 9 commits on STAGING_docker
      (82c9f00..99d1230): CLAUDE.md banner-first (app had none; stale
      docs/run+setup.md deleted as rivals); build.sh deps-only + image
      presence check (no image build — deliberate deviation); one-commit
      LOG_DIR flip (variant-B logger's RUN_ENV switch removed — it wrote
      /opt/run-logs from ANY non-dev env, LOGGER→USER_ID, .json tag; dead
      `app` service deleted with owner sign-off: not on pg_net, could never
      reach PG); boot env_note fix (was logging 3 undefined legacy keys;
      note.argv untouched — ops-dashboard reads argv->>2); gracefulShutdown
      (kill-tested ×5: E_SIGNAL, exit 1, once-guard held); build-release.sh;
      preflight (44/0/0 both copies). Release `1bd5828`: zero drift, first
      `log.siemens_mri`/`log.siemens_ct` rows EVER (5,156 + 230,378 — the
      "backlog" was one day only; Application.log rotates daily). **2 hardened
      entries in the shared svc crontab** (`15,45`, CT `:15:55` / MRI `:16:05`,
      clear of the ge/philips user-crontab pileup at `:15:00`). Two-cycle
      verify green: both families ×2 on `1bd5828` as svc, zero dev-tree,
      steady-state warns = per-system "End of new data". Root-owned
      node_modules husk removed pre-release (monday trap, dodged again);
      rotation script already covers both `.env` copies. Post-cutover museum
      pile noted in its CLAUDE.md (utils/vpn etc., pm2, jobs/win_7, raw
      console.log dumps in job files reaching the bounded .out files).
      **Next app in the queue: hhm_rpp_ge** (shared-image OWNER: its
      build-release must produce `hhm_rpp:svc` AND tag the `staging` alias;
      siemens' reference flip + re-release belongs in that same cutover).

---

## Done

(move items here with date + one-line outcome)
