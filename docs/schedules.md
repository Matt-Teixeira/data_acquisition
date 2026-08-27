# Job Schedules — acq-vm-0

**This file is the canonical schedule manifest.** It documents the live
matt-teixeira crontab as of **2026-08-27** — the fully hardened post-paradigm
state (data_acquisition entries replaced 2026-08-24; hhm_rpp_ge, hhm_rpp_philips
and the maintenance entries hardened 2026-08-26). A schedule that is not in this
file does not exist; keep it in sync with `crontab -l`. Snapshots of the
installed crontab live at `/opt/resources/backups/crontab-<date>.txt`
(re-snapshot before every edit); per-app restore files live in each repo's
`cron-bk/`.

- **Owner:** the crontab belongs to the `matt-teixeira` user (`crontab -l` /
  `crontab -e`). Every entry `cd`s into the app's **release copy**
  (`/opt/apps/<app>`) — compose needs the compose file in the working
  directory, and cron must never run a dev tree.
- **Invocation pattern (hardened, fleet paradigm):** absolute
  `/usr/bin/docker` + `/usr/bin/flock`, `flock -n` per job (skip, never
  queue), `-T` under cron, direct `node index.js <argv>` (no npm-run
  indirection — argv[2] is the job label ops-dashboard reads), output to a
  bounded `>/opt/run-logs/<app>/cron.<job>.out`, no `RUN_USER` (entrypoint
  defaults to svc), no `HOME`.
- Verify any schedule from the app's run record (`util.app_run_logs` /
  `stats.job_runs`), never from cron's own logs. Production rows read
  `svc | <RELEASE_SHA>`; a `dev-tree` row on a schedule means cron is
  running the wrong copy.

## Stagger design

Minute offsets (plus in-minute `sleep` staggers) keep job families off each
other's DB/Redis load peaks:

| Slot | Family |
|---|---|
| :00/:30 (+0–35s sleeps) | data_acquisition HHM pulls (GE/Philips/Siemens × CT/CV/MRI) |
| :58/:28 | data_acquisition `philips` (Philips MRI MMB rsync) |
| :10/:40, :17/:47, :20/:50 | data_acquisition `ip_reset` (VPN reset; one shared lock) |
| :15/:45 | data_acquisition `offline_alert`; GE RPP (0/20/40s sleeps); Philips RPP (18 entries, 0–50s sleeps) |
| :16/:46 (+30–38s sleeps) | data_acquisition `mmb 1..7` + `althea_env` |
| :19/:49 | data_acquisition `mmb 0` (offset) |
| :22/:52 | data_acquisition `offline_alert` (second pass) |
| :18/:48 | data_acquisition `system_reset_totalizer` |
| :25/:55 | incident-engine `run` (after producer bursts finish ~:21/:51) |
| :05/:35 | hhm_rpp_philips `delete_old_files` — saved_files 48 h retention (DB-05; clear of the :00/:30 burst, the :10/:40 VPN reset, and the :15/:45 writers) |
| 02:15 nightly | backups (`/opt/apps/pg_manage_v2/scripts/backup.sh`, bounded .out) |
| 03:30 nightly | run-log prune (`/opt/apps/data_acquisition/scripts/prune-run-logs.sh`) |
| 09:00 on the 3rd & 25th | partition-horizon watchdog (`check-partition-horizon.sh`; its stdout is cron MAIL on purpose — that is the alert channel) |
| 03:00 monthly (1st) | trim cron-mail spool to last 100 MB |

> Maintenance scripts live in the repo that owns their subject (2026-08-18):
> database scripts in `pg_manage_v2/scripts/`, redis scripts + host-setup in
> `redis-admin/`, the cross-app run-log prune in `data_acquisition/scripts/`.

## Apps with NO schedule in this crontab

- **In the SHARED SVC CRONTAB instead** (root-readable: `sudo crontab -l -u
  svc`; fleet standing decision — new/rebuilt schedules go there):
  **monday** (5 entries, restored 2026-08-25), **hhm_rpp_siemens**
  (`15,45` — CT `:15:55`, MRI `:16:05`; SIEMENS_CV dead by config), plus
  Jonathan's odd-jobs `pg-part-arch` (14:00 UTC on the 1st) and his other
  apps' entries.
- **Deliberately dormant** (owner decisions, see each app's CLAUDE.md):
  `reports` (report families email real customers — smoke only at
  non-matching minutes), `part-source-pipeline` (stopped 2026-08-19),
  `acumatica_sync` (no schedule by design).
- **Not cron-shaped:** `ops-dashboard` (long-running service),
  `pg_manage_v2` (its two jobs ARE the maintenance lines below),
  `redis-admin` (no jobs), `imprivata-poc` (manual PoC).
- **acquisition-v2** — paused strangler-fig; its totalizer line stays
  commented for re-cutover (rolled back 2026-07-13); data_acquisition owns
  the job meanwhile.

## incident-engine runs from its release copy (worktree retired 2026-08-26)

The incident-engine entry runs from `/opt/apps/incident-engine`, release
output produced only by `build-release.sh` in `~/apps/incident-engine` —
same guarantee the old `/opt/apps/incident-engine-deploy` worktree gave (a
`git checkout` in the dev tree can never change what cron executes), plus
the clean-tree guard and `RELEASE_SHA` provenance.

## Overlap protection (INSTALLED — 2026-08-24/26 hardening)

Every entry wraps its job in `flock -n /tmp/<app>.<job>.lock`: a run that
outlasts its cadence makes the next tick **skip** (never queue) — correct
for idempotent pulls, and required where a cursor advances after insert
(RPP families would double-process on overlap). The three `ip_reset` entries
share one lock on purpose (the job is the same reset).

## Install / rollback

```bash
crontab -l > /opt/resources/backups/crontab-$(date +%Y%m%d-%H%M).txt  # snapshot first
crontab -e                                                            # edit
crontab /opt/resources/backups/crontab-<date>.txt                     # rollback = restore snapshot
# (Installing from a file is safe for THIS personal crontab only. The shared
#  svc crontab is single-writer, edited ONLY via `sudo crontab -u svc -e` —
#  never installed from a file.)
```

## Live crontab (verbatim, 2026-08-27 — 50 active entries)

```cron
# matt-teixeira USER crontab — post-cutover restore (2026-08-24).
# = the suspended crontab (cron-bk/crontab.bak) with data_acquisition's 24 legacy
# entries replaced by the hardened block below. Everything else (hhm_rpp_ge,
# hhm_rpp_philips, incident-engine, mail trim, pg backups, prune, partition check)
# is preserved VERBATIM in its original slot.
#
# Install (own crontab, so installing from a file is safe here):
#   crontab /opt/apps/data_acquisition/cron-bk/crontab.restore-2026-08-24.cron
# Verify:  crontab -l | grep -v '^ *#' | grep -c 'cd /opt/apps/data_acquisition'   -> expect 24
#
# NOTE: the fleet paradigm wants all app schedules in the shared svc crontab
# (organized by cadence). data_acquisition (+ hhm_rpp_*, incident-engine) has
# historically lived HERE instead; consolidating into svc's crontab is a separate
# follow-up (BACKLOG 6f), not part of this cutover.

# ---------------- DATA_ACQUISITION (hardened 2026-08-24; runs release copy as svc) ----------------
# Same cadences/offsets as the legacy entries; adds flock -n, -T, absolute paths,
# direct node argv (identical to the old npm-run mapping), bounded .out files,
# 5s stagger across the 8 same-minute HHM entries.

# HHM (GE / Philips / Siemens)
00,30 * * * * sleep 0  && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.ge_ct.lock       /usr/bin/docker compose run --rm -T app_tools node index.js hhm null GE CT       >/opt/run-logs/data_acquisition/cron.ge_ct.out 2>&1
00,30 * * * * sleep 5  && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.ge_cv.lock       /usr/bin/docker compose run --rm -T app_tools node index.js hhm null GE CV       >/opt/run-logs/data_acquisition/cron.ge_cv.out 2>&1
00,30 * * * * sleep 10 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.ge_mri.lock      /usr/bin/docker compose run --rm -T app_tools node index.js hhm null GE MRI      >/opt/run-logs/data_acquisition/cron.ge_mri.out 2>&1
00,30 * * * * sleep 15 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.philips_ct.lock  /usr/bin/docker compose run --rm -T app_tools node index.js hhm null Philips CT  >/opt/run-logs/data_acquisition/cron.philips_ct.out 2>&1
00,30 * * * * sleep 20 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.philips_cv.lock  /usr/bin/docker compose run --rm -T app_tools node index.js hhm null Philips CV  >/opt/run-logs/data_acquisition/cron.philips_cv.out 2>&1
00,30 * * * * sleep 25 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.philips_mri.lock /usr/bin/docker compose run --rm -T app_tools node index.js hhm null Philips MRI >/opt/run-logs/data_acquisition/cron.philips_mri.out 2>&1
00,30 * * * * sleep 30 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.siemens_ct.lock  /usr/bin/docker compose run --rm -T app_tools node index.js hhm null Siemens CT  >/opt/run-logs/data_acquisition/cron.siemens_ct.out 2>&1
00,30 * * * * sleep 35 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.siemens_mri.lock /usr/bin/docker compose run --rm -T app_tools node index.js hhm null Siemens MRI >/opt/run-logs/data_acquisition/cron.siemens_mri.out 2>&1

# MMB + althea_env
16,46 * * * * sleep 30 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb1.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 1 >/opt/run-logs/data_acquisition/cron.mmb1.out 2>&1
16,46 * * * * sleep 31 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb2.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 2 >/opt/run-logs/data_acquisition/cron.mmb2.out 2>&1
16,46 * * * * sleep 32 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb3.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 3 >/opt/run-logs/data_acquisition/cron.mmb3.out 2>&1
16,46 * * * * sleep 33 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb4.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 4 >/opt/run-logs/data_acquisition/cron.mmb4.out 2>&1
16,46 * * * * sleep 34 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb5.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 5 >/opt/run-logs/data_acquisition/cron.mmb5.out 2>&1
16,46 * * * * sleep 35 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb6.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 6 >/opt/run-logs/data_acquisition/cron.mmb6.out 2>&1
16,46 * * * * sleep 36 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb7.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 7 >/opt/run-logs/data_acquisition/cron.mmb7.out 2>&1
16,46 * * * * sleep 38 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.althea_env.lock /usr/bin/docker compose run --rm -T app_tools node index.js althea_env >/opt/run-logs/data_acquisition/cron.althea_env.out 2>&1
# OFFSET — mmb group 0 keeps its own slot (carried over from the legacy schedule)
19,49 * * * * sleep 30 && cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.mmb0.lock /usr/bin/docker compose run --rm -T app_tools node index.js mmb 0 >/opt/run-logs/data_acquisition/cron.mmb0.out 2>&1

# Philips MRI MMB rsync
58,28 * * * * cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.philips_mri_mmb.lock /usr/bin/docker compose run --rm -T app_tools node index.js philips >/opt/run-logs/data_acquisition/cron.philips_mri_mmb.out 2>&1

# System reset totalizer
# (Missed in the first restore install — caught 2026-08-24 21:05 by the baseline
#  comparison: 24 legacy entries, 23 hardened. Re-install this file to pick it up.)
18,48 * * * * cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.totalizer.lock /usr/bin/docker compose run --rm -T app_tools node index.js system_reset_totalizer >/opt/run-logs/data_acquisition/cron.system_reset_totalizer.out 2>&1
# ROLLED BACK 2026-07-13 — acquisition-v2 paused; totalizer runs from data_acquisition (line above). v2 line kept commented for re-cutover.
# 18,48 * * * * cd /opt/apps/acquisition-v2 && docker compose run --rm app_tools bash -lc "npm run system_reset_totalizer"

# VPN reset (three historical slots, ONE shared lock so resets never overlap) + offline alert
10,40 * * * * cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.ip_reset.lock /usr/bin/docker compose run --rm -T app_tools node index.js ip_reset >/opt/run-logs/data_acquisition/cron.ip_reset.1040.out 2>&1
17,47 * * * * cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.ip_reset.lock /usr/bin/docker compose run --rm -T app_tools node index.js ip_reset >/opt/run-logs/data_acquisition/cron.ip_reset.1747.out 2>&1
20,50 * * * * cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.ip_reset.lock /usr/bin/docker compose run --rm -T app_tools node index.js ip_reset >/opt/run-logs/data_acquisition/cron.ip_reset.2050.out 2>&1
15,45 * * * * cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.offline_alert.lock /usr/bin/docker compose run --rm -T app_tools node index.js offline_alert >/opt/run-logs/data_acquisition/cron.offline_alert.1545.out 2>&1
22,52 * * * * cd /opt/apps/data_acquisition && /usr/bin/flock -n /tmp/data_acquisition.offline_alert.lock /usr/bin/docker compose run --rm -T app_tools node index.js offline_alert >/opt/run-logs/data_acquisition/cron.offline_alert.2252.out 2>&1

# ---------------- GE RPP (hardened 2026-08-26, cadence unchanged) ----------------
# Direct argv (argv[2] identical to the old npm-run mapping — ops-dashboard label
# unchanged); flock -n because the Redis cursor advances after insert (overlap
# would double-insert); 20s stagger; bounded single-> .out files.
15,45 * * * * sleep 0  && cd /opt/apps/hhm_rpp_ge && /usr/bin/flock -n /tmp/hhm_rpp_ge.ge_ct.lock  /usr/bin/docker compose run --rm -T app_tools node index.js GE_CT  >/opt/run-logs/hhm_rpp_ge/cron.ge_ct.out 2>&1
15,45 * * * * sleep 20 && cd /opt/apps/hhm_rpp_ge && /usr/bin/flock -n /tmp/hhm_rpp_ge.ge_cv.lock  /usr/bin/docker compose run --rm -T app_tools node index.js GE_CV  >/opt/run-logs/hhm_rpp_ge/cron.ge_cv.out 2>&1
15,45 * * * * sleep 40 && cd /opt/apps/hhm_rpp_ge && /usr/bin/flock -n /tmp/hhm_rpp_ge.ge_mri.lock /usr/bin/docker compose run --rm -T app_tools node index.js GE_MRI >/opt/run-logs/hhm_rpp_ge/cron.ge_mri.out 2>&1

# ---------------- PHILIPS RPP (hardened 2026-08-26, cadence + sleep offsets unchanged) ----------------
# Direct argv (argv[2] identical to the old npm-run mapping — ops-dashboard label
# unchanged; log_* keep --max-old-space-size=4096); flock -n (Redis cursors
# advance after insert — overlap would double-process); -T, absolute paths,
# bounded single-> .out files.
15,45 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_ct.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_CT >/opt/run-logs/hhm_rpp_philips/cron.philips_ct.out 2>&1
15,45 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_cv.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_CV >/opt/run-logs/hhm_rpp_philips/cron.philips_cv.out 2>&1
15,45 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_monitor_1.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_MONITOR_1 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_monitor_1.out 2>&1
15,45 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_monitor_2.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_MONITOR_2 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_monitor_2.out 2>&1
15,45 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_monitor_3.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_MONITOR_3 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_monitor_3.out 2>&1
15,45 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_monitor_4.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_MONITOR_4 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_monitor_4.out 2>&1
15,45 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_monitor_5.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_MONITOR_5 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_monitor_5.out 2>&1
15,45 * * * * sleep 5 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_rmmu_1.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_RMMU_1 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_rmmu_1.out 2>&1
15,45 * * * * sleep 10 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_rmmu_2.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_RMMU_2 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_rmmu_2.out 2>&1
15,45 * * * * sleep 15 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_rmmu_3.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_RMMU_3 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_rmmu_3.out 2>&1
15,45 * * * * sleep 20 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_rmmu_4.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_RMMU_4 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_rmmu_4.out 2>&1
15,45 * * * * sleep 25 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_rmmu_5.lock /usr/bin/docker compose run --rm -T app_tools node index.js PHILIPS_MRI_RMMU_5 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_rmmu_5.out 2>&1
15,45 * * * * sleep 30 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_log_1.lock /usr/bin/docker compose run --rm -T app_tools node --max-old-space-size=4096 index.js PHILIPS_MRI_LOG_1 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_log_1.out 2>&1
15,45 * * * * sleep 35 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_log_2.lock /usr/bin/docker compose run --rm -T app_tools node --max-old-space-size=4096 index.js PHILIPS_MRI_LOG_2 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_log_2.out 2>&1
15,45 * * * * sleep 40 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_log_3.lock /usr/bin/docker compose run --rm -T app_tools node --max-old-space-size=4096 index.js PHILIPS_MRI_LOG_3 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_log_3.out 2>&1
15,45 * * * * sleep 45 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_log_4.lock /usr/bin/docker compose run --rm -T app_tools node --max-old-space-size=4096 index.js PHILIPS_MRI_LOG_4 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_log_4.out 2>&1
15,45 * * * * sleep 50 && cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.philips_mri_log_5.lock /usr/bin/docker compose run --rm -T app_tools node --max-old-space-size=4096 index.js PHILIPS_MRI_LOG_5 >/opt/run-logs/hhm_rpp_philips/cron.philips_mri_log_5.out 2>&1
05,35 * * * * cd /opt/apps/hhm_rpp_philips && /usr/bin/flock -n /tmp/hhm_rpp_philips.delete_old_db_files.lock /usr/bin/docker compose run --rm -T app_tools node index.js delete_old_files >/opt/run-logs/hhm_rpp_philips/cron.delete_old_db_files.out 2>&1

# ---------------- INCIDENT ENGINE (hardened 2026-08-26; runs release copy as svc, cadence unchanged) ----------------
25,55 * * * * cd /opt/apps/incident-engine && /usr/bin/flock -n /tmp/incident-engine.run.lock /usr/bin/docker compose run --rm -T app node index.js run >/opt/run-logs/incident-engine/cron.run.out 2>&1

# ---------------- HOST MAINTENANCE (preserved verbatim) ----------------
0 3 1 * * tail -c 100000000 /var/mail/matt-teixeira > /tmp/mailtrim && cat /tmp/mailtrim > /var/mail/matt-teixeira && rm -f /tmp/mailtrim
15 2 * * * /opt/apps/pg_manage_v2/scripts/backup.sh >/opt/run-logs/pg_manage_v2/cron.backup.out 2>&1
30 3 * * * /opt/apps/data_acquisition/scripts/prune-run-logs.sh >/dev/null 2>&1
0 9 3,25 * * /opt/apps/pg_manage_v2/scripts/check-partition-horizon.sh
```

## The svc crontab (root-only)

A second schedule exists outside the block above: the `svc` service
account's crontab (readable only via `sudo crontab -l -u svc`) carries the
fleet's svc-scheduled apps — monday's 5 entries and hhm_rpp_siemens' CT/MRI
entries (blocks recorded in each app's CLAUDE.md) — alongside Jonathan's
odd-jobs, including `pg-part-arch` (partition create/archive) at 14:00 UTC
on the 1st. See the setup doc's PARTITION MAINTENANCE section (A21-08).
Single-writer resource: sequence edits, count entries before/after.
