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

- [ ] **1a. Clear the current backlog of 11** — obtain each host's key from a source
      that already trusts it (the prod server's `known_hosts` is the natural one),
      verify, append to `/opt/resources/ssh/known_hosts`. Owner: Matt.
      Policy guardrail stands (doc 2.1, SHARED SSH BUNDLE): never blind
      `ssh-keyscan` against production endpoints.
- [ ] **1b. Write the standing procedure** into doc 2.1's SHARED SSH BUNDLE section:
      what to do when a *new system/host* enters the inventory (single-host case)
      and when an *inventory migration* lands (bulk case — diff the inventory's IPs
      against `known_hosts` BEFORE the first cron cycle, so this failure class is
      caught pre-emptively instead of discovered as 900 errors). Owner: Matt/Claude.
- [ ] **1c. Fix error classification** — the failure is logged into
      `alert.offline_mmb_conn` as `connection_error='rsync connection closed by
      peer'`, `error_category='connection_reset'`, which points an operator at the
      network rather than at SSH trust. The rsync stderr contains the real cause.
      Improvements: (i) classify `Host key verification failed` / `No … host key is
      known` as its own category (a `host_key_changed` category already exists —
      add the "unknown key" sibling, e.g. `host_key_unknown`); (ii) propagate the
      informative stderr line into `connection_error`; (iii) coverage: 138 of 172
      rows in the last 17 h have NULL `error_category` — the classifier misses most
      events entirely. Owner: Claude (code), data_acquisition mmb error path.

## 2. credential_decrypt failures on hhm (root cause known)

**Symptom:** ~128 decrypt errors/h; hhm pipeline succeeding for only 9 systems vs
134 on mmb. **Root cause (Matt, 2026-08-20): `run_scripts/update_db_creds.sh` was
not run after the migration** — the migrated credentials are still encrypted under
the old key.

- [ ] **2a. Run `./run_scripts/update_db_creds.sh`** from the repo root in a quiet
      window (it deletes any stray repo-local `node_modules/`, then runs
      `npm ci && npm run update_db_creds` in a tmpfs container — nothing lands on
      the host). Owner: Matt.
- [ ] **2b. Verify after:** decrypt errors go to zero in `util.app_run_logs`
      (`func LIKE '%credential_decrypt'`), and hhm distinct successful systems in
      `stats.acquisition_history` climbs from 9 toward fleet size within a few
      cycles. Post-migration this step belongs in the migration runbook — add
      "re-encrypt credentials" to doc 2.1 STEP 5's post-seed checklist so the next
      migration doesn't repeat this. Owner: Matt (verify), doc edit with 1b.

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

- [ ] One-time sanity check that incident-engine re-materialized cleanly against
      the fresh `util.app_run_logs` (its :25/:55 runs are succeeding — confirm its
      incidents look sane, no re-materialization weirdness). Owner: Matt/Claude.

---

## Done

(move items here with date + one-line outcome)
