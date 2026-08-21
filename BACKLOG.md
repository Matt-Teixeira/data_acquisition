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
- [ ] **1d. Philips-MRI rsync bypasses the SSH choke point** (found 2026-08-20 while
      planning 1b): `jobs/philips_mri/rsync_philips-mri.js:82` invokes the legacy
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

- [ ] Reconcile: for each stable-failing system decide retired / temporarily dark /
      wrong IP, and either flag it out of polling in `public.systems` or fix its
      record. Snapshot first (pattern:
      `/opt/resources/backups/systems-flags-snapshot-<date>.txt`). This is also the
      natural moment to make the B0a call (named sync policy vs. manual-on-change
      with an owner), since staging inventory is momentarily in perfect sync with
      prod. Owner: Matt (+ whoever owns prod inventory).

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
and ` ` runs — into the shared `util.app_run_logs` (~4 rows/h, 235 rows so far).
Postgres' `json` type stores it, but consumers that extract those strings as text
throw `unsupported Unicode escape sequence`. **Impact today: ops-dashboard's refresh
fails on it** (dashboard frozen at 2026-08-19 16:29 even after the 4b grant fix —
payload says `"stale":"last refresh failed: unsupported Unicode escape sequence"`).
incident-engine proved immune (13:25 run scanned the full table cleanly). Rows stay
inside the dashboard's 30-day lookback until ~2026-09-19, so producer-side fixes
alone won't unfreeze it.

- [ ] **5a. Harden ops-dashboard's refresh** against ` ` in shared-table JSON
      (neutralize at text level before extraction, or skip-and-count poisoned
      rows). A shared-table consumer must not be crashable by one producer's
      data. Owner: Matt/Claude (ops-dashboard repo).
- [ ] **5b. Jonathan: sanitize the mmb-rpp logger** (strip/escape NUL before the
      DB insert — his vendored logger diverges from the fleet's on this). His
      app, hands off; Matt to coordinate.
- [ ] **5c. Optional one-time cleanup** of the existing poisoned rows (strip
      ` ` in place) once 5b lands — only needed if 5a chooses skip-rows
      rather than neutralize, or to make historical queries clean. DB state
      change; owner call.

---

## Done

(move items here with date + one-line outcome)
