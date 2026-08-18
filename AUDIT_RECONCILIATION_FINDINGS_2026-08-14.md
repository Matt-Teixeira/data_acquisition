# Application Suite and Docker Server Audit / Reconciliation

**Audit date:** 2026-08-14 UTC  
**Reference:** `docs/docker_server_full_setup_2.0.md` (909 lines; last reconciled in-file on 2026-07-27)  
**Scope:** `acumatica_sync`, `data_acquisition`, `hhm_rpp_ge`, `hhm_rpp_philips`, `hhm_rpp_siemens`, `monday`, `part-source-pipeline`, `pg_manage_v2`, `redis-admin`, and `reports`, plus the shared PostgreSQL, Redis, Docker, cron, backup, logging, filesystem, and host controls on which they depend.  
**Explicit exclusions:** `odd-jobs`, `imprivata-poc`, `incident-engine`, `incident-engine-deploy`, `ops-dashboard`, `acquisition-v2`, and other ad hoc applications were not audited as applications. Shared infrastructure effects were considered where they affect an in-scope app.  
**Change policy:** This was a read-only investigation. No app, database, container, schedule, credential, Git ref, firewall, or host configuration was changed. This untracked report is the only file created, so the Data Acquisition worktree is no longer clean solely because of this requested artifact.

> **Secret-handling note:** No credential value is reproduced in this report. Credential checks used key names, equality-only comparisons, or redacted metadata. The committed values described below must be treated as compromised even though they are not printed here.

> **Report-artifact note:** The final report file is restricted to mode `0640`. It contains sensitive topology and exploit-path metadata. Because Data Acquisition currently has no `.dockerignore`, this requested root-level report is eligible build-context material until the context policy is fixed; do not build or transmit that context unintentionally.

## Executive verdict

The current suite is functioning in meaningful parts, but `docker_server_full_setup_2.0.md` is **not yet a secure, reproducible one-stop server build**. It accurately describes much of the intended topology, UID/GID model, Docker versions, PostgreSQL TLS, network names, application image names, and canonical application schedule. However, it is behind the repositories and live runtime in several places, leaves security-critical controls as proposals or follow-ups, and does not test several failure modes that are already present.

The most urgent conclusions are:

1. **A valid shared PostgreSQL superuser credential is committed in four repositories and configured across eight applications.** A fifth repository, Part Source Pipeline, commits its currently configured SFTP password, and additional URL credentials are present in current or reachable Data Acquisition history. Rotation/revocation must precede Git-history cleanup.
2. **All ten live `.env` files are mode `0664`; archived environment files and the only PostgreSQL dump are also world-readable.** The guide's default ACL/umask design permits and perpetuates other-readable file creation.
3. **All four Redis instances currently publish unauthenticated, full-privilege endpoints on every IPv4/IPv6 interface.** Current source intends no host ports, so live containers are unreconciled with the repo. External reachability is not proven because host firewall and Azure NSG policy could not be read.
4. **Backups and log pruning are not scheduled.** The only backup set is from 2026-07-27, is local to the same root filesystem as Docker data, and has not been restored in a rehearsal.
5. **All 24 partitioned PostgreSQL parents run out of future partitions at 2026-10-01 00:00 UTC.** No maintenance job is installed; the available SQL only creates one month and is not safely idempotent.
6. **Philips raw-file retention is not installed and `log.saved_files` has grown to 130 GB.** A one-shot delete would itself be operationally risky and should not be used as the first response.
7. **Confirmed app correctness failures exist now:** Monday targets a nonexistent `dev` database; Monday and part-source URLs are changed by Compose `$` interpolation; the part-source output directory is absent; Philips has date-parser, historical replay, error-masking, command-injection, and dynamic-SQL defects on scheduled paths.
8. **Job success reporting cannot be trusted consistently.** Several apps catch failures and exit zero, while recent database logs show error/warning events in every scheduled GE and Philips run and most Data Acquisition runs.

The guide should be revised only after the live environment is contained and deliberately reconciled. Updating prose alone would otherwise normalize unsafe runtime state.

## Severity and disposition

| Severity | Meaning in this report |
|---|---|
| Critical | Active credential compromise, unauthenticated administrative data access, or immediate fleet-wide compromise potential. Contain now. |
| High | Likely data loss, security breach, imminent availability failure, or routine false-success behavior. Correct in the next controlled maintenance window. |
| Medium | Material reliability, maintainability, auditability, or reproducibility weakness. Plan and track. |
| Low / documentation | Stale or confusing state that can produce future drift but has limited current impact. |

Finding status terms:

- **Runtime drift:** live state differs from the repository's intended state.
- **Document stale:** the reference differs from current, deliberate repository behavior.
- **Missing control:** neither the reference nor current implementation safely covers the requirement.
- **Aligned:** inspected state matches the reference and passed the stated check.
- **Unverified:** access, tools, or a safe non-mutating test were unavailable.

## Immediate containment plan (0–24 hours)

Execute these as one coordinated incident/change, with a rollback owner and a timestamped record:

1. **Pause affected schedules temporarily and inventory every consumer of the exposed credentials.** The confirmed shared PostgreSQL credential appears in nine configured environment keys across eight apps: Acumatica Sync, Data Acquisition, all three RPP apps, Monday, Part Source Pipeline, and `pg_manage_v2`. Reports uses a different restricted role.
2. **Rotate/revoke before editing Git.** Prefer new least-privilege app roles. If containment cannot wait for role design, rotate the shared PostgreSQL role fleet-wide, then migrate away from it. Set the database password interactively with `psql \password` or an approved protected secret workflow so it does not enter shell history or process arguments. Update the server-side rebuild secret too; changing `POSTGRES_PASSWORD_FILE` alone does not change an initialized database role.
3. **Atomically replace protected environment files** and verify both confidentiality and intended readability. Use `0600` for host-only Compose inputs. Acumatica currently reads a bind-mounted `.env` as UID 105, so migrate it to protected secret injection or temporarily use `0640` with a dedicated non-Docker runtime group and a read smoke test. Before rotation, record a cutoff and affected-role backend PIDs; rotate, update consumers, immediately terminate all pre-rotation sessions for that role, then establish fresh `verify-full`/grant/job smokes and resume schedules. PostgreSQL cannot tell which password authenticated an already-established session, and password rotation alone does not terminate it.
4. **Rotate the Part Source SFTP account and every exposed Data Acquisition URL/account credential** identified in current files or reachable history. Treat cron mail, repository logs, build cache, clones, and CI/artifacts as potentially credential-bearing until reviewed.
5. **Remove live Redis host publication immediately after a verified backup** by recreating the four containers from the current no-port Compose definition. Add authenticated, least-privilege Redis ACL users and disable the `nopass` default user; do not rely solely on the absence of host ports.
6. **Restrict the eight archived `.env` files and the 22.5 GB PostgreSQL dump**, then restrict their parent directories/default ACLs. Review which local accounts and processes could read them.
7. **After credentials are revoked**, use an approved secret-removal runbook: preserve a restricted forensic mirror if policy requires; freshly fetch and enumerate branches, tags, PR refs, forks, and mirrors; obtain repo-owner/branch-protection coordination; rehearse the rewrite; force-update every affected ref safely; invalidate clones/caches/artifacts; and rescan every reachable object and built image. `--force-with-lease` may be one protection for branch updates, but it is not a complete history-removal procedure.
8. **Prevent the next near-term failures:** set Monday to the real `staging` database, fix raw Compose environment handling for Monday and Part Source Pipeline, and create/mount the required Part Source `files/` directory before either manual job is run.

Do not respond to the 130 GB Philips table by running one unbounded delete. Its remediation is described in DB-05.

## Reconciliation scorecard: reference versus current state

| Reference area | Current evidence | Result | Required reconciliation |
|---|---|---|---|
| Conventions and repo map, guide lines 14–58 | All ten repos were clean before this requested report was created. All are currently on `STAGING_docker` except the admin branch names are simply `STAGING`; the guide still names `DEV_docker` for Data/Acumatica and `DEV` for Redis. Several repos lack an upstream. | Document stale | Name one authoritative deployment branch per repo, set upstreams, and record SHA/digest in deployment evidence. |
| Docker baseline, lines 60–98 | Docker `29.4.3`, Compose `v5.1.3`, Docker root `/var/lib/docker`, and required services active match. Actual disk inventory includes additional mounted storage not documented. | Mostly aligned | Update disk inventory and deliberately assign backup/data failure domains. |
| Shared users/directories, lines 100–151 | `svc` UID 105 and Docker GID 987 match. `/opt/{apps,resources,run-logs}` are `root:docker 2775`. Default ACLs also grant `other` read/traverse and create other-readable files. Membership in `docker` grants root-equivalent daemon access. | Partial / unsafe | Separate runtime data access from Docker administration; use `2770`/private default ACLs where feasible and explicit secret modes. |
| PostgreSQL bootstrap, lines 156–205 | Named data volume, `pg_net`, restart policy, Postgres 16, SCRAM, and TLS work. Live `pg_db` contains `POSTGRES_PASSWORD` in Docker metadata and no `/run/secrets/pg_pw` mount. | Runtime drift | Rotate as needed and recreate from a tracked declarative definition using a validated secret-file mechanism. Assert the direct password key is absent. |
| Redis, lines 219–253 | Four healthy instances and expected networks/volumes exist. Guide describes published unauthenticated ports; current repo removes ports; old live containers still publish them and permit anonymous full access. | Document stale **and** runtime drift | Recreate from current source, introduce ACL/auth, and update guide/README/acceptance together. |
| `pg_manage_v2`, lines 292–343 | Image exists, but destination CA variable is unused, CA is not mounted, defaults do not enforce verified TLS, and destructive truncation precedes source validation/copy. | Missing control | Add verified TLS, preflight, staged/atomic loads, rollback, complete examples, and automated reconciliation. |
| App environment setup, lines 346–390 | Required keysets generally match examples, but all `.env` files are `0664`; multiple committed examples contain configured credentials; Monday has a duplicate key and points to a nonexistent DB; Compose changes `$`-bearing values. | Failed | Add consumer-aware secret modes, secret scanning, duplicate/semantic/fidelity validation, and live DB/TLS/grant smokes. |
| Shared resource/log dirs, lines 395–415 | Directories exist, but GE/Philips/Siemens/Data central log dirs are not writable by UID 105 under staging routing. Part Source `files/` is absent. | Partial | Add UID-105 write tests to acceptance for every declared RW path. |
| Credential migration, lines 420–432 | The documented Data helper prints decrypted credential objects and encrypted records. | Unsafe | Remove credential logging before any use and run through an approved, auditable secret process. |
| PostgreSQL TLS, lines 435–525 | TLS, SCRAM, `hostssl`, CA verification, and cert lifetime passed. Guide's host `chown 999` makes the private key readable by host user `dd-agent` (UID 999). Most apps use `require`, not `verify-full`. | Partial / unsafe | Deliver the key without host UID collision; finish app CA mounts and fail-closed `verify-full`. |
| Least-privilege DB roles, lines 529–560 | Reports and excluded dashboard/incident roles are restricted; other audited apps share `postgres`. Reports grants have partition/archive drift. | Known debt still open | Deploy one role per workload, integrate grants with partition lifecycle, and add negative grant tests. |
| Entrypoint/image matrix, lines 565–588 | Acumatica has adopted a built image/entrypoint; GE now owns a build; Reports build arguments are parameterized. Guide says otherwise. Built app images drop to UID/GID 105:987. | Document stale | Update matrix/build instructions and add immutable source labels/digests. |
| RPP/Acumatica/Reports sections, lines 626–699 | Current repos have moved beyond the guide; RPP local docs still point to old shared-utils/root service workflows. | Document stale | Replace duplicate stale docs with canonical pointers or keep them automatically validated. |
| Monday/Part Source, lines 702–736 | Images/mounts exist, but Monday DB and URI fidelity fail; Part Source URI fidelity fails and required directory is missing. | Failed | Correct configuration and add preflight/fidelity tests. |
| Canonical schedules, lines 836–846 | Installed application cron lines match `docs/schedules.md` apart from insignificant formatting. Monday, Part Source, Reports, and Siemens are intentionally unscheduled. Philips local docs describe cleanup that is not canonical/installed. | App schedule aligned; maintenance incomplete | Decide automation intent, add locking/timeouts/outcome alerts, and add safe Philips retention. |
| Backup/log rotation, lines 849–872 | Scripts/proposals exist, but backup/prune cron is not installed and Docker log rotation is not applied. | Failed | Make these required, monitored setup steps with restore and age assertions. |
| Follow-ups, lines 876–897 | Some remain valid (roles, image pins); some are already solved in source (Acumatica/GE builds); Redis source changed without runtime reconciliation. | Stale mixed list | Convert to owned, dated tracked work; remove resolved text only after deployment evidence. |
| Acceptance, lines 900–909 | Version, many mounts, networks, PostgreSQL TLS, and UID drop pass. Secret mode, semantic env values, ACL/auth, backup age/restore, partition horizon, exit status, and required-dir tests are absent. | Insufficient | Replace presence-only checks with the expanded acceptance gate near the end of this report. |

## Detailed findings

### Security and credential handling

#### SEC-01 — Critical — Active PostgreSQL superuser credential committed and reused fleet-wide

**Evidence**

- `data_acquisition/.env.example:102` contains a commented plaintext credential. An equality-only check confirmed it equals the current active `PGPASSWORD`, whose active user is `postgres`. Git attribution places it in the current 2026-08-06 tip `238c821`, reachable from local and cached-origin `DEV_docker` and `STAGING_docker`.
- `hhm_rpp_ge/.env.example:51`, `hhm_rpp_philips/.env.example:51`, and `hhm_rpp_siemens/.env.example:51` contain the same active value. Their affected tips are GE `47532bb753d83373a92bc28555efa77676aba8c6`, Philips `9d3d72875707f1f3217045ce49f13ccb2c3bb782`, and Siemens `fa16a518ba846bb0f62f6143ab17905fcd451032`; each is present at local and cached-origin `DEV_docker` and `STAGING_docker`. The three tips reference the same credential-bearing blob `8c8ca46444088dbb95914b244eb34af91b686046`.
- Reachable-history scanning found one matching credential-bearing tracked path/blob in each RPP repo and none in Reports. This is not a proof that other secret types are absent.
- Equality-only fleet comparison found the value in nine live environment keys across eight applications: Acumatica Sync, Data Acquisition (two destination/current keys), GE, Philips, Siemens, Monday, Part Source Pipeline, and `pg_manage_v2`.
- Most of those apps connect as the PostgreSQL superuser. Reports does not match and uses `reports_rw`.

**Delta:** The guide says secrets come from the secret store and acknowledges the shared-superuser debt (lines 354–371 and 529–560), but its process and acceptance tests did not prevent a live secret from entering `.env.example` or multiple remote branch tips.

**Action:** Follow the ordered containment plan above. Add blocking pre-commit/CI scanning, scan every Git ref rather than only the checkout, and re-allow only a sanitized `.env.example` after a deny rule such as `.env*`.

#### SEC-02 — Critical — Currently configured Part Source SFTP secret and Data Acquisition URL credentials are committed

**Evidence**

- `part-source-pipeline/.env.example:56` contains a nonempty plaintext SFTP password comment. An equality-only check confirms it exactly matches the configured live `SFTP_PASS`; no external login was attempted, so current account validity is not asserted. Its current tip `721f8c8` is present on/contained by local and cached-origin `DEV_docker` and `STAGING_docker`.
- `data_acquisition/read/sh/Siemens/siemens_cerb_files_list.sh:1` contains a literal credential-bearing URL, introduced by `ed5fb02` in 2023 and reachable from every current local/cached-remote branch tip. Source and recent-log reference checks suggest this one-line script is currently unused, which does not reduce credential exposure.
- Historical literals remain reachable in earlier versions of `read/sh/Philips/phil_cv_21.sh`, including changes `8df6a453`, `28b2b6f0`, and `25cbd1e6`; the current version is variable-derived, but history still discloses the prior values.

**Action:** Rotate the Part Source SFTP and all affected Data Acquisition external accounts, replace literals with protected injection/placeholders, delete truly unused scripts, and sanitize/coordinate all reachable history after rotation. Review external service access logs if available.

#### SEC-03 — High — Secret and backup files are world-readable by design

**Evidence**

- All ten in-scope live `.env` files are mode `0664`.
- Eight archived environment files under `/opt/resources/backups/env-reconcile-20260806/staging/` are `0664`.
- `/opt/resources/backups/pg/staging-20260727-1933.dump` is approximately 22.5 GB and mode `0664`.
- Sampled Data/GE/Philips JSON run logs and Data legacy logs are commonly `0664`, despite containing raw errors/upstream and credential-adjacent material. Cron mail is group-readable and similarly sensitive.
- Default ACLs on `/opt/apps`, `/opt/resources`, and `/opt/run-logs` include `other::r-x` and inherited file `other::r--`. The backup script redirects output without setting a private `umask`.

**Delta:** Guide lines 134–151 establish shared `2775` directories/default ACLs but omit a separate secret-file policy, private backup directories, and a restrictive creation umask.

**Action:** Use `0600` for host-only secret inputs/dumps and explicitly justified `0640` only where an app process must read the file through a dedicated non-Docker runtime group. Move Acumatica to protected injection or validate its temporary group-read design before tightening. Create logs privately (`0640`/`0660` in dedicated `0750`/`2770` directories), redact before persistence, and enforce bounded retention. Use `0700`/`0750` secret/backup directories, `umask 077`, and atomic temporary files. Review local identities/processes that had read access and rotate credentials if that trust was not intended.

#### SEC-04 — High — Runtime containers can persistently rewrite source, `.env`, and Git metadata

**Evidence**

- App repositories are group-writable and mounted read-write. Controlled entrypoint checks as the real runtime UID/GID `105:987` confirmed source, `.env`, and `.git` were writable in Acumatica, Data Acquisition, Monday, and Part Source. Equivalent RPP/Reports mount designs expose the same class of risk.
- Some legacy `app` services run stock Node as root and mount the checkout read-write. Data's legacy service also lacks `pg_net`, so it is both privileged and nonfunctional for DB jobs.
- Membership in the Docker group is root-equivalent at the host daemon boundary; it is currently also used as a general file-sharing group.

**Action:** Bake reviewed code into immutable images; mount source and warmed dependencies read-only if bind mounts remain; hide `.git`; expose only narrowly scoped output/log/cache paths read-write. Create a separate runtime-data group and reserve Docker daemon membership for administrators.

#### SEC-05 — High — PostgreSQL bootstrap secret remains in Docker metadata

**Evidence**

- Sanitized inspection of `pg_db` shows the key `POSTGRES_PASSWORD` in `Config.Env`; there is no `POSTGRES_PASSWORD_FILE` and no `/run/secrets/pg_pw` mount.
- Guide lines 166–181 and 465–478 specify a root-owned `0600` password file and `_FILE` variable.

**Action:** Rotate if required by SEC-01, then recreate `pg_db` from a tracked Compose/systemd definition using a tested secret mechanism. Preserve the named data volume. Add an assertion that the direct environment key is absent. Remember that a bootstrap file does not rotate an already-initialized role.

#### SEC-06 — High — Host UID collision exposes PostgreSQL TLS private key to `dd-agent`

**Evidence**

- Guide line 460 instructs `chown 999:docker /opt/resources/ssl/pg_ssl.key` so the container's PostgreSQL UID can read it.
- On this host, UID 999 resolves to `dd-agent`. The host key is mode `0600`, owned by that UID, and its parent path is traversable. Thus the host Datadog identity can read the key. Key contents were not read.

**Action:** Keep the source key root-owned and deliver it through a controlled init copy into a protected named volume/tmpfs, a root entrypoint that copies/chowns before dropping privilege, or another tested secret mechanism. Document host/container UID collision checks. Reissue the certificate/key if access by `dd-agent` was outside the trust boundary.

#### SEC-07 — High — Shared superuser and unverified TLS remain standard app configuration

**Evidence**

- Seven workload apps plus the administrative `pg_manage_v2` tool use the shared `postgres` role. Reports uses `reports_rw`; `redis-admin` has no PostgreSQL connection. The main connection mode outside Reports is generally `require`, which encrypts but does not authenticate the server.
- Data and Part Source have multiple active DB helper implementations. Several helpers silently downgrade a missing CA from verified TLS to unverified `require`. Acumatica's helper is fail-closed if verify mode is selected, but no CA is mounted.
- Reports is the positive control: `reports_rw` is non-superuser, CA-mounted, and fail-closed with `verify-full`.

**Action:** Inventory every imported helper, consolidate one fail-closed implementation, mount CA read-only, use `verify-full`, deploy one least-privilege role per workload, and test both required grants and forbidden operations. Remove the shared superuser only after every consumer and emergency process is mapped.

#### SEC-08 — High — Credentials and sensitive payloads can enter logs and cron mail

**Evidence**

- `data_acquisition/util/encrypt/old_to_new_process.js:25-38,60-65` prints decrypted credential objects and later encrypted records; the guide directs operators to run its wrapper.
- `data_acquisition/read/sh/GE/ge_mri_22.sh:1-7` enables shell xtrace while a positional argument is a password. The active caller prints and persists child stdout/stderr/full errors; the path ran 48 times in the sampled day.
- `/var/mail/matt-teixeira` is approximately 402 MB with 39,376 messages. A case-insensitive count found 8,294 `password` markers; values/content were deliberately not inspected.
- Multiple apps log entire upstream error bodies, SMTP results, or raw equipment/data events. Cron lines have no output redirection, so console content is duplicated into mail.

**Action:** Remove credential-object output, disable xtrace around secrets, avoid password arguments, redact error objects, log counts/correlation IDs instead of bodies, and classify/restrict existing mail/log artifacts. Make representative log/mail permission and redaction checks part of acceptance. Establish bounded structured logs and alerting before suppressing cron mail.

#### SEC-09 — High — Guide contradicts itself by passing role passwords on the command line

Guide lines 166–170 warn never to place the PostgreSQL password on a command line, but lines 552 and 692 instruct `psql -v pw='<...>'`. `reports/db/setup-role.sql:3-5,35-47` repeats the pattern. Command arguments and shell history can expose the value.

**Action:** Separate idempotent role/grant creation from credential assignment. Use interactive `\password` or an approved protected input channel, then record the secret only in the authorized store.

#### SEC-10 — High — Docker build contexts include secrets, VCS, and large runtime data

**Evidence**

- Data Acquisition has no `.dockerignore`; its eligible context is about 2.0 GB, including `.env`, `.git`, 1.7 GB of logger output, and 237 MB of legacy logs.
- GE has no `.dockerignore`; its approximately 242 MB context includes `.env`, `.git`, dependencies, and about 241 MB of logs.
- Acumatica, Monday, and Part Source ignore `.git`, `node_modules`, and `*.log` but not `.env`; Monday/Part Source do not exclude `files/` data.
- Reports and `pg_manage_v2` provide the better pattern by excluding environment/VCS/dependency material. No active secret values were found in streamed final image layers, but eligible build context remains an exposure.

**Action:** Use a deny-by-default allowlisted context. Exclude `.env*` (explicitly re-allow only a sanitized example), `.git`, logs, output/data, backups, private keys/client certificates, unneeded certificates, and dependency caches. Explicitly allowlist only a required public CA with a verified hash/provenance. Rebuild only after credential rotation and history sanitation.

#### SEC-11 — High — PostgreSQL is published on every host interface while perimeter controls are unverified

Live Docker port bindings and host listeners expose PostgreSQL 5432 on all IPv4/IPv6 host addresses. PostgreSQL itself correctly requires SSL/SCRAM on the network path, but the confirmed committed credential is a shared superuser credential, making perimeter containment especially important. Root-only iptables/DOCKER-USER rules and Azure NSG policy could not be inspected, so public reachability is **unverified**, not asserted.

**Delta:** The guide publishes 5432 broadly during bootstrap and relies on later HBA/TLS work; it does not make a private bind or proven network policy a hard acceptance gate.

**Action:** Verify Azure NSG and host/DOCKER-USER rules immediately. Bind PostgreSQL only to the required private/loopback interface or remove host publication when all consumers can use the Docker/private network. Make TLS/HBA effective before the first listener starts and add an explicit `hostnossl reject`/least-scope HBA policy where appropriate.

#### SEC-12 — High — Raw acquisition data is other-readable on the host

A metadata-only inventory of `/opt/resources/acqu_files` found 16,374 files and every one was readable by `other`: 8,877 mode `0664` and 7,497 mode `0644`. These are raw suite acquisition inputs; their PHI/customer sensitivity was not classified during this audit. RPP containers correctly mount the data read-only, while Data Acquisition intentionally needs a write path—the host ACL remains the exposure.

**Action:** Classify the data with its owner/privacy policy, restrict the host tree to a dedicated runtime group, preserve RPP read-only mounts, give Data only the minimum required write scope, and add negative-read tests for unrelated host/app identities. Include source and derived files, archives, logs, and backups in retention and incident-response policy.

### PostgreSQL, data integrity, and migration

#### DB-01 — High — Every partitioned table reaches its final boundary on 2026-10-01

**Evidence**

- A read-only catalog query found exactly 24 partitioned parent tables. Every parent's maximum upper bound is `2026-10-01 00:00:00+00`.
- No cron job or systemd timer invokes partition creation.
- The only available maintenance SQL, `data_acquisition/utils/db/sql/odd-jobs/add-pg-table-partitions.sql:3-7,27-154`, computes only the next month and issues plain `CREATE TABLE ... PARTITION OF` statements without safe existence/reconciliation logic. It also contains stale EDU assumptions. Archive SQL catches failures as notices.
- The guide creates/copies schema but has no partition-lifecycle section or acceptance query.

**Impact:** Once the October boundary is reached, inserts routed to these parents will fail unless a matching default partition exists; none was established as a general safety mechanism in this audit. This is an availability deadline, not routine housekeeping.

**Action:** Before September is well underway, centralize an idempotent partition manager that: inventories actual parents; takes an advisory lock; creates at least a three-to-six-month horizon; treats unexpected/missing parents as errors; integrates grants and archival; records a run outcome; and alerts below a minimum horizon. Test a next-month insert inside a rolled-back transaction.

#### DB-02 — High — `pg_manage_v2` cannot perform a fail-safe, verified migration

**Evidence**

- `DST_SSLROOTCERT` exists in the environment schema but has zero source references. Destination commands set `PGSSLMODE` without `PGSSLROOTCERT`; the documented Docker invocation does not mount `/opt/resources/ssl`.
- The DB helper silently falls back from missing CA to unverified TLS. Defaults include destination SSL disabled and source SSL merely `require` on some paths.
- The currently configured source CA path points under a nonexistent `utils/db/...` location while the repository certificate is under `db/`. Unverified `require` masks that error today; changing only the mode to `verify-full` would fail.
- Scripts 2–4 truncate/cascade destination objects before proving source connectivity, certificate/hostname validity, schema/column compatibility, or successful copy. Script 1 streams `--clean` schema changes directly to the destination without an all-or-nothing migration boundary.
- Script 2 is described as processing batch groups but uses only one `NEW_SCHEMA_PORT`. Several environment keys are unused/stale. There is no `.env.example`, dependency lockfile, automated test, dry run, all-table checksum/reconciliation, or rollback.

**Action:** Mount the reviewed CA read-only, set `PGSSLROOTCERT` on every command, require `verify-full`, and preflight CA-path existence, hostname/SAN, both endpoints, and target identity before destructive SQL. Load into staging tables/schema, reconcile tables/rows/checksums/sequences/partitions, then transactionally swap or merge. Add explicit destructive confirmation, backup prerequisite, rollback, ShellCheck/tests, a sanitized complete environment template, and a client/server version compatibility check.

#### DB-03 — High — Reports role grants drift as partitions move between active and archive schemas

**Evidence**

- `reports_rw` is correctly non-superuser and preserves required targeted grants.
- It retains 26 unexpected direct `SELECT` privileges on archived January/February objects: four in `archive_alert`, four in `archive_edu`, and eighteen in `archive_mag`. The role currently has no effective `USAGE` on those archive schemas, so these ACLs are dormant rather than presently usable; they still violate the allowlist and would become usable if schema access were granted later.
- It lacks direct `SELECT` on 26 August/September child partitions: four `alert`, four `edu`, and eighteen `mag`.
- The 13 affected families are `alert.{detections,notifications}`, `edu.{v1,v2}`, and `mag.{ge_mm3,ge_mm4,philips_mri_rmmu_history,philips_mri_rmmu_long,philips_mri_rmmu_magnet,philips_mri_rmmu_short,siemens,siemens_non_tim,stt_magnet}`.
- `reports/db/setup-role.sql:55-96` normalizes only current schemas; its fail-closed audit at lines 102–153 would detect but cannot clean archive drift. The script is not transaction-wrapped.

**Impact:** Archive access exceeds the apparent allowlist. Missing child grants may not break parent queries because PostgreSQL privilege semantics differ for direct child access, so direct application impact remains uncertain; the privilege drift itself is confirmed.

**Action:** Do **not** rerun `reports/db/setup-role.sql` unchanged: it first changes the password, then applies grants, then its audit will fail on the archive ACLs; without a transaction that leaves credentials and partial grants changed despite a reported failure. Separate password assignment, explicitly reconcile archive ACLs, wrap grants plus audit in `BEGIN`/`COMMIT`, and attach grant/revoke operations to the monthly partition lifecycle. Test parent/direct-child behavior, dormant archive denial, and negative access.

#### DB-04 — High — PostgreSQL lacks health/resource controls and retains an OOM event

**Evidence**

- `pg_db` has no Docker healthcheck, memory limit/reservation, or PID limit. Its state retains `OOMKilled=true` for the 2026-06-03 stop/restart event.
- The container is currently running and ready; a present-time sample is not enough to establish the prior OOM cause.
- Host memory at inspection was 31 GiB with no swap and roughly 18 GiB available. The Datadog system-probe was using approximately 8.2 GB RSS/HWM during inspection and warrants owner review, but no evidence ties it to the June event.

**Action:** Investigate and document the June OOM with available platform telemetry. Add `pg_isready` health/dependency semantics and measured reservations/limits/alerts in a tracked runtime definition. Size PostgreSQL and co-resident agents from observed peaks rather than imposing arbitrary caps.

#### DB-05 — High — Philips `log.saved_files` retention is absent and the table is 130 GB

**Evidence**

- `hhm_rpp_philips/jobs/aux_jobs/clear_old_db_files.js:3-10` is coded to delete records older than 48 hours, and app-local documentation mentions a cron entry.
- The canonical schedule and installed crontab omit it.
- The current cleanup implementation performs one unbounded delete, swallows errors, and returns before DB/file run logging; it can report success with no durable outcome and must not be installed unchanged.
- Read-only measurements: 344,241 rows; 329,012 older than 48 hours; oldest capture 2026-07-05; approximately 7,600 rows/day; 130 GB total, nearly all TOAST, with only about 57 MB heap and 44 MB indexes. A capture-time index exists.

**Action:** Confirm business/legal retention. Rewrite the cleanup for small indexed, committed batches with lock and statement timeouts, WAL/free-space monitoring, resumability, metrics, awaited self-logging, and nonzero failure. Vacuum/analyze afterward; ordinary vacuum reuses space but does not return it to the OS. Do not use `VACUUM FULL` without a planned exclusive-lock/capacity window. Longer term, move payloads to object storage or time partitions and drop expired partitions. Install a monitored, locked cleanup only after the safe backlog plan succeeds.

#### DB-06 — Medium — Query observability and baseline tuning are unfinished

**Evidence**

- `staging` reports approximately 252,000 cumulative temporary files and 959 GB of temporary writes.
- `pg_stat_statements` is installed but unusable because `shared_preload_libraries` is empty.
- Settings remain near defaults for a 31 GiB host: `work_mem=4MB`, `shared_buffers` about 128 MB, `effective_cache_size` about 4 GB, `effective_io_concurrency=1`, `track_io_timing=off`, and `log_temp_files=-1`.

**Action:** In a planned restart, preload `pg_stat_statements`, enable appropriately redacted slow-query/temp-file telemetry, and establish workload baselines. Tune from concurrency and query evidence; do not simply raise global `work_mem`.

#### DB-07 — Medium — Recovery design is logical-dump-only and omits cluster globals

Checksums and WAL archiving are off; there is no replica or replication slot. Durability basics (`fsync`, full-page writes, synchronous commit) are on. The backup captures `staging` but not cluster-global roles, and the guide does not define RPO/RTO, PITR, role/config recovery, or fresh-host recovery.

**Action:** Define RPO/RTO. Add versioned role/grant recreation or `pg_dumpall --globals-only`, configuration inventory, and an encrypted off-host copy. If RPO requires it, add WAL archiving/PITR and/or a replica. For new initialization, enable data checksums; assess an offline enablement plan for the existing cluster.

#### DB-08 — Low — Schema-gap text is stale

Guide lines 332–334 say EDU is empty; the live database now contains 20 EDU tables. `mag.ge_mm` remains absent while `mag.ge_mm3` and `mag.ge_mm4` exist. Update the guide and add schema-contract checks for any code that still expects `mag.ge_mm`.

### Redis

#### REDIS-01 — Critical — Four unauthenticated full-privilege instances are published on all host interfaces

**Evidence**

- Live HostConfig publishes ports 6379–6382 on empty HostIp, and `ss` confirms listeners on `0.0.0.0` and `[::]`.
- Safe runtime queries show `protected-mode=no`, no password, and the default user `on nopass ~* &* +@all`. Anonymous host-network `PING` succeeds.
- Current `redis-admin/docker-compose.yaml:19-81` contains no `ports:` blocks. Desired source hashes differ from every live container's Compose label; containers were created 2026-07-27, before the 2026-07-28 source change that removed ports.
- UFW and nft CLI tools are absent, but root-only iptables/DOCKER-USER rules could not be read. Azure CLI is absent, so NSG exposure is also unverified. Listener presence is confirmed; public reachability is not.

**Delta:** The guide explicitly describes unauthenticated all-interface publication and defers authentication, while current source intends private bridge-only access. The live runtime matches neither a secure design nor the source.

**Action:** After a verified backup, recreate from current no-port Compose. Add unique per-app/per-instance ACL users, disable the default user, update clients and authenticated healthchecks, and keep credentials out of tracked configs. Verify host firewall/DOCKER-USER and NSG independently. Because PROD, STAGING, and DEV share one bridge, also split environment networks or prove ACL-based cross-environment denial.

#### REDIS-02 — High — Kernel reliability prerequisites are not applied

All four containers logged the Redis memory-overcommit warning. Host `vm.overcommit_memory=0`; transparent huge pages report `[always]`. `somaxconn=4096` is sufficient for the configured Redis backlog.

**Action:** Persist `vm.overcommit_memory=1`; evaluate and persist THP disablement per the supported Redis/host policy; verify after reboot. Add both checks to setup and acceptance.

#### REDIS-03 — Medium — Memory/PID policy and client lifecycle are missing

- Redis has no container memory/PID constraints and `maxmemory=0`. This is not automatically wrong, but it makes host contention unbounded.
- Philips and Siemens helpers reference block-scoped or nonexistent clients in `catch` blocks, masking the original failure with `ReferenceError`; several `quit()` calls are not awaited and clients are created per operation without connection/command timeouts.

**Action:** Measure peak usage and define appropriate reservations/limits and, if justified, Redis `maxmemory`/eviction policy consistent with data criticality. Refactor clients to one connection per job with explicit timeouts and `try/finally` guarded/awaited close. Add authentication/TLS client support with REDIS-01.

#### REDIS-04 — Positive controls

All four containers were healthy with `restart=unless-stopped`, zero restarts, non-root PID 1, named volumes, and read-only configuration mounts whose host/container hashes matched. AOF is enabled with `appendfsync=everysec`; AOF/RDB status reports no save/rewrite error. Key counts (content not read) were PROD 1,711, STAGING 1,711, dev04 1,712, and dev05 0. These controls should be preserved during recreation.

#### REDIS-05 — High — The guide's RDB seed/restore sequence can start empty under AOF

Guide lines 246–250 correctly warn that an AOF-enabled Redis with an AOF manifest can ignore `dump.rdb`, but lines 278–281 then instruct operators to delete `appendonlydir` and start with the same AOF-enabled configuration. That recreates the empty-start condition and risks treating an empty instance as restored. The only backup artifacts currently retained are RDB files.

**Action:** Replace this with a rehearsed, rollback-safe procedure: preserve the only AOF/RDB artifacts; start an isolated instance temporarily with AOF disabled to load the RDB; authenticate and verify expected key count/content invariants; enable AOF on the populated instance and wait for a successful rewrite; then restore the normal reviewed config and recreate. Never delete the only AOF before independent backup and verified recovery.

### Backups, logs, schedules, and host operations

#### OPS-01 — High — Backup automation is not installed and recovery is unproven

**Evidence**

- Neither user/root crontabs, `/etc/cron*`, nor systemd timers contain the proposed backup or prune jobs.
- Only one backup set exists, dated 2026-07-27. The PostgreSQL custom archive passes `pg_restore --list`; all four Redis files identify as valid RDB v12. These are format checks, not restore tests.
- `backup.log` is absent. No full restore, role/global recovery, Redis restore, off-host copy, or freshness alert is evidenced.
- Redis backup calls `SAVE` and copies `dump.rdb`, while the instances use AOF. A restore that leaves AOF enabled may load AOF instead of the copied RDB, so the current procedure does not yet prove which artifact is authoritative or recoverable.
- `/opt` backups and `/var/lib/docker` reside on the same root filesystem. A separate mounted `/mnt/sdd` 2 TB disk is roughly 1% used, but a separate local disk is still not an off-host copy.

**Action:** Prefer monitored systemd timers with `Persistent=true`, or implement an explicit startup freshness/catch-up check; plain cron silently loses backup/prune/partition runs during downtime. Add `umask 077`, `flock`, free-space preflight, traps, `.partial` output plus atomic rename, checksums, independent retention, and alerts on age/failure/size. Encrypt and copy off-host. Rehearse a missed-window catch-up and a fresh isolated restore of PostgreSQL database + globals/grants/config and each authenticated Redis instance; record duration and evidence against defined RPO/RTO.

#### OPS-02 — High — Application log pruning and Docker rotation are not operational

**Evidence**

- `prune.log` records one run on 2026-07-27. Current in-scope repo log totals are approximately 69,363 files / 4.29 GB, with 37,683 older than 14 days: Data 37,823 / 1.734 GB (20,543 old), GE 4,731 / 247.8 MB (2,571 old), Philips 26,809 / 2.304 GB (14,569 old). Data also has 81,803 legacy `logs/` files / approximately 237 MB outside the current prune pattern.
- `/etc/docker/daemon.json` is absent; dockerd has no log-rotation flags/drop-ins; persistent containers have empty log options. Current container logs are not yet large, but are unbounded.
- The guide calls nightly pruning at lines 47–53 but later labels the actual cron additions and daemon configuration as proposals.

**Action:** Install/monitor the pruner, include or retire Data's legacy logger, and test retention without following symlinks or deleting unrelated files. Apply bounded Docker `local` or `json-file` rotation during maintenance and recreate persistent containers so defaults take effect. Add disk/inode/failure alerts; never automate volume pruning.

#### OPS-03 — High — Scheduled error signals are pervasive while process status is often false-success

**Evidence**

- Data Acquisition, last 24 hours: 1,152 runs; 939 (81.5%) contained at least one ERROR and 624 contained WARN. Over 14 days, 13,242 of 16,128 runs had error events. The top error-producing functions were `execRsync`, `exec_hhm_data_grab`, and `exec_remote_rsync`.
- GE, last seven days: all 1,008 runs contained warning/error events, including 30,912 warnings.
- Philips, last seven days: all 5,712 runs contained warning/error events, with 75,496 warning/error events including 23,856 ERRORs.
- Data, GE, Philips, Siemens, Reports, and Part Source contain top-level or inner catches that log/suppress and return zero/no failure status. Reports and Part Source import self-logging functions but do not produce the guide's promised `util.app_run_logs` outcome.

**Caveat:** An event-bearing run can include a tolerated per-system failure and is not automatically a whole-job failure. The inability to distinguish partial, tolerated, and fatal outcomes is itself the finding.

**Action:** Define an explicit final state (`success`, `partial`, `failed`, `skipped`) with counts; propagate fatal errors; set a nonzero exit code; await/flush logs; close PG/Redis in `finally`; alert on partial/failure thresholds. Add `flock` and bounded timeout to schedules. Investigate the persistent endpoint/system failures after the outcome model is trustworthy.

#### OPS-04 — Medium — Cron mail is uncontrolled and its trim process is inadequate

Every scheduled command can emit mail; the spool is approximately 402 MB. The monthly trim is retention rather than redaction/alerting and uses a predictable temporary path. Move to per-job structured, mode-restricted, rotated output or journald and alert on final state. Use a safe mail retention mechanism with private temporary creation and atomic replacement only after important failure signals are captured elsewhere.

#### OPS-05 — Medium — Central run-log permissions will fail when environment routing changes

`/opt/run-logs/data_acquisition`, GE, Philips, and Siemens are not effectively writable by runtime UID 105 under current group/ACL state. Current `RUN_ENV=dev` directs logs elsewhere and masks the issue. Reports/Monday/Part Source paths were aligned.

**Action:** Establish the intended nonprivileged log group, setgid directory and effective ACL mask, then perform a create/append/rotate smoke test as UID 105 for every central path. Do not solve this by expanding Docker daemon access.

#### OPS-06 — Medium — Host/storage inventory and patch posture are stale

- Root `/dev/sda1` is 2 TB, about 41% used with roughly 1.2 TB free and low inode use. Additional mounted disks include `/mnt/sdd` 2 TB at roughly 1% used; the guide describes only the root topology.
- The inspected host is Debian 13.6 on a 6.12 cloud kernel. A further approximately 1 TB device was visible but not mounted; it should not be treated as usable or durable capacity until ownership and intent are established.
- Cached package metadata showed 13 available upgrades, including Docker/Compose/containerd, Datadog, and `libpq`. No network refresh was performed, so this is a maintenance signal, not a current vulnerability assertion.
- Docker image inventory has about 12.2 GB reported reclaimable and 1.76 GB build cache. This is not an emergency, but cleanup ownership is undefined.

**Action:** Update the host inventory, schedule tested patching, and make storage placement an explicit failure-domain choice. Use conservative image/build-cache cleanup with age/digest evidence; never prune volumes indiscriminately.

#### OPS-07 — Medium — Time synchronization and local encryption-at-rest evidence are incomplete

The host timezone file and current clock report UTC, which is the correct canonical basis for cron, partition bounds, TLS validity, and run records. NTP synchronization could not be proven: system-bus access was denied and the chrony client could not reach its daemon from the audit context. Visible root and backup-capable filesystems are plain ext4 block mappings with no local dm-crypt/LUKS layer in the inspected view; Azure-managed-disk/server-side encryption policy was not accessible.

**Action:** Make UTC plus synchronized NTP/chrony a setup assertion and alert on loss of synchronization. Record the encryption-at-rest policy/evidence for the root Docker/`/opt` volume, any `/mnt/sdd` backup placement, snapshots, and off-host copies. Do not infer lack of Azure platform encryption merely from the absence of a guest-visible LUKS layer.

### Docker, release, dependency, and setup reproducibility

#### REL-01 — Medium — Images and runtime definitions are mutable and incompletely attributable

- All app Dockerfiles use mutable `node:lts`, currently resolving locally to Node `24.16.0`; app images are approximately 1.63–1.64 GB. PostgreSQL uses `postgres:16`; Redis uses `redis:7-alpine`.
- The shared `hhm_rpp:staging` image predates GE's first tracked Compose-owned Dockerfile and carries no OCI source/revision label, so its exact source provenance is uncertain.
- `pg_manage_v2` has no dependency lockfile and uses `npm install`. Other inspected production caches match their lockfiles.
- No local Docker CVE scanner was installed. Registry advisory audits completed for the core four apps only; RPP/Reports advisory lookup was not authorized because it would disclose private dependency metadata externally.

**Action:** Pin supported versions and tested digests; use lockfiles and `npm ci`; add OCI revision/source/build-date labels, SBOM/provenance, signed/attested builds if supported, and a defined dependency/image update cadence. Rebuild from reviewed SHAs and record exact image IDs in deployment evidence.

#### REL-02 — High — Compose validates syntactically while silently changing configuration

All nine Compose projects pass `docker compose config --quiet`, but Acumatica, Monday, and Part Source emit `$expand`/`$format` interpolation warnings. Acumatica does not inject the app env into the process, so dotenv later reads raw values; its warnings are cosmetic but noisy. Monday and Part Source use `env_file`, so Compose's altered values become authoritative and cause real runtime corruption.

**Action:** Treat any Compose warning as an acceptance failure. Use Compose's long-form raw environment-file format where supported, isolate a minimal `.compose.env` for interpolation-only values, or escape/quote literal dollars. Add a nonsecret sentinel containing `$format` and `$expand` and compare bytes inside an ephemeral container.

#### REL-03 — Medium — Container hardening and resource policy are absent

Batch app definitions generally lack read-only root filesystems, capability drops, `no-new-privileges`, memory/PID limits, and explicit temp/output mounts. Default AppArmor, seccomp, and cgroup namespaces are active and containers are not privileged, which is a useful baseline but not workload-specific hardening.

**Action:** After mapping actual writes and child-process needs, make root filesystems/source read-only, use tmpfs for temp paths, drop unused capabilities, set `no-new-privileges`, and add measured resource/time limits. Preserve UID/GID 105:987 and verify every declared writable path.

#### REL-04 — High — SSH setup weakens host verification and grants overly broad read access

Guide lines 604–622 prescribe a group-readable private key/config and include a relative-path `chmod` command that is unsafe outside the expected directory. Data's Dockerfile enables SFTP auto-confirm and legacy `group1`/`ssh-rsa`, conflicting with the guide's claim of verified host keys.

**Action:** Use absolute paths, a dedicated non-Docker read-only service group, `0750` directories, `0640` or stricter key/config/known-host files, pinned `known_hosts`, and strict verification. Scope legacy algorithms to the minimum named host and plan their removal.

#### REL-05 — Medium — Automated quality/release gates are largely absent

The audited application repos have no meaningful unit/integration test suites, lint configuration, CI workflow, or Node `engines` guard. Syntax checks passed, but syntax is not behavior. Several unused dependencies remain (`pm2` in RPP apps, `short-uuid` in Reports, TypeScript tooling in Philips), and Data relies on a transitively hoisted `uuid` without declaring it directly.

**Action:** Add CI gates for secret/ref scanning, Compose warnings/config, lockfile install, syntax/lint/tests, Docker build, dependency/SBOM scan, environment schema and byte fidelity, non-root/read-only runtime, DB/TLS/grant smokes, required directories, and explicit failure exit behavior.

#### REL-06 — Low — Canonical guide scope is blurred by optional/unowned applications

The user-defined core suite is ten apps, but guide resource/application sections also provision excluded ad hoc or separately owned apps. Split the executable core baseline from optional annexes so following the one-stop path does not inadvertently deploy or grant access to unrelated workloads.

#### REL-07 — Medium — Tracked examples hard-code host/release facts that should be discovered

The August parameterization work says host identity must not be hard-coded, yet tracked environment examples still contain concrete staging UID/GID and image-tag values. Copying them to a new development server can silently bake the wrong user/group identity or deploy the wrong image tag.

**Action:** Leave required host facts unset and fail closed, or generate a protected host-specific Compose environment from `id`/`getent` plus the approved release manifest. Acceptance must compare numeric host facts, image users/groups, and write permissions before running a workload.

#### REL-08 — High — Branch/tag/RUN_ENV do not control external production side effects

The guide's deployment axes do not include external-system identity and egress. Several staging checkouts are configured with production-class Acumatica, HCA, Monday, Teams/SMTP, or SFTP accounts/endpoints, and some code unconditionally consumes `PROD_*` variables. No mutating external call was executed, so the exact side-effect scope remains unverified; the configuration/design gap is confirmed.

**Action:** Maintain a per-app data-flow manifest classifying every endpoint, credential/account, board/mail destination, SFTP path, and operation as production/test/read-only/mutating. Use non-production identities or dry-run for validation, enforce egress allowlists, and require an approved deployment-intent token/preflight before a staging checkout may mutate a production system.

#### REL-09 — High — Guide order can auto-create bind sources with the wrong ownership/type

The guide warms Data Acquisition's `app_tools` cache at lines 379–380 before creating its node-cache/data/run-log subdirectories at lines 395–409 and before provisioning the SSH bundle at lines 592–623. Short-form bind mounts can auto-create missing host paths as root-owned directories, defeating the intended permission model; stricter long-form mounts may instead fail.

**Action:** Move every shared/resource/cache/data/log/SSH directory creation, ownership, mode, ACL, and file-type preflight ahead of any Compose build/run that resolves mounts. Prefer long-form binds with `create_host_path:false`. Acceptance must reject a missing/wrong-type/wrong-owner bind source before Docker is invoked.

#### REL-10 — Medium — Host-local operational scripts are not reproducible from the guide/repositories

The guide writes a crontab snapshot into `/opt/resources/backups` before proving that private directory exists, then states that scripts “live” under `/opt/resources/scripts` without a versioned installation source. These scripts are outside the audited repositories, so a blank server cannot reproduce or authenticate them from Git and the guide alone.

**Action:** Version the scripts/configs in an owned infrastructure repo or embed/package checksummed content. Create private backup/log directories first, install files with explicit owner/mode/hash, validate syntax/dry run, then install persistent timers.

## Application-by-application findings

Cross-cutting findings such as the committed credential, `.env` permissions, shared superuser use, writable source, image pinning, and missing CI apply to the apps below even where not repeated.

### 1. `acumatica_sync`

**Current/aligned state**

- Clean checkout on `STAGING_docker` at the inspected local SHA; local DEV/STAGING/cached-origin tips currently agree, but no upstream is configured.
- Current Compose builds/runs `acu-sync:${IMAGE_TAG}` with the baked entrypoint and UID/GID drop. The expected image exists and a real encrypted `SELECT 1` smoke passed. Top-level failures set a nonzero status and close the pool.
- Dependency tree matches the lockfile; the point-in-time production advisory audit returned no advisories.

**Deltas and loose ends**

- **Document stale:** guide matrix/section/follow-up lines 585, 665–674, and 888 still say stock `node:lts`, hard-coded user, unused Dockerfile, and “do not build.” Current `docker-compose.yaml:3-20` owns the real build.
- **Missing audit contract:** `index.js:12-49` logs only to console and does not create the guide's promised `util.app_run_logs` record.
- **API safety:** `api_call/rtt-odata.js:10-27` has no timeout/retry and logs the full upstream error response body.
- **Atomicity:** `jobs/insert_new_systems.js`, `jobs/update_table_deltas.js`, and sequential query helpers mutate per system/field without a transaction; a mid-run failure leaves partial state.

**Recommended closure:** Update guide/README and branch upstream; add a redacted structured run result; add timeout/bounded retry/jitter; use a transaction/bulk upsert or staging table; schema-qualify SQL; add least-privilege `verify-full` role and CA mount.

### 2. `data_acquisition`

**Current/aligned state**

- Clean `STAGING_docker` checkout; DEV/STAGING local/cached-origin tips currently agree, but the branch has no upstream. Current application cron entries match the canonical schedule.
- `app_tools` uses the expected image, mounts, SSH bundle, dependency cache, and UID/GID drop. Encrypted DB `SELECT 1` passed. Environment key schema matches the tracked example with no blank active keys.
- Node and Bash syntax checks passed.

**Critical/high findings**

- Active superuser credential and external URL credentials are tracked/reachable (SEC-01/SEC-02).
- `read/sh/GE/ge_mri_22.sh` xtrace and `util/encrypt/old_to_new_process.js` disclosure paths are active/unsafe (SEC-08).
- `index.js:75-120` silently accepts unknown run groups and catches top-level errors without setting a failure code. The DB/file logger also swallows insert/stream failures. Recent event aggregates are described in OPS-03.
- `utils/logger` holds 37,823 JSON files / 1.734 GB; 20,543 are older than 14 days. Legacy `logs/` contains 81,803 files / 237 MB and is outside the pruner.
- The legacy `app` service runs as root, mounts the repo read-write, joins only Redis, and cannot resolve `pg_db`; remove it or make it identical to the supported `app_tools` runtime.
- No `.dockerignore`; the build context is about 2.0 GB and includes secrets/VCS/log data (SEC-10).
- Central staging log path is not writable by UID 105 (OPS-05).
- A migration/destination environment block still names a `dev` database on `host.docker.internal` with SSL disabled. That path was not executed, so current use is uncertain; the local cluster has no `dev` database. Remove it if obsolete or bring it under `pg_manage_v2`'s verified, preflighted workflow.

**Dependencies:** A point-in-time `npm audit --omit=dev` reported 29 findings (4 low, 7 moderate, 16 high, 2 critical). The critical paths were transitive through direct `pm2@5.3`; import scanning found no app use of `pm2`, `cron`, `ioredis`, `lodash`, or `short-uuid`. `uuid` is actively imported but not declared directly.

**Recommended closure:** Contain credentials first; make unknown/fatal work nonzero and await logger shutdown; retire the legacy service/logger; triage current endpoint/system failures; add a strict build allowlist; remove demonstrably unused dependencies, declare direct ones, update/relock/regression-test; reconcile branch/README to the deployment branch.

### 3. `hhm_rpp_ge`

**Current/aligned state**

- Clean `STAGING_docker` checkout with key schema/cache/Compose validation aligned. Recent output ownership proves UID/GID drop. Scheduled row volume matches expected cadence.
- GE now owns the `hhm_rpp:${IMAGE_TAG}` Compose build.

**Deltas and loose ends**

- `.env.example:51` contains the active shared database credential (SEC-01).
- Every one of 1,008 sampled seven-day runs contains warning/error events; GE catches per-system/top-level failures and ends with exit code zero (`index.js:29-55,86-109`).
- No `.dockerignore`; approximately 242 MB of eligible context includes `.env`, `.git`, dependencies, and roughly 241 MB of logs.
- Repo-local logs total about 4,731 files / 247.8 MB, with 2,571 older than 14 days; pruning is not scheduled.
- Guide/manual build text is stale. `docs/setup.md` still selects DEV, clones obsolete shared `utils`, and recommends the stock/root `app` service; the README is empty.

**Recommended closure:** Complete credential containment; aggregate per-system state into a reliable nonzero final outcome; add allowlisted build context and OCI revision; install pruning; update the guide to `docker compose build app_tools`; replace stale local setup docs with a canonical pointer.

### 4. `hhm_rpp_philips`

**Current/aligned state**

- Clean `STAGING_docker` checkout with Compose/key schema/cache aligned; UID/GID drop is evidenced. Scheduled row volume matches expected cadence.
- GE is the intended current build owner for the shared RPP image. The installed `hhm_rpp:staging` image predates GE's first tracked Dockerfile commit and has no revision label, so its actual source provenance remains unknown.

**Critical/high correctness and security findings**

- `.env.example:51` contains the active shared database credential (SEC-01).
- All 5,712 sampled seven-day runs contained warning/error events, including 23,856 ERROR events. `index.js:45-101` catches/logs without reliable nonzero final state or full resource cleanup.
- The 23,856 ERROR total is explained by persistent missing-file cascades: RMMU directory ENOENT 6,048; Logcurrent ENOENT 5,040; two follow-on TypeError classes 4,368 each; CT EAL ENOENT 2,016; and CT Events ENOENT 2,016. `Philips_MRI_Rmmu.js` continues after `readdir` failure, Logcurrent continues after missing size input, and both CT parsers call `stat` before their missing-file guards.
- `processing/phil_mri_monitor_data/initialUpdate/minValue.js:83` assigns to `sme` instead of comparing, so the special parser is always chosen in that condition and the system identifier is mutated. Its catch at lines 111–118 calls undefined logger symbols, masking the original exception.
- `read/sh/get_monitor_delta.sh:8-10` always appends a second extraction from a hard-coded 2023 timestamp and embeds `$1` into awk source. It can replay/duplicate historical data on every delta.
- `data_acquisition/Philips_MRI_Logcurrent.js:13,16-20,191-196` passes a DB/config-derived path through `child_process.exec`, creating shell-command injection risk.
- `util/phil_mri_monitor_helpers.js:43-85,134-179` interpolates config-derived column names as SQL identifiers without a strict allowlist/identifier escaping. Impact is amplified by the shared superuser.
- Several shell wrappers leave paths/options unquoted. `Philips_MRI_Monitor.js:127-145` unconditionally prints and passes the raw last-line equipment event to the logger, which serializes it to PostgreSQL and disk along with full error stacks. Additional console stack/first-last output is conditional on `LOGGER=dev`, which the current configuration does not enable.
- Redis helper catches can throw `ReferenceError` while handling another failure; clients lack robust timeout/finally close (REDIS-03).
- The 130 GB saved-file retention backlog is DB-05. Repo logs are about 26,809 files / 2.304 GB, with 14,569 older than 14 days.

**Recommended closure:** In addition to fleet containment, fix/test strict comparison and error imports; remove the hard-coded extraction and use native Node streaming or safe `awk -v`; replace shell execution with filesystem APIs/`execFile`; allowlist/escape identifiers; audit potentially affected aggregates; redact raw payloads; correct Redis lifecycle; execute the controlled DB retention program. Reconcile app-local cron/docs with the canonical manifest.

### 5. `hhm_rpp_siemens`

**Current/aligned state**

- Clean `STAGING_docker` checkout; Compose/key schema/cache align and it intentionally has no live schedule in the canonical manifest.
- Uses the shared RPP image and read-only acquisition-data mount.

**Deltas and loose ends**

- `.env.example:51` contains the active shared credential (SEC-01).
- `index.js:45-77` catches errors, explicitly suppresses DB error logging in one path, does not reliably set failure status, and does not guarantee pool closure.
- Redis helpers reference an unavailable client during error handling and do not consistently await close or enforce timeouts.
- The central staging log directory is not writable by UID 105.
- `docs/setup.md` repeats the obsolete DEV/shared-utils/root-service workflow; there is no README. Manual runtime outcome was not exercised to avoid side effects.

**Recommended closure:** Contain credential; make manual jobs return an audited final state and close resources; fix Redis lifecycle; repair the staging log path; replace stale docs; add a non-destructive smoke job to release acceptance.

### 6. `monday`

**Current/aligned state**

- Clean `STAGING_docker` checkout with configured upstream, built image, correct UID/GID entrypoint, and matching dependency cache. The runner rejects a missing job, records top-level errors, and exits nonzero in its principal path.
- Monday is intentionally absent from the canonical live schedule, although app-local documentation disagrees.

**Critical/high findings**

- Active `PGDATABASE=dev`, while the local cluster contains only `postgres` and `staging`. A real app-container connection failed with SQLSTATE `3D000`. Compose overrides host/port/SSL but not database. Duplicate legacy PG keys add ambiguity.
- Compose changes `PROD_EQUIPMENT_URI`, `PROD_EQUIPMENT_ALL_URI`, and legacy `PG_PW` because of `$` interpolation. The URI keys are actively used. The preferred helper uses `PGPASSWORD`, so the altered legacy password key may not be the active DB failure, but it still demonstrates unsafe config duplication.
- Job auditing writes `stats.job_runs`, not the guide's `util.app_run_logs`. Per-item Monday update failures are counted/printed but can still yield overall success without an explicit partial-failure state.
- Four CSV exports totaling roughly 1.4 MB are mode `0664`, dated 2026-06-15, contain operational/customer/equipment data, have no retention, and are eligible for the Docker context.
- API calls lack timeout/retry and log full upstream error bodies.
- `PROCESS-FLOW.md` claims daily/:20/:50 schedules, while canonical `docs/schedules.md` and live cron intentionally exclude Monday; last historical scheduled job records were 2026-07-07.

**Dependencies:** Point-in-time audit reported two moderate findings involving `short-uuid`/transitive `uuid`.

**Recommended closure before any run:** Set and assert `staging`; collapse duplicate DB settings; mount CA and use fail-closed `verify-full`; preserve `$` bytes via raw env handling; add startup connection/fidelity smoke. Then define partial-failure status, classify/restrict/retain exports, sanitize/bound APIs, update dependencies, and decide/document whether automation should return.

### 7. `part-source-pipeline`

**Current/aligned state**

- Clean `STAGING_docker` checkout; DEV/STAGING local/cached-origin tips agree, but no upstream is configured. The image/entrypoint/UID/cache/log mapping align. A real encrypted DB `SELECT 1` passed.
- Canonical schedule intentionally leaves this app manual.

**High findings**

- `.env.example:56` commits the currently configured plaintext SFTP credential (SEC-02).
- Compose alters all seven actively consumed feed/OData URI keys (`HCA_URI`, `HCA_TECH`, `HCA_INVOICE`, `HCA_CONTRACT_DETAILS`, `HCA_SRV_ORDER_DETAILS`, `INV_FEED`, `INV_FEED_2`) at `$format` interpolation points.
- Required `/opt/apps/part-source-pipeline/files` is missing despite guide line 727; `jobs/sync-inv-feed.js:70-74` writes there synchronously and will fail `ENOENT` before SFTP.
- `index.js` imports but never calls DB self-logging, accepts unknown jobs, and swallows failures. `sync-hca`, feed, and SFTP layers also catch without propagating, so a failed manual run can exit zero with no audit record.
- The HCA client logs the entire response dataset, potentially including invoice/customer/service data; error paths print full upstream bodies.
- Two active DB helpers diverge; the business helper silently enables unverified TLS without a CA.

**Dependencies:** Point-in-time audit reported one moderate direct `uuid` finding.

**Recommended closure before any run:** Use raw env semantics and prove byte fidelity; create a controlled UID-105-writable data mount and preflight it; exclude it from builds; propagate/record final failure; replace payload logs with counts/IDs; consolidate fail-closed DB helper; update dependency and branch upstream.

### 8. `pg_manage_v2`

**Current/aligned state**

- Clean `STAGING` checkout. Expected image exists. `.env` is ignored/untracked, but mode `0664` is unsafe.
- PostgreSQL client 16 is intentionally installed.

**Deltas and loose ends**

- Migration correctness/TLS risks are detailed in DB-02.
- Guide has no sanitized complete `.env.example`; dead/stale variables include `DST_SSLROOTCERT`, `EDU_KDB_TABLES`, `CON_DATA`, and some environment port keys.
- The built `pg_manage:latest` image predates the inspected repo's SSL-related commit, so source/image provenance is not reconciled.
- No dependency lockfile; mutable `node:lts`; no tests/CI.
- Dead/misleading paths include wrong argv indexing with swallowed errors in `index.js`, a reference to a nonexistent script, destructive raw Redis recreation commands, and an old `/home/.../apps`/deprecated-utils workflow.

**Recommended closure:** Treat one versioned, tested migration workflow as canonical; delete/archive dead paths; add lockfile/`npm ci`, provenance, TLS/preflight/staged load/reconciliation/rollback, safe examples, and an explicit maintenance-only destructive gate.

### 9. `redis-admin`

**Current/aligned state**

- Clean `STAGING` checkout. Current DEV and STAGING refs point to the same commit, although the guide names DEV. Compose validates and its source has no host port publication. Four tracked configs correctly use long-form read-only binds and AOF.

**Deltas and loose ends**

- Live containers predate/no longer match source and remain published/unauthenticated (REDIS-01).
- PROD/STAGING/DEV share one bridge, so source removal of ports does not provide environment isolation from another attached container.
- README is internally inconsistent: it says no host ports but retains password/port known-issue text and references a missing commands file. Environment password keys are unused.
- Neither branch has a reliable documented release/upstream workflow; remote freshness beyond cached refs was not checked.

**Recommended closure:** Reconcile runtime after backup; add ACL/network isolation/kernel controls; clean dead env/docs; pin Redis image digest; set intended upstream; add safe authenticated backup/restore and denial tests.

### 10. `reports`

**Current/aligned state**

- Clean `STAGING_docker` checkout. Compose validates, builds `aux:${IMAGE_TAG}` with parameterized IDs, mounts CA read-only, and enforces fail-closed `verify-full`. `reports_rw` is non-superuser and required sensitive-table denial remains effective.
- Reports is intentionally manual-only in the canonical schedule. No live manual job was run.

**Deltas and loose ends**

- Role/archive/partition grant drift is DB-03. Guide/manual build text is stale because Compose now owns the build.
- Reports still uses legacy `aux:${IMAGE_TAG}`. Monday now owns a separate image, so no other in-scope consumer remains; excluded workloads must be inventoried before renaming it to `reports:${IMAGE_TAG}` and rejecting stale legacy-tag substitution.
- `index.js:60-65` imports `dbInsertLogEvents` but never calls it; no Reports rows establish the “every job self-logs” contract.
- `email/send_email.js:33-52` logs recipient/full SMTP result, launches DB status updates without `await`, and swallows failures.
- The `monday` branch at `index.js:161-166` does not return, then continues into a generic query map with no `monday` query at lines 171–194.
- Top-level catch returns success; configured `TWILIO_*` keys have no tracked source/dependency consumer.
- Local docs are absent, `short-uuid` appears unused, and there are no tests/CI. Dependency advisory status is unverified because a network audit was not authorized for this repo.

**Recommended closure:** Make role reconciliation transactional/lifecycle-aware; add awaited run logging and correct nonzero/finally handling; await notification status, minimize mail metadata, return after Monday flow, remove unused secrets/dependencies, add tests, and update guide to `docker compose build app` with provenance. After a complete consumer inventory, rename the legacy `aux` image to a Reports-specific tag.

## Confirmed aligned and healthy controls

These are meaningful controls worth preserving; they do not offset the critical findings.

- Docker `29.4.3` and Compose `v5.1.3` match the reference. Docker, containerd, and cron services are enabled/active. Docker root is `/var/lib/docker`.
- Shared top-level directories are correctly numeric-owned `root:docker` and setgid as the guide currently specifies; `svc` UID 105 and Docker GID 987 match. The security issue is the overly broad ACL/group model, not a numeric mismatch.
- All ten repository working trees were clean before this requested report was created. `.env` is ignored/untracked in current checkouts; no repository has ever tracked a live file literally named `.env` in the inspected reachable history. The committed example/script literals remain critical exceptions.
- Required environment keysets match their examples without blank/missing required keys in the checked groups. Expected host/image/ID settings compare equal without exposing values. Monday's duplicate `PG_SSL_PATH`, semantic database error, and Compose-altered endpoints are explicit failures, so key presence alone is not acceptance.
- All nine Compose definitions pass syntactic validation. Expected networks and image tags exist. Batch applications correctly have no long-running containers; a sampled Data Acquisition `compose run --rm` removed itself.
- Built application entrypoints drop to UID/GID `105:987`; recent GE/Philips logs corroborate that runtime identity. Default AppArmor/seccomp/cgroup namespace protections are active and persistent containers are not privileged.
- Production dependency caches match every non-development lockfile entry for repos with lockfiles: no missing, version-mismatched, or extraneous production packages were found.
- Node syntax and Bash syntax checks completed without failures in the sampled/reachable application source sets.
- PostgreSQL is ready on a named volume/network with `restart=unless-stopped`. SSL is enabled, password encryption is SCRAM, TLS minimum is 1.2, and a safe `verify-full` probe negotiated TLS 1.3 with a modern cipher. The certificate SAN covers internal tested names and expires in May 2029.
- Effective PostgreSQL HBA contains a valid `hostssl ... scram-sha-256` catch-all; an unencrypted network-path probe was rejected. Local/loopback trust remains local. `public` cannot create database/schema objects.
- Dedicated non-superuser roles exist for Reports and the separately scoped dashboard/incident workloads. Active dashboard sessions use TLS. Reports itself is a positive example of CA-mounted fail-closed TLS.
- PostgreSQL durability basics and housekeeping are on: `fsync`, full-page writes, synchronous commit, and autovacuum. No invalid/unready indexes, unvalidated constraints, deadlocks/conflicts, dangerous XID age, replication lag, or slots were detected during the audit.
- All four Redis containers are healthy, persistent, non-root, correctly volume-mounted, and have matching read-only config content with working AOF/RDB status. Preserve these properties when closing exposure/auth gaps.
- The only PostgreSQL dump passes archive-list parsing and all four Redis RDB files identify as valid format. This proves structural readability only, not recoverability.
- Current root capacity/inode use is not an emergency: approximately 41% block use, about 1.2 TB free, and roughly 1% inode use.
- RPP acquisition-data mounts are read-only. Data Acquisition intentionally mounts its acquisition data store read-write. Reports' CA mount is read-only.
- Backup/prune scripts use reasonably narrow filenames/patterns. Preserve their scoping while adding private creation, scheduling, atomicity, monitoring, and restore testing.

## Prioritized remediation roadmap

### Phase 0 — Immediate containment (same day)

- Execute SEC-01/SEC-02 credential rotation and session invalidation as a coordinated fleet event; protect live/archived secrets first and sanitize history only after revocation.
- Recreate Redis without host ports and deploy authenticated ACLs; separately verify firewall/NSG/DOCKER-USER policy.
- Set Monday's database to `staging`, preserve raw `$` values for Monday/Part Source, and create the Part Source output mount before any manual run.
- Remove/disable active xtrace/decrypted-credential printing; restrict cron mail and relevant logs pending review.
- Assign incident/change owners for partition deadline, backup installation, and Philips retention so none is lost behind the credential response.

### Phase 1 — Within seven days

- Install monitored, private, atomic backup and prune timers; copy backups off-host; schedule an isolated restore rehearsal.
- Implement explicit job outcomes/nonzero exit/finally cleanup and alerts for Data, GE, Philips, Siemens, Part Source, and Reports. Triage the current high-error systems after semantics are reliable.
- Fix Philips assignment/error-import/historical-replay defects, command/SQL injection surfaces, unquoted wrappers, and Redis lifecycle. Add regression fixtures before resuming affected paths where pausing is operationally acceptable.
- Start the controlled batched `log.saved_files` backlog purge with capacity/WAL/lock metrics after retention approval.
- Correct `.env`, backup, raw acquisition, export, SSH, and log permissions; separate app runtime data access from Docker administration.
- Add an allowlisted `.dockerignore` everywhere and rebuild from sanitized, reviewed source with revision labels.

### Phase 2 — Within 30 days

- Complete per-app least-privilege role rollout with CA mounts and fail-closed `verify-full`; remove all helper fallback paths and add positive/negative grant tests.
- Rewrite `pg_manage_v2` around preflight, staged/atomic loads, reconciliation, rollback, and verified TLS.
- Make app code/dependencies immutable/read-only at runtime; narrow write mounts; remove unsafe legacy root services.
- Add `pg_db` health/dependency semantics and investigated resource policy; enable query/temp observability in a planned restart and tune from evidence.
- Add Redis environment network isolation, client timeouts, measured memory policy, and persistent host kernel settings.
- Pin base images/digests, add lockfile for `pg_manage_v2`, remove unused packages, remediate tested dependency findings, and introduce CI/SBOM/secret scanning.
- Reconcile branch upstreams and publish a release manifest containing repo SHA, clean state, image ID/digest, and deployment timestamp.

### Phase 3 — Deadline work and resilience

- **Before 2026-10-01:** deploy and verify the idempotent partition manager with a multi-month horizon and integrated grants/archive lifecycle. Target completion well before September ends.
- Define RPO/RTO; add globals/config recovery and, where required, WAL archiving/PITR/replica and data-checksum strategy.
- Complete reboot recovery, backup restore, Redis restore, and failure-injection rehearsals; record results.
- Decide whether Monday, Part Source, Reports, Siemens, and Philips cleanup remain manual or become scheduled; document one canonical answer and remove conflicting app-local instructions.

## Required changes before publishing the guide as version 2.1

1. **Freeze a release manifest:** authoritative branch, upstream, reviewed SHA, image digest, required environment schema, and build owner for every app.
2. **Separate core and optional scope:** keep these ten apps in the executable baseline; move excluded/ad hoc workloads to explicitly optional annexes.
3. **Replace the shared-permission model:** distinct administrator and app-runtime groups; per-type directory/file modes; `umask 077` for secrets/backups; no recursive executable-bit broadening.
4. **Add a complete secrets lifecycle:** approved store, protected injection, interactive DB role rotation, consumer inventory, session invalidation, history/artifact response, and automated scanning. Remove all password-on-argv instructions.
5. **Make PostgreSQL declarative and secure from first start:** tracked Compose/systemd owner, TLS/HBA before publication, private binding, password-file metadata assertion, key delivery without host UID collision, healthcheck, role/grant/partition/recovery steps.
6. **Replace the Redis section:** no host ports, separate environment networks and/or strict ACL identities, disabled default user, authenticated healthchecks/backups, kernel prerequisites, persistence/restore testing, and explicit firewall validation.
7. **Replace presence-only app environment checks:** detect duplicate keys, semantic database names, required paths, CA existence, byte-for-byte `$` fidelity, and redacted live connection/grant results.
8. **Make external side effects explicit:** version an endpoint/account/data-flow manifest, separate production/test credentials, enforce egress, and require a dry-run or approved mutation intent.
9. **Update build/entrypoint sections:** Acumatica, GE, and Reports are Compose-owned builds now. Require lockfile installs, allowlisted contexts, revision labels, non-root/read-only smokes, and exact image IDs.
10. **Make scheduling executable:** install application and maintenance schedules idempotently; include persistent/catch-up semantics, locks/timeouts/final states/alert routing; designate manual-only jobs explicitly; add partition and safe Philips retention maintenance.
11. **Make recovery an acceptance gate:** private/atomic backups, globals/configs, encryption/off-host copy, freshness alerts, isolated restore, measured RPO/RTO, and reboot recovery.
12. **Version one canonical runbook:** remove or replace conflicting RPP setup docs, Monday process schedule, Redis README text, and resolved follow-ups. Generate fragments where duplication is unavoidable.

## Expanded release/server acceptance checklist

The current guide's lines 900–909 are too narrow. The following should produce timestamped evidence and fail closed.

| Acceptance control | Current audit state |
|---|---|
| Every repo is on the manifest branch/SHA, clean, freshly fetched, and has the intended upstream | **Partial/Fail:** clean and cached refs match; branch table is stale, most upstreams absent, no network fetch |
| No reachable ref contains a non-placeholder credential; entropy/provider-pattern/history scan and explicit placeholder allowlist pass across all files/objects | **Fail** |
| Live/archived secrets and dumps are not accessible to `other`; private creation umask passes | **Fail** |
| Intended app identities can read only their required secret input; host-only secrets remain `0600` | **Fail/Not implemented** |
| Raw acquisition/output/log/mail artifacts follow classified access/retention rules and deny unrelated identities | **Fail/Unverified classification** |
| Compose emits zero warnings and preserves a literal-dollar sentinel byte-for-byte in each process | **Fail:** Monday/Part Source changed; Acumatica warns |
| Every context is allowlisted and excludes `.env`, VCS, logs, output/data, keys, and backups | **Fail** |
| Exact image ID/digest maps to a reviewed SHA/SBOM and approved base digest | **Fail/Unverified** |
| Container effective UID/GID is intended and no workload is privileged | **Pass** for inspected supported services |
| App-runtime identities are not in the host Docker group and cannot open the Docker socket; approved deploy admins can | **Fail:** runtime and Docker file-sharing roles are not separated |
| Source/dependencies/rootfs are read-only; only declared output paths are writable | **Fail** |
| Every bind source exists before Compose with the expected file/directory type, numeric owner, mode, and ACL; no auto-created path is accepted | **Fail/Not encoded** |
| UID 105 can create/append/rotate every declared runtime output; all required directories exist | **Fail:** central logs and Part Source `files/` |
| PostgreSQL is ready, TLS/SCRAM active, plaintext network path rejected, SAN/expiry valid | **Pass** |
| PostgreSQL is privately bound/firewall-restricted and effective root-only rules/NSG are evidenced | **Unverified/Partial:** all-interface listener; policy inaccessible |
| No direct PostgreSQL password is present in container metadata; secret delivery is protected | **Fail** |
| TLS private key is unavailable to unintended host identities | **Fail:** UID 999 collision |
| Every app role is non-superuser, uses `verify-full`, has required grants, and fails negative tests | **Fail:** only Reports pattern substantially complete; its grants drift |
| Database schema/table/sequence/row counts/checksums reconcile after migration | **Unverified/Not implemented** |
| Every partitioned parent has the required future horizon; rolled-back boundary insert succeeds | **Fail:** all end 2026-10-01 |
| Redis has no published host port and anonymous/cross-environment access is denied | **Fail** |
| Redis persistence, authenticated backup, and isolated restore pass for all four instances | **Partial/Unverified:** persistence healthy, restore not run |
| `vm.overcommit_memory`, THP, backlog, resource/eviction policy match documented decisions | **Fail/Partial** |
| Backup/prune/partition timers are installed with catch-up semantics; a simulated missed window and last-success/freshness/size alerts pass | **Fail** |
| Encrypted off-host PG globals+DB and Redis recovery completes inside RTO/RPO | **Fail/Unverified** |
| Every persistent container has effective bounded log rotation; disk/inode alarms pass | **Fail** |
| One non-destructive job per app family reports a correct success; injected failure returns nonzero and is alerted | **Fail/Unverified** |
| External endpoints/accounts are classified; staging dry-run/test identities cannot mutate production without recorded approval | **Fail/Unverified** |
| Dependency/image advisory policy, lockfiles, tests, and CI gates pass | **Partial/Fail** |
| Host-local operational scripts/configs match a versioned source and approved checksum/mode | **Fail:** current `/opt/resources/scripts` installation source is not reproducible |
| Host timezone is UTC, NTP synchronization is healthy, and loss is alerted | **Partial:** UTC passes; synchronization unverified |
| Encryption-at-rest evidence covers root/`/opt`, backup disks, snapshots, and off-host copies | **Unverified** |
| Reboot recovers Docker, PostgreSQL, Redis, timers, networks, mounts, and health in order | **Unverified** |

## Evidence and methods

The audit used the following non-mutating or self-cleaning checks:

- **Documentation/source:** line-by-line reference mapping; Compose/Dockerfile/entrypoint/package/README/schedule/SQL/shell/JS inspection; code-reference searches; duplicate/dead environment-key analysis.
- **Git:** status, branch/upstream, local/cached-origin tip comparison, blame/containment, ignored/tracked-file checks, reachable-history pattern scans. Results reported file/key/type only; secret values were not emitted.
- **Filesystem:** numeric `stat`, ACLs, parent traversal, file ages/counts/sizes, required directory and mount checks. Sandbox namespace artifacts were cross-checked to avoid falsely reporting shared directory ownership.
- **Docker:** version/info, image/network/container metadata, sanitized environment key inspection, Compose validation, desired/runtime label hash comparison, mount/config hashes, log options, health/restart/resource/security settings, and isolated `--rm` identity/writability/config-fidelity smokes.
- **PostgreSQL:** read-only catalog/settings/statistics/privilege/partition queries; `SELECT 1`; TLS and no-encryption probes; dump archive-list check. No business mutation or restore was performed.
- **Redis:** metadata-only/key-count queries, anonymous PING, ACL/protected-mode/auth flag inspection, persistence/status checks, configuration hash checks. No application keys were read.
- **Operations:** user/root/system cron and timer inventory, installed-versus-canonical schedule comparison, backup/log artifact inspection, active process spot check, disk/memory/process metadata.
- **Code/dependencies:** Node/Bash syntax checks, lockfile/cache reconciliation, direct-import review, and point-in-time production advisory audits where permitted.

## Limitations and explicitly unverified items

- **Remote Git freshness:** cached origin refs were inspected but no network fetch was performed. Git hosting PR refs, forks, mirrors, caches, artifacts, and other clones were not accessible.
- **Network perimeter:** listeners were inspected. Root iptables/ip6tables/DOCKER-USER rules and Azure NSG policy were not readable; no external public-port probe was attempted. Do not infer either public exposure or adequate containment from this report alone.
- **Recovery:** no full PostgreSQL restore, globals/role recovery, Redis restore, failover, reboot, or off-host recovery was performed. Format checks are not recovery evidence.
- **Business endpoints/jobs:** no live Acumatica, Monday, HCA, SMTP, SFTP, or external equipment call and no mutating manual business job was executed. Confirmed effective-env corruption was not exercised against the upstream systems.
- **Security scanning:** gitleaks, TruffleHog, Semgrep, ShellCheck, Hadolint, Trivy, Grype, and Docker Scout were unavailable. Custom history/pattern checks and final-layer equality scans cannot prove absence. RPP/Reports online advisory state remains unknown; core app results are point-in-time only.
- **Database impact:** Reports parent-table access may make missing child grants non-impacting for current parent queries; archive excess grants are confirmed. Event-bearing run counts do not independently prove whole-job failure.
- **Temporal observations:** process-overlap, CPU, memory, disk, container state, and cached upgrade results are snapshots. No long-duration concurrency test or host reboot was run. The prior PostgreSQL OOM cause is unknown.
- **Certificates:** tested internal SAN/expiry/verification passed. Public-IP SAN freshness was not independently compared with the current Azure address.
- **Excluded apps:** no conclusions are made about the quality/security of excluded apps. Their containers/files were not scored except where shared host state affected the in-scope suite.

## Bottom line

The suite has a coherent foundation and several strong controls—especially working PostgreSQL TLS, reproducible numeric runtime identity, healthy Redis persistence, clean pre-report working trees, and valid Compose definitions—but it is currently operating with a fleet-wide compromised database credential, unsafe local secret permissions, unreconciled unauthenticated Redis publication, no current backup/prune automation, and known near-term data/availability defects. Those conditions preclude calling the present document a secure one-stop build.

The correct order is **contain secrets and exposed services, restore trustworthy recovery and job outcomes, fix imminent data-path defects, then reconcile and reissue the guide with executable acceptance evidence**.
