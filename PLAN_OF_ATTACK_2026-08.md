# Plan of Attack — Acquisition Server & Application Suite

**Prepared:** 2026-08-14
**Sources:** Two independent audits, cross-verified against the live server on 2026-08-14
(`AUDIT_RECONCILIATION_FINDINGS_2026-08-14.md` — the full technical audit;
`AUDIT_RECONCILIATION_VERIFIED_2026-08-14.md` — independent verification of it. Finding IDs like
SEC-01 or DB-01 in this plan refer to those documents.)
**Owner:** Matt Teixeira (items marked 👥 benefit from a second person)

---

## The goal, in one paragraph

We want one trusted blueprint for building these servers. The **staging server** should be the
reference copy — the "golden image" — and the setup document
(`docs/docker_server_full_setup_2.0.md`) should be the recipe that reproduces it exactly, so a new
production or development server can be built from the document alone. Today, three things disagree:
the document (last updated July 27), the code repositories (which moved on July 28 and August 6),
and the running server (parts of which predate both). On top of that, the audits found real
security and reliability problems. This plan fixes the problems, brings all three back into
agreement, and finishes with a rewritten document — version 2.1 — that has been **proven** by
building from it.

**Scope boundary:** the `odd-jobs` app belongs to Jonathan and is **out of bounds** — nothing in
this plan modifies it. Where its work intersects ours (database partition upkeep, item 1), this
plan only verifies and monitors, read-only, and routes anything else through Jonathan.

## The October 1 concern — stood down (corrected 2026-08-14)

> ⏰→✅ The audits warned that the database's monthly "bins" (partitions) end October 1 with "no
> maintenance job installed" — a fleet-wide outage. Follow-up investigation found the bin-maker
> **does exist**: Jonathan's **odd-jobs** app runs partition upkeep (create next month's bins +
> archive old ones) on the 1st of every month, scheduled under the `svc` service account — one of
> the two places the audits couldn't see. Its August 1 run verifiably succeeded and created all 24
> September bins. **There is no emergency.** What remains is item 1: confirm ownership with
> Jonathan and add an independent safety check — because if that one monthly run ever fails, it
> currently fails *silently*, and an October-style outage would still follow.

## The plan at a glance

| # | Item | Type | Phase | Effort | Finding |
|---|---|---|---|---|---|
| 1 | Verify partition upkeep (owned by odd-jobs) + add an independent safety check 👥 | 🤝 Verify | 1 | ~2 hrs | DB-01 |
| 2 | Change the master database password; remove it from the code repos | 🔒 Security | 1 | ~½ day + evening window | SEC-01/02 |
| 3 | Rebuild the four Redis containers to match their blueprint | 🔒 Security / drift | 1 | ~½ day | REDIS-01/02 |
| 4 | Switch on the backups that were built but never scheduled | 🛟 Safety net | 1 | ~½ day | OPS-01/02 |
| 5 | Un-break the two manual apps (Monday, Part Source) | 🔧 Correctness | 1 | ~2 hrs | REL-02 + app findings |
| 6 | Fix job-log routing (the pair of masked problems from Aug 6) | 🔧 Reliability | 1 | ~1 hr | OPS-05 |
| 7 | Housekeeping: remove five stale leftover containers | 🧹 Hygiene | 1 | 15 min | (new) |
| 8 | Fix the known Philips code bugs | 🐛 Correctness | 2 | 1–2 days | Philips findings |
| 9 | Make jobs fail loudly instead of reporting false success | 🐛 Reliability | 2 | 2–3 days | OPS-03 |
| 10 | Put the database container itself under version control, with a proper secret | 🔒 Security / repro | 2 | ~½ day | SEC-05/06, DB-04 |
| 11 | Keep secrets and logs out of Docker image builds | 🔒 Hygiene | 2 | ~1 hr | SEC-10 |
| 12 | Rewrite the setup document as version 2.1 | 📘 The goal | 3 | 2–3 days | doc-staleness findings |
| 13 | Prove it: run the acceptance test 👥 | ✅ The proof | 3 | 1–2 days | — |
| 14 | Scheduled longer-term debt (tracked list) | 📋 Ongoing | 4 | ongoing | remainder |

**Suggested calendar:** Phase 1 = week of Aug 17. Phase 2 = week of Aug 24. Phase 3 = first half of
September, targeting **doc 2.1 signed off by ~Sep 12**. (The former Oct 1 partition emergency
stood down on Aug 14 after discovery that odd-jobs already handles it — see item 1.)

---

## Decisions needed (make these first — several items wait on them)

| ID | Decision | Recommendation |
|---|---|---|
| D1 | Should Redis get passwords now (item 3) or as a follow-up? | **DECIDED 2026-08-17: auth added during the rebuild** — one maintenance window instead of two. |
| D2 | How long must raw Philips machine files be kept? (Feeds the 130 GB cleanup, item 14c.) | **Historical precedent found (2026-08-17):** the old server ran a 48-hour retention job every 30 min (`delete_old_db_files` in monolithic hhm_rpp's crontab) that was never carried over when the app split in three — that's the direct cause of the 130 GB bloat. **DECIDED 2026-08-18: 48 h confirmed.** Item 8b drafted (batched purge + reworked job + cron line); purge awaits a go-ahead. |
| D3 | After the password change, do we also scrub the old password out of Git *history*? | Yes, but only after rotation makes the old value worthless; then it's cleanup, not emergency. |
| D4 | Where do off-server backup copies go? (Azure storage account is the natural fit.) | Pick a target; until then backups remain on-server, which protects against mistakes but not server loss. |
| D5 | Should staging's job logs route to the central log folders (`RUN_ENV=staging`)? | **DECIDED 2026-08-17: yes, flip it** — permissions fixed first, one app at a time (item 6). |

---

## Phase 1 — Stop the clocks (week of Aug 17)

### 1. Verify partition upkeep (owned by odd-jobs) and add an independent safety check 🤝

- **The issue (DB-01 — corrected 2026-08-14):** Both audits reported that the database's 24 binned
  tables have bins only through September and that "no maintenance job is installed," predicting a
  fleet-wide October 1 failure. Follow-up investigation found the maintenance **does exist**:
  Jonathan's **odd-jobs** app runs a create-and-archive partition job (`pg-part-arch`) on the 1st
  of each month, scheduled under the `svc` service account. The audits missed it because that
  account's schedule requires root to read, and odd-jobs was excluded from their scope. The
  August 1 run is verified end-to-end: its log shows both steps succeeding, and all 24 September
  bins exist in the database. "Bins end October 1" is simply what a healthy
  build-next-month-on-the-1st system looks like when observed in August — not a cliff.
- **What still deserves attention (without touching odd-jobs):** The safety margin is one month,
  and the scheduled run fails *silently* — its output is discarded, and per odd-jobs' own to-do
  notes a failed job does not signal failure outward. If the September 1 run breaks, nobody would
  know until everything stops on October 1. There is also no catch-all fallback bin, and one
  side-effect lands in our court: the reports app's database permissions drift each month as bins
  are created and archived (finding DB-03).
- **The fix (boundary-respecting):**
  1. **A 15-minute conversation with Jonathan** 👥 — confirm he owns this and hand him the audit
     observations that concern his app: the silent-failure mode, the one-month horizon, and a
     stale note in his own docs claiming the released job is disabled (it isn't — that note
     predates his July 28 fix). What, if anything, he changes is entirely his call.
  2. **An independent, read-only watchdog that we own:** a small scheduled check a few days after
     the 1st of each month — "does every binned table have next month's bin?" — that raises an
     alert if not. This monitors odd-jobs' *outcome* in the shared database; it never touches its
     code or schedule.
  3. **Tidy our own house:** data_acquisition carries a stale May 26 copy of the partition SQL
     (part of what misled the audits). Remove it or mark it reference-only, pointing to odd-jobs
     as the owner. Fold the reports permission upkeep into the monthly rhythm (Phase 4a).
  4. **First live check:** in the first week of September, confirm the October bins appeared.
- **Done when:** Jonathan has confirmed ownership; the watchdog has run once and correctly alerts
  on a simulated gap; October bins are verified in early September.

### 2. Change the master database password and get it out of the code repos 🔒

- **The issue (SEC-01, SEC-02):** The database's all-powerful administrator password is pasted —
  as a "commented-out example" — in files committed to four code repositories, and eight of the ten
  apps log in with it. Separately, an SFTP password and an old service URL with a password baked in
  are also committed. Anyone with access to those repositories effectively holds the keys to all
  our data.
- **Why it matters:** A shared admin password committed to source control is the single worst habit
  a security review can find. Context that keeps this out of panic territory: the server is **not
  reachable from the internet** (verified — no public IP), and the repositories are private. So
  this is a *planned, careful* change — but one that must not wait.
- **The fix:** One coordinated evening: set a new database password (entered interactively, never
  typed into a command line where it gets recorded); update the configuration of all eight apps;
  disconnect any sessions still using the old password; then immediately smoke-test one job per
  app. Same evening: rotate the SFTP account and the old URL account. Then scrub the five files and
  one script that contain the values, and add an automatic "secret scanner" so a committed password
  can never slip through again. Git-history scrubbing follows per decision D3.
- **Done when:** The old password no longer works anywhere; a scan of every repository finds no
  live credential; the next full cycle of scheduled jobs runs green.

### 3. Rebuild the four Redis containers to match their blueprint 🔒

- **The issue (REDIS-01, REDIS-02):** Redis is the fast "noteboard" apps use to remember where they
  left off between runs. The four running Redis containers date from July 27 and still expose
  themselves to the whole network **with no password** — anyone on the internal network can read or
  erase everything. The blueprint in the repository was fixed (network doors removed), but the
  running containers were never rebuilt, so what's running matches neither the blueprint nor a safe
  design. Two operating-system settings Redis needs for reliability are also unset.
- **Why it matters:** Beyond the security gap, this is *drift*: the running system silently
  disagrees with its own source of truth — exactly the disease this whole plan exists to cure. And
  the next innocent `docker compose up` would change behavior by surprise.
- **The fix:** Take a verified backup first (item 4's script, run by hand once). Then recreate the
  four containers from the current blueprint — after which only apps on the internal Docker network
  can reach them. Apply the two OS settings so they survive reboots. Add passwords per decision D1.
  Confirm each instance still has its data (key counts match the backup).
- **Done when:** No Redis ports appear on the host; an anonymous connection attempt from the server
  itself is refused; every app's scheduled jobs still run green; settings persist after reboot.

### 4. Switch on the backups that were built but never scheduled 🛟

- **The issue (OPS-01, OPS-02):** Backup and log-cleanup scripts were written on July 27 — and
  never scheduled. The **only** backup of the database is from July 27 and is now six weeks stale.
  Log files (69,000+ files, ~4 GB) grow without pruning, and Docker's own container logs have no
  size cap configured.
- **Why it matters:** Right now, a bad mistake or disk failure loses six weeks of data. A backup
  system that exists but isn't running is the most dangerous kind — everyone assumes it's there.
- **The fix:** Install the two ready-made schedule lines (nightly database + Redis backup, nightly
  log pruning). Apply the prepared Docker log-rotation config during a quiet window. Add "newest
  backup is less than 25 hours old" to the health checklist. Off-server copies follow decision D4.
  - *Restore rehearsal waived (owner decision, 2026-08-17)* due to time/resource cost. Partial
    assurance remains: every dump is automatically verified as structurally readable
    (`pg_restore --list`) before the script reports success. A full restore remains unproven until
    the Phase 3 acceptance run (rebuilding dev from the doc will exercise it naturally).
- **Done when:** A dated backup file appears every morning; the prune log shows nightly runs;
  container logs have a size cap.

### 5. Un-break the two manual apps (Monday, Part Source) 🔧

- **The issue (Monday/Part-Source findings, REL-02):** The Monday.com sync app is pointed at a
  database named `dev` — which does not exist on this server — so its next run fails instantly. The
  Part Source app is missing the `files/` folder it writes to (the setup doc says to create it;
  the live server drifted), so its next run also fails instantly. Additionally, Docker Compose is
  quietly mangling web addresses in both apps' configuration because it treats `$` characters as
  variables to substitute.
- **Why it matters:** These are the two apps most likely to be run by hand on short notice, and
  both fail on step one. The `$`-mangling means the configuration an app *receives* is not the
  configuration you *wrote* — a silent-corruption class of bug.
- **The fix:** Point Monday at the real `staging` database and delete its duplicated settings.
  Create the Part Source folder with the right ownership. Escape the `$` characters (or move those
  values out of Compose's hands) and then verify, from inside a container, that the values arrive
  byte-for-byte intact. Add "Compose reports zero warnings" to the checklist.
- **Done when:** A dry run of each app connects and produces output; `docker compose config` is
  warning-free for every app.

### 6. Fix job-log routing — the deferred pair from Aug 6 🔧

- **The issue (OPS-05):** Staging's apps are all labeled `RUN_ENV=dev`, which routes their per-run
  log files *inside each code repository* instead of to the central `/opt/run-logs` folders. Those
  central folders, meanwhile, are owned by root and unwritable by the apps — a second bug the first
  one has been hiding. This pair was knowingly deferred on Aug 6.
- **The fix:** In this order: fix ownership/permissions on the four central folders, *then* flip
  staging's apps to `RUN_ENV=staging` (decision D5). Doing only the flip would break logging
  everywhere at once.
- **Done when:** After the next scheduled cycle, fresh log files appear under
  `/opt/run-logs/<app>/` for all four affected apps.

### 7. Housekeeping: remove five stale leftover containers 🧹

- **The issue (new finding):** Five containers from one-off manual runs (three imprivata-poc, two
  ops-dashboard) have been sitting alive for 4–7 weeks, possibly holding database connections.
- **The fix:** Remove them; always use `--rm` for one-off runs; add "no stale run containers" to
  the checklist. **Done when:** `docker ps` shows only the intended long-running services.

---

## Phase 2 — Make the apps honest, and the database reproducible (week of Aug 24)

### 8. Fix the known Philips code bugs 🐛

- **The issue (Philips findings):** Four verified defects in the Philips pipeline, all on scheduled
  paths: **(a)** a one-character typo (`=` where `===` belonged) makes *every* machine take a
  special-case path meant for one specific machine — and overwrites the machine's ID in the
  process; **(b)** the error handler in that same file calls functions that don't exist there, so
  when something goes wrong, the error *about the error* hides the original problem; **(c)** a
  leftover debug line re-extracts data from a hard-coded April 2023 date on **every** run, risking
  duplicated historical data; **(d)** two places build shell commands from data values — an
  injection risk — and should use safe APIs instead.
- **The fix:** Correct the comparison and imports; delete the 2023 line; replace shell-building
  with safe calls; then spot-check the affected aggregate tables for damage the typo may have
  caused. Add small regression tests so these can't quietly return.
- **Done when:** Fixes deployed; one full scheduled cycle runs clean; aggregate spot-check
  documented.

### 8b. Restore the lost `saved_files` retention job ⭐ COMMITTED FOLLOW-UP

- **The issue (DB-05 — root cause identified 2026-08-17):** The old server pruned the raw-file
  table every 30 minutes to a 48-hour retention (`00,30 * * * * cd /home/prod/hhm_rpp && npm run
  delete_old_db_files`). That cron line was never migrated when `hhm_rpp` split into the three
  GE/Philips/Siemens apps, so the table has grown unchecked to 130+ GB — quintupling backup
  size/time (why nightly dumps temporarily exclude it) and consuming disk.
- **The fix — two distinct parts, in order:**
  1. **Backlog first, carefully:** ~40+ days of accumulated rows cannot be deleted in one shot
     (the current `clear_old_db_files.js` does exactly that and swallows errors — the audit warns
     against installing it unchanged). Purge in small, committed, monitored batches.
  2. **Then the steady-state job:** rework `delete_old_db_files` for the 3-app world — decide its
     new home (Philips owns the table's data, so its repo is the natural candidate), schedule it
     every 30 min as before, with a lock, real error propagation, and a self-log row.
  3. Afterward: remove the `--exclude-table-data` flag from `backup.sh` so nightly backups are
     complete again.
- **Done when:** table holds ≤48 h of data (or the confirmed D2 window); job runs on schedule with
  visible outcomes; backups re-include the table at sane size.

### 9. Make jobs fail loudly instead of reporting false success 🐛

- **The issue (OPS-03):** Many jobs catch their own failures, log them somewhere nobody looks, and
  then report "success" to the scheduler. In the sampled window, **80%+ of data-acquisition runs
  contained errors** — some tolerated and normal (a site being offline), some real failures — and
  the system cannot tell the difference, so no one is alerted to anything.
- **Why it matters:** Every other reliability effort depends on being able to trust a green
  checkmark. This is also why the error volume must be *triaged after* the semantics are fixed —
  today's numbers mix harmless noise with real breakage.
- **The fix:** Give every job an explicit final state — success / partial / failed — with counts;
  make fatal errors exit nonzero so the scheduler and future alerting can see them; close database
  and Redis connections properly on the way out. Do `data_acquisition` first as the template, then
  copy the pattern to GE, Philips, Siemens, Part Source, and Reports. Then triage the persistent
  offenders the new reporting reveals.
- **Done when:** A deliberately-broken test job produces a nonzero exit and a "failed" record; the
  daily error volume has been triaged into "expected" vs "fix" lists.

### 10. Put the database container under version control, with a proper secret 🔒

- **The issue (SEC-05, SEC-06, DB-04):** The main database container was launched by hand long ago:
  its admin password sits readable in the container's metadata; it has no health check; no memory
  guardrails (it was OOM-killed once in June and nobody was notified); and the TLS private key on
  disk is accidentally readable by the Datadog monitoring agent because of a numeric user-ID
  collision.
- **The fix:** Write the database's runtime definition into a tracked Compose file — password
  supplied via a root-only secret *file* (never an environment variable), a health check, sensible
  memory settings, and a key-delivery method that doesn't collide with host accounts. Recreate the
  container from that definition in a maintenance window (its data lives on a named volume and is
  preserved; item 4's backup runs first regardless). This also makes the database — the last
  hand-built piece — reproducible from the repo, like everything else.
- **Done when:** Container metadata shows no password; health check reports healthy; the definition
  lives in Git; the key is readable only by its intended user.

### 11. Keep secrets and logs out of Docker image builds 🔒

- **The issue (SEC-10):** The two repos that build Docker images (`data_acquisition`, `hhm_rpp_ge`)
  have no `.dockerignore`, so a build could sweep ~2 GB of configuration files, Git history, and
  logs into the image. **The fix:** Add allowlist-style `.dockerignore` files; rebuild after item 2
  so images are built from scrubbed source. **Done when:** Build context is a few MB and contains
  no `.env`, `.git`, or logs.

---

## Phase 3 — Rewrite the doc and prove it (first half of September)

### 12. Rewrite the setup document as version 2.1 📘

- **The issue:** The doc froze on July 27; the repos moved on July 28 (Redis ports) and Aug 6
  (host-identity parameterization). Its branch map, build instructions, and several sections are
  now wrong, and Phase 1/2 deliberately changed more.
- **The fix — the 2.1 change list:**
  - **Branch map:** all eight app repos → `STAGING_docker`; the two admin repos → `STAGING`; set
    upstreams so `git pull` works everywhere.
  - **Host identity:** document the Aug 6 convention — user/group IDs and image tags live only in
    each host's untracked `.env`; builds fail loudly if unset. Change the committed example files
    to placeholders (today they carry staging's real numbers, which would silently poison a new
    server — REL-07).
  - **Build matrix:** every image is now built by Compose (`acu-sync`, `monday`, `psp`, `aux` from
    reports, `hhm_rpp` from GE); delete the "do not build acumatica" and "build RPP by hand" text.
  - **Redis section:** rewritten for no host ports, the OS settings, the D1 password decision, and
    a safe restore procedure (the current text's restore steps can silently produce an *empty*
    Redis — REDIS-05).
  - **Database section:** the tracked Compose definition from item 10; password-file method;
    partition/bin lifecycle section with its checklist query; remove the two places that put
    passwords on command lines (SEC-09).
  - **Backups & schedules:** backups/pruning/bin-maker become *required, installed* steps with a
    proven restore — no more "proposed" files; `docs/schedules.md` stays the schedule manifest and
    gains the maintenance jobs.
  - **odd-jobs:** documented as the owner of monthly partition upkeep, with its schedule location
    noted. The doc's old "retire odd-jobs or bring it up to conventions" follow-up is resolved as
    **keep-and-document** — retiring it would silently end partition maintenance.
  - **Follow-ups section:** refreshed to the real remaining debt (Phase 4 below).
  - **Acceptance test:** expanded per item 13.
- **Done when:** 2.1 is merged and every command in it was executed at least once on this server.

### 13. Prove it: the acceptance test ✅ 👥

- **The issue:** A recipe nobody has cooked from is a guess. The old doc's acceptance list also
  checked that things *exist* but not that they *work* (a folder can exist and still be unwritable;
  a backup can exist and still not restore).
- **The fix:** A checklist run by someone who didn't write the doc (Jonathan is the natural
  candidate), ideally by rebuilding the dev server from doc 2.1 start to finish. The checklist, in
  plain terms: no secrets anywhere in any repo; zero Compose warnings and configuration arrives
  byte-for-byte; every app writes where it must as the service user; every binned table has ≥3
  months of future bins; newest backup < 25 hours old and a restore has been rehearsed; Redis
  unreachable anonymously; database password absent from container metadata; no stale containers;
  and a full reboot brings everything back without help.
- **Done when:** The checklist passes on staging **and** on a rebuild. At that moment,
  "build from the doc" and "clone staging" mean the same thing — the golden image exists.

---

## Phase 4 — Scheduled debt (30–90 days; tracked, not blocking)

These are real, agreed problems that should *not* delay the golden image. Each already has a recipe
or decision noted in the audit documents.

| Item | Plain-language summary | Depends on |
|---|---|---|
| a. One database account per app | Today 8 apps share the admin account. The doc already contains the proven per-app recipe (used 3×); roll it out app by app, least-critical first, with verified TLS. | Item 2 |
| b. Verified TLS everywhere | Most apps encrypt but don't *verify* who they're talking to; copy the fail-closed pattern already proven in Reports. | (a) |
| c. Philips 130 GB file-log cleanup | One table holds 130 GB of old raw file copies with no retention rule. After decision D2, delete gradually in small monitored batches — never one big delete, which could stall the database. | D2 |
| d. Stricter secret file permissions + a dedicated runtime group | Config files are readable by every account on the server; separate "can run apps" from "can administer Docker". | Items 2, 10 |
| e. Version pinning + automated checks (CI) | Pin base software versions; add automatic secret-scanning, config validation, and tests to every change. | Item 2 |
| f. Database tuning & query visibility | Turn on the query-statistics module (needs one planned restart), then tune from evidence; investigate June's out-of-memory kill. | Item 10 |
| g. Off-server encrypted backups | Copy nightly backups off this VM per decision D4. | D4, item 4 |
| h. Cron mail cleanup | 400 MB of job emails, some containing sensitive output; redact at the source, restrict, retain sensibly. | Item 9 |
| i. External-endpoint inventory | Some staging jobs talk to real production systems (Acumatica, Monday, SFTP). Write down every external touchpoint and which credentials/mode (read-only vs writing) each job should use per environment. | — |
| j. PROD server planning | Branches, cutover runbook, data governance — deliberately future work, unblocked once doc 2.1 is proven. | Item 13 |

---

## What could go wrong while executing (and the guardrails)

- **The password change misses an app** → that app fails on its next run. Guardrail: the audit
  already inventoried all nine places the credential is configured; rotate from that list and
  smoke-test each app the same evening.
- **The Redis rebuild loses state** → jobs re-process or miss data. Guardrail: backup first,
  record key counts before, compare after; the rebuild preserves the data volumes.
- **The log-routing flip breaks logging** → guardrail: fixed order (permissions first), verified
  on one app before the rest.
- **The database recreate goes wrong** → guardrail: data lives on a named volume that is not
  touched; fresh backup taken first; done in a quiet window with a written rollback (restart the
  old definition).
- **The September 1 partition run fails silently** → an October outage happens despite everything
  above. Guardrail: item 1's watchdog check in the first week of September, before relying on the
  new month.
- **General:** snapshot the schedule (`crontab`) before any edit — already standing practice — and
  log each completed item with its date in the table below.

## Progress tracker

| # | Item | Status | Date done | Notes |
|---|---|---|---|---|
| 1 | Partition upkeep verified (odd-jobs) + watchdog | ✅ Done | 2026-08-17 | svc-crontab schedule confirmed via sudo (14:00 UTC, 1st); watchdog built+tested+scheduled (3rd & 25th). Jonathan chat dropped by owner. Standing check: verify October bins early Sep |
| 2 | Password rotation + scrub | ✅ Done | 2026-08-17 | Rotated via \password + 9 env keys; pre-rotation sessions killed (incl. idle superuser conn from Jun 25); all 8 apps smoke-tested OK; 5 repos scrubbed + dead script deleted (commits = Matt). SFTP credential in psp history: vendor cannot rotate; history rewrite declined 2026-08-18 — **accepted risk** (repo access = the boundary); D3 moot with it. Still open: secret scanner (Phase 4e) |
| 3 | Redis rebuild | ✅ Done incl. auth | 2026-08-18 | Ports-off 8/17. Auth ACTIVE 8/18: requirepass on PROD/dev04/dev05 via root-only secret + fail-loud mount; STAGING deferred (odd-jobs has no client auth — Jonathan). Empirically proven: pw-client vs nopass-server hangs node-redis forever → server-first order is mandatory. Honest healthchecks (redis-cli exits 0 on NOAUTH). Two clean authed bursts verified; 1 transient error from the activation window itself. Kernel settings verified persisted (sysctl.d + THP unit, now tracked in redis-admin/host-setup) |
| 4 | Backups switched on (restore rehearsal waived → Phase 3) | ✅ Done | 2026-08-18 | Gate passed: first unattended 02:15 run OK — 4.0 GB / 15 min with saved_files excluded (vs 151 GB / 4.5 h full). Prune's first night freed 2.7 GB / 45k old files. Full reference dumps preserved outside retention. **Correction 8/18: "container logs capped" was NOT actually done** (daemon.json never applied) — closed same day via `logging:` blocks in tracked composes (pg_db, redis ×4, ops-dashboard; owner decision). backup.sh now does authenticated Redis SAVE with reply-checking. Maintenance scripts moved into owning repos (pg_manage_v2, redis-admin, data_acquisition) + cron repointed — /opt/resources/scripts retired as a script home |
| 5 | Monday / Part Source fixed | ✅ Done | 2026-08-17 | staging DB + dup/dead keys removed + $-escaping verified byte-for-byte in-container; Monday DB smoke passed; real job dry-runs deferred (external side effects) |
| 6 | Log-routing pair fix | ✅ Done | 2026-08-17 | 4 dirs fixed (Matt sudo) + UID-105 write-verified; 6 apps flipped to RUN_ENV=staging; GE verified end-to-end with real run |
| 7 | Stale containers removed | ✅ Done | 2026-08-17 | 5 running + 4 exited removed (incl. 2 accidental ops-dashboard duplicates holding DB connections); dashboard healthy after |
| 8 | Philips bugs fixed | ✅ Done | 2026-08-18 | 4 patches 8/17 (17/17 burst clean, 0 ReferenceErrors/allowlist rejections). Logcurrent cascade fix 8/18 (triage A2): 13:15 burst 17 runs, **zero ERROR events** — Philips noise floor now 0, any ERROR is real |
| 9 | Jobs fail loudly | ✅ Fleet-complete | 2026-08-17 | All 6 target apps live + burst/exit-3 verified (data_acquisition, philips, siemens, ge, psp, reports). Siemens/psp/reports fatal runs now DB-visible for the first time; reports monday fall-through bug fixed. Monday app already exited honestly — outcome-event parity is an optional later nicety |
| 10 | Database under version control | ✅ Done | 2026-08-18 | Swap executed 14:17 UTC (<1 min downtime, healthy in 8 s). All gates passed: no password in metadata (SEC-05), key root-only + dd-agent denied (SEC-06), healthcheck live (DB-04), non-SSL rejected. Bonus: `pg_stat_statements` preloaded+created in same restart (DB-06 → Phase 4f now has data). First post-swap cycle: 21 runs, 0 fatal |
| 8b | saved_files retention restored | ✅ Done | 2026-08-18 | Purge: 359,618 rows / ~135 GB in 1 h 24 m, zero anomalies (WAL pinned at 1 GB). Job live-verified + committed to philips (first proof run caught a t.none/pg_advisory_unlock bug — fail-loudly contract works); cron :05/:35 installed; first automated run success exit 0; backup exclusion removed (dumps ~10 GB tonight). VACUUM FULL 18:22: **141 GB → 5.8 GB in 161 s**, ~135 GB returned to the OS. pg_db recreated same window with the server-agnostic healthcheck |
| — | OPS-03 triage (new, from item 9's data) | ✅ First pass | 2026-08-18 | `TRIAGE_OPS-03_2026-08-18.md`: fix-list vs site-list split. Found 79-system credential-decrypt failure (now tracked to alert.offline_hhm_conn) and the July 7 event (23 systems / 21 sites dark — `JULY7_DARK_SYSTEMS.csv` for contract comparison) |
| 11 | .dockerignore added | ✅ Done | 2026-08-18 | data_acquisition + hhm_rpp_ge; probe-verified context 2.0 GB → 16 KB (2 files) |
| 12 | Doc 2.1 written | ✅ Done | 2026-08-18 | `docs/docker_server_full_setup_2.1.md` — every fact live-verified same day; owner review incorporated (four-instance Redis build, restored 5.6 SQL changelog for prod initiation, server-agnostic `<DB_NAME>`/identity table with matching code changes in backup.sh/watchdog/pg_db healthcheck). REL-07 fixed in all 8 repos. Committed & pushed. Remaining proof = item 13 acceptance rebuild on the fresh dev server |
| 13 | Acceptance test passed | ⏸ On hold (owner) | 2026-08-18 | Waiting for the dev server to be wiped and available; Matt will then build it from doc 2.1 top-to-bottom (checklist at the doc's end). Everything else in the plan is complete — this is the only remaining step to "golden image proven" |
| D1–D5 | Decisions recorded | ✅ Resolved/parked | 2026-08-18 | D1 executed 8/18 (auth live on 3 of 4 instances; STAGING accepted passwordless), D2 = 48 h, D5 = flip done. D3 **moot** (owner accepted the history credential as-is). D4 **parked by owner 8/18** — needs a team conversation; backups stay on-server until then (doc 2.1's backup section says so). No decision blocks anything actionable |

*When item 13 is checked, the goal is met: staging is the golden image, and the document is the
proof-tested recipe that reproduces it.*
