# Job Schedules — acq-vm-0

**This file is the canonical schedule manifest.** It documents the live crontab as of
2026-08-18 (maintenance lines added 08-17/18). The old `cron-jobs.txt` (mixed legacy `/home/prod` paths) is retired to
`docs/attic/`. A snapshot of the installed crontab is kept at
`/opt/resources/backups/crontab-<date>.txt` (re-snapshot before every edit).

- **Owner:** the crontab belongs to the `matt-teixeira` user (`crontab -l` / `crontab -e`
  as that user). Cron runs from `$HOME`, so every entry `cd`s into the app dir first —
  compose needs the compose file in the working directory.
- **Invocation pattern:** every job is a one-shot
  `docker compose run --rm <service> bash -lc "npm run <job>"` (or `node index.js <job>`
  for incident-engine) against a pre-warmed node_modules cache. Jobs do **not** run
  `npm ci` — the cache is warmed once at setup (see the setup guide) and after
  dependency changes.

## Stagger design

Minute offsets keep job families off each other's DB/Redis load peaks:

| Slot | Family |
|---|---|
| :00/:30 | data_acquisition HHM pulls (ge/philips/siemens × ct/cv/mri) |
| :58/:28 | data_acquisition `philips_mri_mmb` |
| :10/:40, :17/:47, :20/:50 | data_acquisition `ip` (VPN reset) |
| :15/:45 | data_acquisition `offline_alert`; GE + Philips RPP families (with 5s `sleep` staggering inside the minute) |
| :16/:46 | data_acquisition MMB `schedule_1..7` + `althea_env` (1s sleep stagger) |
| :19/:49 | data_acquisition `schedule_0` (offset) |
| :22/:52 | data_acquisition `offline_alert` (second pass) |
| :18/:48 | data_acquisition `system_reset_totalizer` |
| :25/:55 | incident-engine `run` (after producer bursts finish ~:21/:51) |
| :05/:35 | hhm_rpp_philips `delete_old_db_files` — saved_files 48 h retention (DB-05, restored 2026-08-18; clear of the :00/:30 burst, the :10/:40 VPN reset, and the :15/:45 writers into that table) |
| 03:30 nightly | run-log prune (`/opt/apps/data_acquisition/scripts/prune-run-logs.sh`) |
| 02:15 nightly | backups (`/opt/apps/pg_manage_v2/scripts/backup.sh`) |
| 09:00 on the 3rd & 25th | partition-horizon watchdog (`/opt/apps/pg_manage_v2/scripts/check-partition-horizon.sh`) |
| 03:00 monthly (1st) | trim cron-mail spool to last 100 MB |

> Maintenance scripts live in the repo that owns their subject (decided 2026-08-18):
> database scripts in `pg_manage_v2/scripts/`, redis scripts + host-setup files in
> `redis-admin/`, cross-app run-log prune here in `data_acquisition/scripts/`.
> `/opt/resources/scripts/` is no longer a script home.

## Apps with NO schedule on this box (intentional)

`hhm_rpp_siemens`, `acumatica_sync`, `monday`, `reports`, `part-source-pipeline`,
`ops-dashboard` (long-running service, not cron), `imprivata-poc` (PoC, manual runs).

**acquisition-v2** is the strangler-fig replacement for data_acquisition. Its
`system_reset_totalizer` cron line was **rolled back 2026-07-13** (paused); the line is
kept commented in the crontab for re-cutover. Until then data_acquisition owns that job.

## incident-engine runs from its release copy (worktree retired 2026-08-26)

The incident-engine entry runs from `/opt/apps/incident-engine`, which is release
output produced only by `build-release.sh` in `~/apps/incident-engine` — same guarantee
the old `/opt/apps/incident-engine-deploy` worktree gave (a `git checkout` in the dev
tree can never change what cron executes), plus the clean-tree guard and `RELEASE_SHA`
provenance. The entry is hardened (absolute paths, `flock -n`, `-T`, bounded
`cron.run.out`) at the unchanged :25/:55 cadence.

## Overlap protection (optional hardening — not installed)

No entry currently uses `flock`; a run that outlasts its 30-minute cadence would overlap
with the next. If pile-ups are ever observed (`docker ps` showing stacked `*-run-*`
containers), wrap entries like:

```cron
00,30 * * * * cd /opt/apps/data_acquisition && flock -n /tmp/cron-ge_ct.lock docker compose run --rm app_tools bash -lc "npm run ge_ct"
```

`-n` skips the run instead of queueing it — correct for these half-hourly idempotent pulls.

## Install / rollback

```bash
crontab -l > /opt/resources/backups/crontab-$(date +%Y%m%d-%H%M).txt  # snapshot first
crontab -e                                                            # edit
crontab /opt/resources/backups/crontab-<date>.txt                     # rollback = restore snapshot
```

## Live crontab (verbatim, 2026-08-18)

```cron
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command

## HHM DATA ACQUISITION
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run ge_ct"
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run ge_cv"
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run ge_mri"
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run philips_ct"
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run philips_cv"
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run philips_mri" 
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run siemens_ct"  
00,30 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run siemens_mri"
58,28 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run philips_mri_mmb"
10,40 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run ip"
15,45 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run offline_alert"

# MMB DATA ACQUISITION
16,46 * * * * sleep 30; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_1"
16,46 * * * * sleep 31; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_2"
16,46 * * * * sleep 32; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_3"
16,46 * * * * sleep 33; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_4"
16,46 * * * * sleep 34; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_5"
16,46 * * * * sleep 35; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_6"
16,46 * * * * sleep 36; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_7"
16,46 * * * * sleep 38; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run althea_env"
# RESET VPN
17,47 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run ip"
# OFFSET
19,49 * * * * sleep 30; cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run schedule_0"
# OFFSET - RESET VPN
20,50 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run ip"
# OFFLINE ALERT
22,52 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run offline_alert"

# GE RPP
15,45 * * * * cd /opt/apps/hhm_rpp_ge && docker compose run --rm app_tools bash -lc "npm run ge_ct"
15,45 * * * * cd /opt/apps/hhm_rpp_ge && docker compose run --rm app_tools bash -lc "npm run ge_cv"
15,45 * * * * cd /opt/apps/hhm_rpp_ge && docker compose run --rm app_tools bash -lc "npm run ge_mri"

# PHILIPS RPP
15,45 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_ct"
15,45 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_cv"

15,45 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_monitor_1"
15,45 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_monitor_2"
15,45 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_monitor_3"
15,45 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_monitor_4"
15,45 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_monitor_5"

15,45 * * * * sleep 5; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_rmmu_1"
15,45 * * * * sleep 10; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_rmmu_2"
15,45 * * * * sleep 15; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_rmmu_3"
15,45 * * * * sleep 20; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_rmmu_4"
15,45 * * * * sleep 25; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_rmmu_5"

15,45 * * * * sleep 30; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_log_1"
15,45 * * * * sleep 35; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_log_2"
15,45 * * * * sleep 40; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_log_3"
15,45 * * * * sleep 45; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_log_4"
15,45 * * * * sleep 50; cd /opt/apps/hhm_rpp_philips && docker compose run --rm app_tools bash -lc "npm run philips_mri_log_5"

# AUX JOBS
18,48 * * * * cd /opt/apps/data_acquisition && docker compose run --rm app_tools bash -lc "npm run system_reset_totalizer"
# ROLLED BACK 2026-07-13 — acquisition-v2 paused; totalizer runs from data_acquisition (line above). v2 line kept commented for re-cutover.
# 18,48 * * * * cd /opt/apps/acquisition-v2 && docker compose run --rm app_tools bash -lc "npm run system_reset_totalizer"
# SAVED_FILES RETENTION (48 h) — restored 2026-08-18, plan item 8b / audit DB-05.
05,35 * * * * cd /opt/apps/hhm_rpp_philips && docker compose run --rm -T app_tools bash -lc "npm run delete_old_db_files"


# Monthly: trim cron-mail spool to last 100MB (added 2026-07-10, see acquisition-v2 session)
0 3 1 * * tail -c 100000000 /var/mail/matt-teixeira > /tmp/mailtrim && cat /tmp/mailtrim > /var/mail/matt-teixeira && rm -f /tmp/mailtrim

# incident-engine: deterministic error->incident pipeline, one `run` line =
# materialize (L0) then assess (aggregate). Half-hourly at :25/:55 — just after
# the producer bursts finish (~:21/:51), so it never piles onto their DB load.
# materialize and assess serialize on a shared watermark lock, so a single
# sequential `run` is deliberate: two staggered lines would only block each other.
# Added 2026-07-16 (Phase 3; see /opt/apps/incident-engine/markdown/DEPLOYMENT.md).
25,55 * * * * cd /opt/apps/incident-engine-deploy && docker compose run --rm app node index.js run

# --- maintenance jobs (installed 2026-08-17, plan-of-attack steps 1+3) ---
# backup entry hardened 2026-08-26 (pg_manage_v2 migration): bounded .out
# instead of /dev/null. The watchdog entry's MISSING redirect is deliberate —
# its stdout ALERT becomes cron mail, which is the alert channel.
15 2 * * * /opt/apps/pg_manage_v2/scripts/backup.sh >/opt/run-logs/pg_manage_v2/cron.backup.out 2>&1
30 3 * * * /opt/apps/data_acquisition/scripts/prune-run-logs.sh >/dev/null 2>&1
0 9 3,25 * * /opt/apps/pg_manage_v2/scripts/check-partition-horizon.sh
```

## The svc crontab (root-only; odd-jobs partition maintenance)

A second schedule exists outside the block above: the `svc` service account's
crontab carries odd-jobs' `pg-part-arch` (partition create/archive) at 14:00 UTC
on the 1st — owned by Jonathan, readable only via `sudo crontab -l -u svc`.
See the setup doc's PARTITION MAINTENANCE section (audit A21-08).
