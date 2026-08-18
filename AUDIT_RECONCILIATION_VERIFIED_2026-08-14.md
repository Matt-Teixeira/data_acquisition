# Verification & Reconciliation of the 2026-08-14 Audit

**Verifier:** Claude (independent live re-verification of `AUDIT_RECONCILIATION_FINDINGS_2026-08-14.md`)
**Date:** 2026-08-14 UTC
**Method:** Read-only checks against the live host, containers, database, Redis, crontab, git state, and source. Secret comparisons were equality-only; no credential value appears in this file. This file is the only artifact created.
**Goal context:** staging (`acq-vm-0`) is to become the golden image for dev/prod builds, with `docs/docker_server_full_setup_2.0.md` as the canonical instruction set.

## Bottom line

**Codex's report is accurate.** I independently re-verified every Critical and High finding I could test — roughly 30 distinct factual claims spanning credentials, permissions, Docker runtime state, database catalog state, Redis configuration, cron, and code-level bugs — and **every one held up**, several to the exact file:line and exact counts (16,374 acquisition files; 26 archive grants; 24 partitioned parents). The report's caveats are honest and its "unverified" labels are correctly placed.

Three material calibrations, two new facts, and one sequencing disagreement follow. None of them weakens the core conclusion: the guide cannot be reissued as-is, but the path to reissuing it is shorter than the report's full roadmap implies.

## Verification matrix

**Legend:** ✅ CONFIRMED = independently re-verified live. ☑️ SPOT-CONFIRMED = key elements re-verified, details accepted. ⚪ ACCEPTED = not re-tested; evidence in the report is specific and consistent with everything that was tested.

| Finding | Verdict | My evidence |
|---|---|---|
| SEC-01 committed superuser credential | ✅ CONFIRMED | Live `PGPASSWORD` (18 chars, `PGUSER=postgres`) appears verbatim at `data_acquisition/.env.example:102` and `hhm_rpp_{ge,philips,siemens}/.env.example:51`. Same value present in the live `.env` of acumatica_sync, all three RPPs, monday, part-source-pipeline, pg_manage_v2. reports does not contain it (uses `reports_rw`). |
| SEC-02 SFTP + URL credentials committed | ✅ CONFIRMED | Live `SFTP_PASS` matches `part-source-pipeline/.env.example:56`. `read/sh/Siemens/siemens_cerb_files_list.sh:1` contains an embedded `user:pass@` URL. |
| SEC-03 world-readable secrets/backups | ✅ CONFIRMED | All ten `.env` files `0664 matt-teixeira:docker`. `staging-20260727-1933.dump` 22.5 GB `0664`. All archived env files in `env-reconcile-20260806/staging/` `0664`. |
| SEC-05 pg password in Docker metadata | ✅ CONFIRMED | `pg_db` `Config.Env` contains key `POSTGRES_PASSWORD`; no `_FILE` variant, no secret mount. |
| SEC-06 TLS key readable by dd-agent | ✅ CONFIRMED | `pg_ssl.key` is `0600` owned `999:987`; `getent passwd 999` → `dd-agent`. |
| SEC-08 credentials into logs/mail | ✅ CONFIRMED | `ge_mri_22.sh` runs `set -euxo pipefail` with `password="$3"` (xtrace echoes it). `old_to_new_process.js:37-38,64-65` prints decrypted and new credential objects. Mail spool 403 MB. |
| SEC-11 PG on all interfaces | ✅ CONFIRMED + new fact | 5432 listening on `0.0.0.0` and `[::]`. **New:** the VM's single NIC has **no Azure public IP** (see Calibration 1). |
| SEC-12 acqu_files other-readable | ✅ CONFIRMED | 16,374 files (exact count match), **zero** are non-other-readable. |
| SEC-04 writable source / docker group | ☑️ SPOT-CONFIRMED, calibrated | Group-writable RW mounts confirmed by design; legacy `app` service in data compose is stock `node:lts` on `redis_net` only. See Calibration 3 on "root-equivalent". |
| SEC-07/09/10, REL-04 | ⚪ ACCEPTED | Consistent with verified state (`.dockerignore` absent in data_acquisition and hhm_rpp_ge, the two repos that build images; guide lines 552/692 do use `-v pw=`; guide line 612 documents the group-read key). |
| REDIS-01 published, unauthenticated, drifted | ✅ CONFIRMED | Ports 6379–6382 bound on empty HostIp; `protected-mode no`; ACL `default on nopass ~* &* +@all`; anonymous `/dev/tcp` PING from host → `+PONG`. Current compose has **no** `ports:` blocks; containers created 2026-07-27; the no-ports commit (`138b106`, authored 2026-05-18) merged into the deployed line 2026-07-28 (`3151159`). Runtime matches neither source nor a secure design. |
| REDIS-02 kernel prereqs | ✅ CONFIRMED | `vm.overcommit_memory=0`, THP `[always]`. |
| REDIS-03/05 client lifecycle, restore order | ⚪ ACCEPTED | REDIS-05's logic matches the guide's own AOF warning (lines 246–250 vs 278–281 contradiction is real on its face). |
| DB-01 partition wall 2026-10-01 | ⚠️ Facts confirmed; **conclusion corrected same day — see Addendum** | Exactly 24 partitioned parents; **every** max upper bound is `2026-10-01`; **zero DEFAULT partitions exist anywhere**; no partition job in the *readable* crontab or timers. **Correction:** maintenance exists in `odd-jobs` (excluded from audit scope), scheduled from the root-only `svc` crontab; its Aug 1 run created all 24 September partitions. The residual risk is a silent single point of failure, not an approaching wall. |
| DB-03 reports_rw grant drift | ✅ CONFIRMED (archive side) | Exactly 26 direct grants in archive schemas: 4 `archive_alert`, 4 `archive_edu`, 18 `archive_mag`. Missing-child-grant side accepted. |
| DB-04 no health/limits, OOM retained | ✅ CONFIRMED | `OOMKilled=true`, Healthcheck NONE, `Memory=0`, `PidsLimit=nil`. |
| DB-05 saved_files 130 GB | ✅ CONFIRMED | `pg_total_relation_size('log.saved_files')` = 130 GB, ~317k rows (est). |
| DB-06 observability off | ✅ CONFIRMED | `shared_preload_libraries` is empty. |
| DB-02/07/08 | ⚪/☑️ | `DST_SSLROOTCERT` confirmed dead (in `.env`, zero source references). Rest accepted. |
| OPS-01 backups not scheduled | ✅ CONFIRMED | No backup/prune lines in crontab; no relevant systemd timers; only backup set is 2026-07-27. The scripts have sat ready in `/opt/resources/scripts/` since 2026-07-27, never installed. |
| OPS-02 log pruning / Docker rotation | ✅ CONFIRMED | `daemon.json` absent; `pg_db` LogConfig `json-file` with empty (unbounded) config; `prune.log` single run 2026-07-27. |
| OPS-03 error-bearing runs / false success | ☑️ SPOT-CONFIRMED | Aggregates accepted; the mechanism is verified in code: `data_acquisition/index.js:75-77` silently ignores unknown run groups, and the `onBoot` catch (114–120) logs the error but never sets a nonzero exit code. |
| OPS-04 cron mail | ✅ CONFIRMED | Spool 403 MB; monthly trim uses predictable `/tmp/mailtrim`. |
| OPS-05 run-log dirs unwritable | ✅ CONFIRMED | `/opt/run-logs/{data_acquisition,hhm_rpp_ge,hhm_rpp_philips,hhm_rpp_siemens}` are `2755 root:root`. Masked because every staging `.env` sets `RUN_ENV=dev`. This is the known deferred pair from the 2026-08-06 reconciliation — fix together. |
| OPS-07 time sync | ✅ **UPGRADED TO PASS** | `timedatectl`: clock synchronized, NTP service active (Codex could not verify this; it is fine). |
| REL-02 compose interpolation | ✅ CONFIRMED | monday warns on `$G`/`$format` (uses `env_file` → real corruption); part-source warns `$format` ×10 (uses `env_file` → real corruption); acumatica warns `$expand`/`$format` (no `env_file` → cosmetic). |
| REL-07 hard-coded host facts in examples | ✅ CONFIRMED | `DOCKER_GID=987`, `UID_0=105`, `UID_1=1001`, `UID_2=1006`, `IMAGE_TAG=staging` are tracked in the `.env.example` of data_acquisition, hhm_rpp_ge, monday, part-source-pipeline — exactly the values the 2026-08-06 host-identity convention says must come from the host. |
| Monday misconfiguration | ✅ CONFIRMED | `.env:10` `PGDATABASE=dev`; cluster contains only `postgres`/`staging`; `PG_SSL_PATH` duplicated (2×); compose `env_file` at line 4. |
| Part-source missing dir | ✅ CONFIRMED | `files/` missing; `jobs/sync-inv-feed.js:73-74` writes `../files/<name>` → guaranteed ENOENT. Note: guide line 727 **does** create it — this is live drift from the doc, not doc staleness. |
| Philips code defects | ✅ CONFIRMED | `minValue.js:83` is `if ((sme = "SME15816"))` — assignment, always truthy, clobbers `sme`; its catch (111–118) calls `addLogEvent`/`E`/`cat` which are **not imported** in that file → ReferenceError masks the original error. `get_monitor_delta.sh:10` unconditionally runs a second extraction from hard-coded `2023-04-29\t02:10:48`; line 8 splices `$1` into the awk program text. |
| Doc staleness (branch map, build matrix) | ✅ CONFIRMED | All eight app repos on `STAGING_docker`; pg_manage_v2 and redis-admin on `STAGING`. Guide says `DEV_docker` (data, acumatica) and `DEV` (redis-admin). Builds are now compose-owned everywhere: `acu-sync:${IMAGE_TAG}`, `hhm_rpp:${IMAGE_TAG}` (GE compose:63-66), `aux:${IMAGE_TAG}` (reports docker-compose.**yml**:43-45), `monday:${IMAGE_TAG}`, `psp:${IMAGE_TAG}`. Guide's matrix (lines 577–588), acumatica "do not build" text, and RPP "no build: section" text are all stale. Only philips/monday have upstreams configured. |
| Schedules aligned | ☑️ SPOT-CONFIRMED | 45 installed cron job lines vs 46 in `docs/schedules.md` by pattern count (delta is the commented acquisition-v2 rollback line). Substantively aligned, as reported. |
| Git history attributions, npm audit counts, log-volume counts, context sizes, REL-08 external-credential inventory | ⚪ ACCEPTED | Specific, internally consistent, and every neighboring testable claim proved exact. |

## Calibrations (where I'd adjust Codex, not overturn it)

**1. Network exposure is VNet-internal, not internet-facing.** Azure IMDS shows this VM has **one NIC and no public IP**. So the unauthenticated Redis instances, PG 5432, and dashboard 8080 are reachable from the VNet/peered networks/VPN — not from the internet (barring an LB NAT rule, which IMDS gives no sign of; NSG and root-only iptables remain unread, same limitation Codex had). This downgrades REDIS-01/SEC-11 from "assume internet-exposed, contain in 0–24h" to "fix in the next planned window, this week." It does **not** make them okay: any VNet host and any container on the shared bridges can reach full-privilege Redis anonymously, and the runtime-vs-source drift means a naive `docker compose up -d` someday would be a *surprise* config change. Recreate deliberately, soon.

**2. Credential rotation is mandatory but can be a planned change, not an incident.** The four repos carrying the superuser password are personal private-remote repos (`github.com/Matt-Teixeira/...`), the DB is not internet-reachable, and the exposure audience is repo collaborators, clones, cron mail, and anything that read the world-readable files. Rotate this week in one coordinated pass (all 9 keys / 8 apps, interactive `\password`, terminate pre-rotation sessions), scrub the five `.env.example` lines and the Siemens one-liner, and only then decide on history rewriting. Codex's ordering (rotate **before** git surgery) is correct and important.

**3. "svc in docker group is root-equivalent" is technically true but the practical path is narrow.** `svc` is nologin and exists only as an in-container UID; app containers do not mount the Docker socket, so gid 987 inside a container confers file access, not daemon access. The real design smell is using the docker group as a general file-sharing group. Fix it as deliberate 2.1 design work (dedicated runtime group), not as containment.

**4. DB-01 outranks everything else on the calendar.** Given calibrations 1–2 soften the security emergencies, the hardest-dated item in the whole report is the partition wall: **47 days out, zero DEFAULT partitions as a net, and it takes down run-logging (`util.app_run_logs`) and offline alerting (`alert.*`) at the same instant it takes down data ingest.** Codex listed it fifth; operationally it is co-#1 with credential rotation. *(Superseded the same day — see the Addendum: the maintenance exists in odd-jobs and worked on Aug 1; the calendar emergency stands down to a silent-failure watch item.)*

**5. Sequencing of the doc reissue.** Codex says revise the guide only after the environment is contained and reconciled. Agreed in spirit — but the branch map and build matrix are wrong *today*, which blocks any dev/prod build attempt regardless of security posture. The right read: do the Week-1 list below, then reissue as 2.1 immediately; don't gate the doc on the full 30-day roadmap (roles fleet rollout, CI, hardening), which belongs in the doc's FOLLOW-UPS section as tracked debt.

## New facts Codex did not have

1. **No Azure public IP** on the only NIC (Calibration 1).
2. **NTP is healthy** — `timedatectl` reports synchronized, service active. OPS-07's open question is closed.
3. **Five stale `docker compose run` leftovers** are running right now: `imprivata-poc-app_tools-run-*` ×3 (up 4 weeks) and `ops-dashboard-app-run-*` ×2 (up 7 weeks). Excluded apps, but they sit on the shared host and the ops-dashboard ones may hold DB connections. Remove them and add a "no stale `run-` containers" check to acceptance.
4. **Zero DEFAULT partitions** across all 24 parents (Codex inferred none "as a general mechanism"; it is now confirmed as exactly zero).
5. **`util.app_run_logs` and `alert.*` are among the 24 expiring parents** — the sharpest consequence of DB-01 (see Calibration 4).

## Reconciled action sequence

### Week 1 — stop the clocks (live state)

1. **Partition horizon** *(superseded — see Addendum)*: partition maintenance already exists in `odd-jobs` and worked on Aug 1. Do **not** build a competing manager or pre-create partitions unilaterally. Instead: confirm ownership with the odd-jobs owner, stand up a read-only next-month-horizon watchdog, and verify October's partitions in early September.
2. **Credential rotation** (one coordinated pass): rotate the shared `postgres` password; update 9 keys across 8 apps; terminate pre-rotation backend sessions; smoke each app. Rotate the part-source SFTP account and the Siemens URL account. Scrub the five committed example/script literals. Add a pre-commit/CI secret scan. History rewrite is a separate later decision.
3. **Redis reconcile**: after `backup.sh` runs once by hand, recreate the four containers from the current no-ports compose; persist `vm.overcommit_memory=1` and THP disablement; decide now whether ACL/auth ships with this change or as a documented follow-up — the doc must record whichever is chosen.
4. **Install the ops cron** that has been waiting since 2026-07-27: `backup.sh` + `prune-run-logs.sh` lines from `proposed-crontab-additions.txt`; apply `daemon.json.proposed` in a quiet window; run the guide's restore test once and record it.
5. **Unbreak the manual apps**: monday `PGDATABASE=staging` + collapse duplicate keys; create part-source `files/` (guide line 727 — live drift); fix `$` fidelity for monday/part-source (escape `$$` in env files or move URI keys out of compose's `env_file` path; verify bytes inside a container).
6. **Staging identity pair-fix** (deferred since 2026-08-06): `chgrp docker` + `g+w` the four root:root run-log dirs, then flip staging `.env`s to `RUN_ENV=staging`. Do not do one without the other.

### Week 2 — repo fixes, then reissue the doc as 2.1

7. Philips: fix `minValue.js:83` assignment + missing catch imports; delete/parameterize `get_monitor_delta.sh:10`; move `exec` → `execFile`/fs APIs on the injection surfaces. data_acquisition: unknown run group → error, catch → `process.exitCode = 1`. Add `.dockerignore` to data_acquisition and hhm_rpp_ge (the two image-building repos).
8. Recreate `pg_db` from a tracked compose definition with `POSTGRES_PASSWORD_FILE`, a healthcheck, and a decided key-delivery mechanism that avoids the uid-999/dd-agent collision (or explicitly document dd-agent as inside the trust boundary).
9. **Reissue `docker_server_full_setup_2.0.md` → 2.1** with: corrected branch map (STAGING_docker ×8, STAGING ×2) and upstreams; the 2026-08-06 host-identity axis (uid/gid/tag from untracked `.env`, no ARG defaults — and change tracked examples to placeholders per REL-07); the compose-owned build matrix (acu-sync, monday, psp, aux←reports, hhm_rpp←GE); rewritten Redis section (no host ports, kernel prereqs, auth decision, AOF-safe restore per REDIS-05); declarative pg_db with password file; `\password` instead of `-v pw=`; partition-lifecycle section with acceptance query; backups/pruning as **required, installed** steps with restore evidence; RUN_ENV semantics per host; expanded-but-pragmatic acceptance gate (secret scan clean, zero compose warnings + `$` fidelity, UID-105 write smoke per declared mount, partition horizon ≥ 3 months, backup age < 25 h + rehearsed restore, no stale `run-` containers, pg password-file assertion, reboot test).

### Tracked debt (goes in 2.1 FOLLOW-UPS, does not block reissue)

Role-per-app rollout with fail-closed `verify-full` (the doc's existing checklist stands; reports archive-grant reconciliation folds into the partition lifecycle); secret-file mode policy + dedicated runtime group (needs the acumatica bind-mount design decision); `log.saved_files` retention program per DB-05 (batched, monitored — never one big DELETE); image pinning/lockfiles/CI/SBOM; pg observability (`pg_stat_statements` preload at next planned restart) and OOM investigation; external-endpoint/prod-credential manifest (REL-08); mail-spool redaction/retention; off-host encrypted backup target (`/mnt/sdd` is a different disk but the same host — it is a staging area, not an answer); history rewrite decision after rotation.

## What this changes about the "golden image" plan

Staging can be the model, but today it models three different things at once: the doc (2026-07-27), the repos (moved on 2026-07-28 and 2026-08-06), and the runtime (partly created before both). The Week-1 list collapses runtime onto the repos; the Week-2 list collapses the doc onto both. After that, "clone the doc" and "clone staging" mean the same thing — which is the property prod and dev need.

## Addendum — 2026-08-14 (post-report): DB-01's conclusion corrected

Prompted by the owner's caution that the excluded `odd-jobs` app "does database stuff like partitions," a follow-up read-only check found that **partition maintenance exists and works — it lives in `odd-jobs`**, a colleague-owned app both audits were instructed to exclude, and its schedule sits in the **`svc` account's crontab**, which neither audit could read (root-only). Evidence:

- `odd-jobs/jobs/pg-part-arch.js` (deployed copy) actively executes both `add_pg_table_partitions` and `archive_partitions` SQL — the blocks are not commented out.
- The 2026-08-01 14:00 UTC run log (`/opt/run-logs/odd-jobs/`) records "Table partitions added successfully" and "Partitions archived successfully," then enumerates **exactly the 24 `*_2026_09` partitions** this report verified in `pg_class`.
- `alert.detections_2026_08` and `_2026_09` have later relfilenodes (856661, 894786) than the restore-era partitions (566003–566027) — created in separate, later batches, matching a monthly cadence.
- Five `archive_*` schemas hold 300+ archived monthly partitions — the archive half of the same job, and the mechanism behind DB-03's grant drift.
- A warning in odd-jobs' own CLAUDE.md (dated Jul 24) that the released job "performs no actual partition maintenance" is stale: it predates the Jul 28 redeploy, and the Aug 1 outcome proves the deployed code works.

**Corrected conclusion:** "all bounds end 2026-10-01" is the normal steady state of a build-next-month-on-the-1st system observed in mid-August — not an approaching wall. The **residual risk is real but different**: a one-month horizon maintained by a job that fails silently (cron output discarded; per odd-jobs' own to-do notes it does not exit nonzero on failure), with zero DEFAULT partitions as a net. A single missed month-start run still produces the fleet-wide outage this report described — one month later than predicted.

**Disposition (boundary-respecting; odd-jobs is out of bounds for us):** confirm ownership with its owner; add an independent read-only horizon watchdog; verify October's partitions in early September; and remove `data_acquisition`'s stale May-26 vendored copy of the partition SQL, which helped mislead both audits.

**Lesson for the acceptance gate:** a "no maintenance job is scheduled" claim must enumerate **every** account's crontab (which requires root) before it may be asserted.
