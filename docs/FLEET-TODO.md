# Fleet TODO — post-migration work queue

Working list, kept current as items close. Created 2026-08-27, after the
dev/release paradigm migration completed for all 12 repos (BACKLOG 6, doc
2.1 header). Sources: doc 2.1 FOLLOW-UPS, `FLEET-FINDINGS.md` (the other
fleet's findings), BACKLOG 6p/6r tails, and the 2026-08-27 audit session.

Conventions: `[ ]` open · `[x]` done (date + evidence) · owner in **bold**.
An item that needs a *decision* says so — don't fix those unilaterally.

---

## 1 — Dated / this week

- [ ] **1a. pg_manage_v2 closeout** (BACKLOG 6p) — **Matt + session**, expected
      2026-08-28 am. Evidence to check: release-copy backup smoke's `OK` line,
      then two nightly `backup.log` lines ending `sha=03b1a1a`. Then: banner
      off in `~/apps/pg_manage_v2/CLAUDE.md`, closeout re-release
      (`bash ~/apps/pg_manage_v2/build-release.sh`), tick BACKLOG 6p.
      The watchdog's Sep 3 tick reports on its own clock — read it (see 1c).
- [ ] **1b. redis-admin banner-off** (BACKLOG 6r) — **Matt + session**,
      expected 2026-08-28. Evidence: two clean cron cycles of the consuming
      apps (data_acquisition + hhm_rpp trio in `util.app_run_logs` — no
      Redis-connection errors since the 7bd34e1 apply) plus tonight's
      `backup.log` line showing all four Redis SAVEs verified. Then: banner
      off in `~/apps/redis-admin/CLAUDE.md`, closeout release, tick 6r.
- [ ] **1c. 2026-09-01 14:00 UTC — `pg-part-arch` plumbing run** — **Jonathan**
      (odd-jobs, svc crontab); coordination **Matt**, BEFORE the 1st.
      Verified 2026-08-27: September partitions all exist, zero malformed
      suffixes on staging — the run tests only plumbing (cron, docker, auth,
      logging), which is exactly what failed silently on 08-01.
      - Ask Jonathan: does pg-part-arch touch Redis? redis-STAGING has auth
        since 2026-08-19 and an unauthenticated client fails NOAUTH (doc 2.1
        follow-up 9).
      - After the run: October partitions exist (watchdog query, doc 2.1
        PARTITION MAINTENANCE). The independent watchdog fires Sep 3 09:00 —
        actually read `/opt/run-logs/pg_manage_v2/` + partition-watchdog.log.
      - Diagnostic to remember: `no partition of relation ... found for row`
        in ANY app = this job failed or hasn't run.
- [ ] **1d. Release queue — make the 2a pool standard (and this week's
      preflight/build.sh commits) live**: `bash ~/apps/<app>/build-release.sh`
      for data_acquisition, monday, part-source-pipeline, acumatica_sync,
      hhm_rpp_ge, hhm_rpp_siemens, hhm_rpp_philips, reports,
      incident-engine, ops-dashboard (service — its release restarts the
      container). No urgency order; each app's "Release currency" preflight
      warning clears as its release lands. pg_manage_v2 and redis-admin
      release with their 1a/1b closeouts.

## 2 — Fleet decisions — ALL DECIDED 2026-08-27 (Matt): our fleet decides on
##     its own needs; alignment with the other fleet is their choice.

- [x] **2a. Pool standard: `connectionTimeoutMillis: 10000`, `max: 15`,
      `idleTimeoutMillis: 60000`** — DECIDED + IMPLEMENTED 2026-08-27, as
      its own pass (deliberately NOT tied to the roles arc). 11 pool files
      across 10 repos (8 vendored pg-pool.js + ops-dashboard's ro/writer
      pair + acumatica's pg_pool.js), byte-identical block after
      `ssl: buildSsl(),`. Safety pre-checked: every run-once app ends its
      pool or exits explicitly, so 60s idle cannot extend run tails.
      Verified through the real file: unreachable host errors at ~10.5s
      (was infinite hang); real pg_db connect 150ms.
      **REMAINING: each app's next release makes it live** — see the
      release queue note at the bottom of §1.
- [ ] **2b. `stamp_compress.sh` — REFRAMED (Matt): refactor, not retire.
      Proposal DRAFTED 2026-08-27** —
      `docs/stamp-compress-refactor-proposal.md`: extend prune-run-logs.sh
      with a daily bundle stage (per-day tar.gz in
      `/opt/run-logs/<app>/archive/`, ~15× compression measured, 2.7 GB /
      20k loose files today), 180-day bundle retention, flock, idempotent;
      no per-app copies. **Awaiting Matt's call on the 5 decision points
      at the bottom of the proposal**, then ~60 lines + dry-run verify.
- [x] **2c. `build.sh`: `env_val` is our standard** — SETTLED 2026-08-27
      (already shipped in all 12 repos; pilot straggler fixed cb890f3).
      Whether the other fleet adopts it is their call.
- [x] **2d. `MIGRATION-HANDOFF.md` access — DROPPED** (Matt, 2026-08-27):
      not pursuing access or their evaluations. FLEET-FINDINGS.md stays as
      the only artifact from their effort we consult.

## 3 — Quick wins (session can do; no decision needed)

- [x] **3a. "Release is N commits behind" preflight check** — DONE
      2026-08-27, all 12 repos, byte-identical block before each Summary
      (data_acquisition `0bec5a2` … redis-admin `48b75be`, all pushed).
      Dev tree: warns with commit count behind + uncommitted-work note;
      release copy: asserts its RELEASE_SHA stamp exists. Proved itself on
      first run: data_acquisition's release is 21 commits behind (mostly
      docs — but includes the build.sh env_val fix; re-release at next
      convenience clears the warn).

## 4 — Orphan cleanup (mechanical; needs sudo/operator or explicit go)

- [ ] **4a. `/opt/resources/node_mod_cache/*`** — orphaned since the
      migrations (no compose file references the cache; verified
      2026-08-27). `sudo rm -rf /opt/resources/node_mod_cache` after a
      last `grep -r node_mod_cache /opt/apps/*/docker-compose.yaml` returns
      only comments.
- [ ] **4b. `aux:staging` image** — retired by reports' migration (doc 2.1
      follow-up 10); `docker rmi aux:staging`.
- [x] **4c. `schedules.md` sync** — DONE 2026-08-27: rewritten from live
      `crontab -l` (50 entries, count verified block-vs-crontab). Now
      records the hardened invocation pattern, flock-installed overlap
      protection, the corrected no-schedule list (monday/siemens are in the
      svc crontab; reports/psp/acumatica dormant by decision), and the svc
      crontab pointer.

## 5 — Next big arc: DB roles rollout (doc 2.1 Phase 4a + 4b)

- [ ] **5a–5g.** Seven apps still connect as `PGUSER=postgres` with
      unverified TLS (verified 2026-08-27). Order (blast radius, low→high):
      monday → part-source-pipeline → acumatica_sync → hhm_rpp_siemens →
      hhm_rpp_ge → hhm_rpp_philips → data_acquisition. Per app (doc 2.1
      DATABASE ROLES checklist): enumerate reads/writes → `db/setup-role.sql`
      from the closest template (incident-engine owner / ops-dashboard
      readonly / reports read-mostly) → fail-closed pg-pool (copy from
      reports) + `PG_SSLMODE=verify-full` + ssl mount → apply via
      password-file pattern → swap `.env` creds → smoke grants before the
      next scheduled run. Fold the 2a pool-timeout values into the same
      vendored-file touch once decided. One app at a time, soak between.

## 6 — Backlog (real, not pressing — doc 2.1 FOLLOW-UPS keeps the full list)

- [ ] **6a. Cron consolidation** (data_acquisition BACKLOG 6f) — move
      user-crontab schedules (data_acquisition, ge, philips,
      incident-engine) into the shared svc crontab. Its own project;
      single-writer discipline per FLEET-FINDINGS §7.
- [ ] **6b. Phase 4 remainder** — cron mail cleanup (4h), external-endpoint
      inventory (4i), systems-inventory sync policy (B0a), off-host backups
      (blocked on decision D4), version pinning + CI secret scanning (4e),
      PROD readiness (4j, unblocked once doc 2.1 passes acceptance).
- [ ] **6c. FLEET-FINDINGS §5 merge traps** — applies whenever a
      pre-migration branch gets merged (nearest case: redis-admin's stale
      `PROD` branch). Before any such merge:
      `git diff --name-status <base> origin/<branch>` and look for ADDS that
      replace modified files.
- [ ] **6d. reports dependabot alerts** — GitHub flagged 27 vulnerabilities
      on reports' default branch at the 2026-08-27 push (1 critical,
      13 high): github.com/Matt-Teixeira/reports/security/dependabot.
      Triage per FLEET-FINDINGS §4 (verify reachability before bumping —
      their fleet found lodash/uuid advisories unreachable and `pg-promise`
      the one worth fixing). Feeds Phase 4e (version pinning + CI).

---

## Done (this effort — evidence in BACKLOG 6 and doc 2.1)

- [x] 2026-08-24→27 — **dev/release paradigm migration, all 12 repos**
      (BACKLOG 6a–6r; doc 2.1 header).
- [x] 2026-08-27 — doc 2.1 full audit vs live server (`de7cddc`…`139077c`).
- [x] 2026-08-27 — `hhm_rpp:staging` alias retired (ge `fabd749`, tag
      deleted; follow-up 15 first item).
- [x] 2026-08-27 — FLEET-FINDINGS quick fixes: data_acquisition build.sh
      `env_val` (`cb890f3`); masking widened to `*TOKEN*|*KEY*` in all 10
      preflights with display loops (pg_manage_v2/redis-admin print no
      values by design); incident-engine flush verified already-correct.
- [x] 2026-08-27 — FLEET-FINDINGS §3 DB checks run on staging: zero
      malformed partition suffixes; September partitions all present.
- [x] 2026-08-27 — hhm_rpp_philips closeout (BACKLOG 6q): full-day
      verification passed, banner off `3a2c0ec`, closeout release run by
      Matt — `/opt/apps` carries `RELEASE_SHA=3a2c0ec`.
- [x] 2026-08-27 — all repos pushed (16 commits, 10 repos, zero ahead).
