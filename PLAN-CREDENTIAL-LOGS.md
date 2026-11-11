# Plan: device credentials in run logs (hhm_data_acquisition)

Date: 2026-11-11 · Branch: `DEV` (uncommitted) · Investigation was read-only. Prod DB was probed
through `~/hep3/reports/sme_reports/ct/db.js` (`default_transaction_read_only=on`). Prod files
were read with counts only. No credential was printed, copied or decrypted. Every count
below comes from a pattern match, never from a value.

## 1. Summary

- **Credentials are logged on every collector run, not only when a script fails.**
  `exec_hhm_data_grab`, `exec_phil_cv_data_grab`, `exec_list_dirs` and the two
  `post_tunnel_reset` wrappers log their call note, including `args = [host_ip, user,
  pass, ...]`, before running the script. That goes to `util.app_run_logs.verbose_log`, the
  local run-log file and the console. Failures add a second copy (`err.stack` =
  `Error: Command failed: <script> <ip> <user> <pass> ...`) in `verbose_log` **and**
  `warn_error_logs`. This has been true since commit `5a71778` (2023-06-23, "Init logging").
- **Scope on prod:**
  - DB: **136,669 rows** hold credentials in the 14 tables counted so far (2025-10 → today),
    about 10,400 a month, all from this app (`data_acquisition`, called
    `hhm_data_acquisition` before 2026-03). Every other app has 0. Archive months 2025-03 → 09
    are still being counted (§2.2).
  Local run-log files: **372,952 of 1,143,764** hold credentials (2024-02 → today), detail in §2.2.
- **Fix (built, tested, uncommitted):** one shared redaction step. `decryptString` registers
  every value it returns; every log sink masks those exact values (`***`). That covers the DB
  insert, the run-log file, all `console.*` output and `stats.job_runs`. Callers are unchanged.
- **Clean-up (separate step, your call):** SQL and a file tool are ready and rehearsed
  read-only. §6 has the recommendation.
- **Rotation (your call):** §7 has the facts. Short version: for at least 29 months the
  credentials sat in clear text in places readable by the 2 DB roles with SELECT and by any
  of the 20 local accounts on vm-debian (run logs and `.env` files are world-readable). And
  the "encrypted" copies in `hhm_credentials` can be decrypted with a key that sits in the repo.

## 2. Where credentials reach a log or table

### 2.1 Paths (code)

| # | Sink | How | When | Code |
|---|---|---|---|---|
| L1 | `verbose_log`, run-log file | `cal` note `{…, execute_path, args}` with `args=[ip,user,pass,…]` | **every run** | `read/exec-hhm_data_grab.js:27-36`, `read/exec-phil_cv_data_grab.js:28-34`, `read/exec-list_dirs.js:29-34`, `read/post_tunnel_reset/exec-hhm_data_grab.js:11-16`, `…/exec-phil_cv_data_grab.js:15-20` |
| L2 | `verbose_log` **and** `warn_error_logs`, run-log file | `addLogEvent(E,…, error)` stores `err.stack`, which begins `Error: Command failed: <script> <args joined by spaces>` followed by stderr. The catch also reuses the outer `note`, so `args` appear a second time. | on script failure (non-zero exit, timeout) | `utils/logger/log.js:52-61`; catches at `exec-hhm_data_grab.js:174,224`, `exec-phil_cv_data_grab.js:176,228`, `exec-list_dirs.js:136`, `post_tunnel_reset/*:60/61` |
| L3 | console | `console.log(note)` with args (`exec-hhm_data_grab.js:34-35` every run; `post_tunnel_reset/*` "Bash Args"); `console.log(error)` in every catch prints stack + `cmd` + `stdout` + `stderr` | every run / failure | catches in all `read/exec-*.js` |
| L4 | console | explicit prints: `console.log(user)`, `console.log(pass)`; `console.log(system_creds)` (the encrypted row) | manual runs / every Philips MRI run | `jobs/hhm/run_manual.js:62-63`, `jobs/hhm/philips/philips_mri.js:41` |
| L5 | `stats.job_runs.error_message` | `error.message` of a top-level error | only if an exec error escapes the wrappers | `index.js:114` |
| L6 | process list (`ps`) | credentials are argv of the scripts and of `sshpass -p` / `lftp -c "open sftp://u:p@h"` / expect | while each script runs | all `read/sh/{GE,Philips}/*`, `Siemens/siemens_cerb*` (out of scope, §5) |

Things I checked that are **not** affected:
- The online-queue `connection_error` text: fixed strings from `util/tools/connection_regex.js`.
- Redis queues and `note.system`: system rows carry only `credentials_group` (an id).
- The collector scripts themselves: no `set -x`, no `echo` of args. `siemens_cv_logfiles_zip.sh`
  already passes the password via the environment (`LFTP_PASSWORD`).
- MMB, rsync and Althea paths: argv has host, user id and paths only (key-based ssh).
- `exec-tunnel_reset.js` (winston logger): dead code, required nowhere.
- `exec-ip_table.js`: calls `telnet_ip_tables.sh` with no args.
- `error.cmd` / `error.stderr` reach the DB only through `err.stack` (L2). `log.js` never
  serializes the Error object itself, but `console.log(error)` prints them (L3).
- Console output on prod: cron lines have no redirect and no `MAILTO`, and the box has no MTA,
  so cron output is discarded. Console leaks matter for DEV, manual and terminal runs.

### 2.2 Affected data on prod (counts only)

**`util.app_run_logs`** is range-partitioned by month: live partitions 2026-05 → 2026-11
(~56 GB). **`archive_util.app_run_logs_2025_03` … `_2026_04`** are 14 detached monthly tables
(~140 GB), same layout, still readable by the same roles. Nothing older remains in the DB.

Columns are `app_name text, run_id uuid, verbose_log json, warn_error_logs json,
inserted_at timestamptz default now()` (the task guessed four columns; there's also
`inserted_at`). No triggers. Only index: `inserted_at DESC`.

Counts per month for the collector app (substring match; a row can match several columns):

| Month | app_name | rows | `cmd_failed_any` | `cmd_failed_cred_script` | `args_logged` | `list_dirs` | **affected** |
|---|---|---:|---:|---:|---:|---:|---:|
| 2025-03 → 2025-09 | (archive) | _counting_ | | | | | _pending_ |
| 2025-10 | hhm_data_acquisition | 34,256 | 24,281 | 8,921 | 10,408 | 2,973 | **10,408** |
| 2025-11 | hhm_data_acquisition | 34,120 | 21,013 | 8,639 | 10,080 | 2,878 | **10,080** |
| 2025-12 | hhm_data_acquisition | 35,753 | 23,046 | 8,928 | 10,417 | 2,986 | **10,426** |
| 2026-01 | hhm_data_acquisition | 35,750 | 24,371 | 8,929 | 10,418 | 2,972 | **10,418** |
| 2026-01 | data_acquisition | 10 | 3 | 3 | 3 | 0 | **3** |
| 2026-02 | hhm_data_acquisition | 32,285 | 23,635 | 8,062 | 9,419 | 2,681 | **9,419** |
| 2026-02 | data_acquisition | 37 | 16 | 16 | 20 | 33 | **33** |
| 2026-03 | hhm_data_acquisition | 4,405 | 3,477 | 1,097 | 1,300 | 354 | **1,300** |
| 2026-03 | data_acquisition | 31,353 | 24,069 | 7,436 | 9,139 | 2,606 | **9,139** |
| 2026-04 | data_acquisition | 34,313 | 25,831 | 8,574 | 10,003 | 2,858 | **10,003** |
| 2026-05 | data_acquisition | 35,741 | 27,888 | 8,928 | 10,417 | 2,976 | **10,417** |
| 2026-06 | data_acquisition | 34,596 | 25,251 | 7,745 | 10,082 | 2,883 | **10,085** |
| 2026-07 | data_acquisition | 35,738 | 24,087 | 7,625 | 10,412 | 2,976 | **10,412** |
| 2026-08 | data_acquisition | 35,743 | 23,825 | 7,624 | 10,415 | 2,975 | **10,415** |
| 2026-09 | data_acquisition | 34,589 | 22,483 | 7,510 | 10,080 | 2,879 | **10,080** |
| 2026-10 | data_acquisition | 35,742 | 26,679 | 7,698 | 10,416 | 2,976 | **10,416** |
| 2026-11 (to 11th) | data_acquisition | 12,297 | 9,124 | 2,624 | 3,615 | 1,022 | **3,615** |
| **2025-10 → 2026-11** | | | | | | | **136,669** |

Live partitions (2026-05 → 11): 65,440 affected rows. Archive tables counted so far
(2025-10 → 2026-04): 71,229.

Other apps (`mmb-rpp`, `hhm_rpp`, `alert-notify`, `alert-processor`, `aws-ff`, `odd-jobs`,
`hhm_creds`) have **0** affected rows. `mmb-rpp` has many `Command failed:` rows, but they
are rsync failures without a password.

How to read the columns:
- `cmd_failed_any`: rows with `Command failed:` anywhere; includes MMB/rsync failures, whose
  argv has no password.
- `cmd_failed_cred_script`: `Command failed: ./read/sh/{GE,Philips,Siemens/siemens_c…}`. These
  scripts take `[ip, user, pass, …]`, so the message contains the password.
- `args_logged`: rows with a logged `execute_path` of such a script (L1, approximate:
  substring match).
- `list_dirs`: rows with an `exec_list_dirs` note (Philips CV, `[ip,user,pass,…]`).
- `affected`: the union of the last three.
- `stats.job_runs` (2026-03-04 → today): 344,777 rows, 151 with an `error_message` (all job
  `monday`), **0** with `Command failed:` or a credential shape. The clean-up still redacts
  and verifies it (rule R5), in case one is written before the deploy.

**Local run-log files, `/home/prod/hhm_data_acquisition/utils/logger/`** (88 GB; every file
`0644`, so readable by every local account). Every file was scanned (`.gz` decompressed,
0 read errors) with the same credential-specific patterns as the DB columns below:

| Location | Files | Holding credentials | `Command failed` (cred script) | logged args (cred script) | `exec_list_dirs` | Period (mtime) |
|---|---:|---:|---:|---:|---:|---|
| loose `data_acquisition-log.prod.*.js` | 290,349 | **84,645** | 65,818 | 84,642 | 24,169 | 2026-03 → today |
| `aa-save-logs/` (`…production…`) | 144,613 | **51,534** | 38,352 | 47,413 | 12,379 | 2024-02 → 2024-06 |
| daily dirs `YYYY-MM-DD/*.js.gz` (880 dirs; non-empty to 2026-03-04) | 708,784 | **236,760** | 171,905 | 222,564 | 65,810 | 2024-06-14 → 2026-03-04 |
| `01-04-24/` (old winston format) | 18 | 13 with `Command failed:` (not classified) | | | | Jan 2024 |
| **total** | **1,143,764** | **372,952** | | | | |

By year (mtime): 2024: 131,020; 2025: 135,857; 2026: 106,062.

A first pass with the generic patterns (`Command failed:` / any `args`) matched about 79% of
files. That overcounts: most `Command failed:` lines are MMB rsync failures, which carry no
password.

DEV checkout `utils/logger/`: 26 files, 19 with `Command failed:`, 21 with logged args.

Side finding: **log rotation has been broken since 2026-03-05.** `stamp_compress.sh
hhm_data_acquisition prod` copies `hhm_data_acquisition-log.prod.*`, but since around March
the files are named `data_acquisition-log.prod.*` (`APP_NAME=data_acquisition`). `cp` matches
nothing, `set -e` exits after `mkdir`, and each day since leaves an empty directory while the
loose files pile up (70.5 GB).

## 3. Fix (built on DEV, uncommitted)

### 3.1 Recommendation: register exact values at decryption, mask at every sink

- `util/redact.js` (new) keeps a process-wide set of secret values. One cron run is one
  process, so the set is "the credentials of this run". `redactString` masks each value,
  plus its JSON-escaped, `util.inspect`-escaped and URL-encoded forms, with `***`, longest
  first. No positional regex, so field, script and argument order don't matter.
- `util/encrypt/index.js`: `decryptString` returns `registerSecret(decrypted)`. That is the
  only place plaintext credentials come into existence, so nothing needs to remember to
  register.
- Sinks:
  - DB row and run-log file: `index.js` flushes through the new `util/flush_run_log.js`. It
    calls `redactInPlace(run_log.log_events)` (every string value, including an execFile
    Error's `cmd`/`stdout`/`stderr`) and then the shared logger's `dbInsertLogEvents`, then
    `redactInPlace` again and `writeLogEvents`. The shared logger itself is **not modified**
    (§3.3), and its JSON stays valid because the objects are scrubbed before it serializes
    them.
  - `index.js`: `installConsoleRedaction()` at boot wraps `console.log/info/warn/error/debug/trace`
    once, which covers every `console.log(error)` in every catch, current and future. All
    cron jobs enter through `index.js`. `stats.job_runs.error_message` is redacted.
- Removed the explicit prints in `run_manual.js` and `philips_mri.js` (L4).
- IP, script path, stderr and stack are kept, so the logs stay useful:
  `Command failed: ./read/sh/GE/x.sh 10.1.2.3 *** *** /files/SME…`.

Alternatives considered:
- Rebuild the error message without the args: covers L2 only. L1 (every run) and console
  stay leaky.
- Strip `args` from notes in each wrapper: five or more call sites, and the next wrapper
  forgets.
- Regex on argv positions: fragile (Siemens CV has 5 args, Siemens CT/MRI 1) and misses
  stderr echoes. For the *clean-up* it's the only option, because the values are unknown
  there.

### 3.2 Tests (`util/__tests__/credential-redaction.test.js`, jest; `tests/` is gitignored)

Fake credentials, generated per run, go through the real `encryptString`/`decryptString`.
The password contains `" \ ' & /` and a space. A real failing `execFile` runs a temp script
that echoes its args to stderr, through the real `exec_hhm_data_grab`, then `flushRunLog` and
the real, unmodified shared `log.js`, with Redis and the PG pool mocked.
- Control: the raw `error.message`, `stack`, `cmd` and `stderr` do contain the fake values.
- Asserted absent in every textual form (raw, JSON, inspect, URL, SQL-quoted) from: the
  `util.app_run_logs` INSERT, the run-log file (also valid JSON) and the console (including
  `console.trace`).
- Result: **8/8 pass**.
- Mutation check on a scratch copy: undoing any one part of the fix (`redactInPlace` in the
  flush, decrypt registration, the `trace` wrapper) fails exactly the matching assertions.
- Cost: 32 ms on a 5.2 MB run log.
- The two existing suites (`tests/config`, `tests/jobs/hhm`) already fail on DEV: they import
  modules that exist only on the Docker line. Unrelated.

### 3.3 Deployment detail: `utils/` is a shared repo, so it isn't changed

`utils/` is gitignored here because it is **its own git repository**, `AvanteHS-RTT/utils`.
All 8 prod apps use it (`hhm_data_acquisition`, `hhm_rpp`, `hhm_rpp_ge`, `hhm_rpp_siemens`,
`mmb-rpp`, `alert-notify`, `alert-processor`, `aws-ff`), all on its `PROD` branch.

A first version patched `utils/logger/log.js` to require `../../util/redact`. That path exists
only in this app, so shipping it would have broken the other seven. (It was also undeployable
from here: `git add -f` silently does nothing for a path inside a nested repo.) That patch was
withdrawn before any commit. The `utils` repo is clean, and its `log.js` is byte-identical to
prod's.

The fix now lives entirely in this repo (`util/flush_run_log.js`, called from `index.js`), so
**a normal `git pull` of `hhm_data_acquisition` on prod deploys all of it**. The `utils`
repo needs no pull.

If you later want the shared logger itself to redact (for every app), that's a change in
`AvanteHS-RTT/utils` with its own review. The hook would have to be optional, because other
apps have no `util/redact.js`. Listed in §8.

The Docker line (`DEV_docker`, …) vendors `utils/` as plain files and has **the same leak**
(same `args` note, no redaction): follow-up, §8.

### 3.4 Post-deploy check (read-only, counts only)

After the first runs on prod, rows written since the deploy must show no unmasked credential
shape. In psql, after section 0 of the clean-up SQL (which defines the helpers), with `<T0>`
the deploy time:

```sql
SELECT count(*) AS rows_since_deploy,
       count(*) FILTER (WHERE pg_temp.credlog_residual(verbose_log::text)
                           OR pg_temp.credlog_residual(coalesce(warn_error_logs::text, ''))) AS leaking
FROM util.app_run_logs
WHERE app_name = 'data_acquisition' AND inserted_at >= '<T0>';
-- expect leaking = 0 (and rows_since_deploy > 0)
```

The residual check is structural, so it would also flag a fixed row whose credentials failed
to register. A registered value shows as `***`, and `***` never matches the check.

## 4. Commit plan (after review, each one only with your OK)

1. Code fix: `util/redact.js`, `util/flush_run_log.js`, `util/encrypt/index.js`, `index.js`,
   `jobs/hhm/run_manual.js`, `jobs/hhm/philips/philips_mri.js`,
   `util/__tests__/credential-redaction.test.js`. Explicit paths only; nothing in `utils/`. Your WIP (`db/normalize/prod/*.sql`,
   `handoff/`) is never staged.
2. Clean-up tooling + this plan: `maintenance/credlog/*`, `PLAN-CREDENTIAL-LOGS.md`,
   `REVIEW-CREDLOG-*.md`, or keep them out of git; your choice.

## 5. Out of scope unless you agree: credentials on the command line

While a script runs, its argv is visible to every local user (`ps`, `/proc/<pid>/cmdline`;
`/proc` is mounted without `hidepid`, and 20 local accounts exist). That holds for the shell
script and its children: `sshpass -p <pass>` and `lftp -c "… open sftp://user:pass@host"`
put it on their own argv too.

| Option | How | Pros | Cons |
|---|---|---|---|
| **env vars** | `execFile(path, [ip, …], { env: { ...process.env, HHM_USER, HHM_PASS } })`; scripts use `sshpass -e` (`SSHPASS`), `lftp open --env-password -u "$user"` (`LFTP_PASSWORD`), expect `$env(HHM_PASS)` | small change per script; `siemens_cv_logfiles_zip.sh` already does it; not in `ps` | readable by the same uid and root in `/proc/<pid>/environ` (not by other users); inherited by children; a script running `env` or `set -x` would print it |
| **stdin** | `child.stdin.write(pass + "\n")`; script does `read -r pass` | never in argv or environ | every script and every tool must read from stdin; `sshpass` needs `-d <fd>` or `-f`; more work, harder to test |
| hidepid | mount `/proc` with `hidepid=2` | one change, covers everything | system-wide side effects (monitoring, netdata run here); root still sees all; doesn't fix logs |

Recommendation if you take it on: env vars, one script family at a time (GE CT/CV/MRI,
Philips CT/CV/MRI, Siemens cerb), each with its own test run. The redaction fix stays as a
safety net.

## 6. Clean-up of existing data (separate step; run only after the fix is deployed)

### 6.1 `util.app_run_logs` + `archive_util.*`: `maintenance/credlog/redact_app_run_logs.sql`

The values are unknown here (only the collector decrypts them), so the SQL masks by
structure, with the same four rules as the file tool. The rules apply only to the
credential-bearing scripts (`./read/sh/GE/*`, `./read/sh/Philips/*`,
`./read/sh/Siemens/siemens_c*`, all called with `[ip, user, pass, …]`). Rows that only
mention other commands (MMB rsync etc.) are not rewritten.

- R1: logged `execute_path` + `args` (≥ 3 strings) → `args[1]` and `args[2]` (user, pass)
  become `"***"`; `args[0]` (ip) and the rest are kept.
- R2: the `exec_list_dirs` note `args` → the same.
- R3: `Command failed: <cred script> <args…>` → `<script> ***`, up to the end of that line.
  Stderr lines after it are kept.
- R4: a serialized `"cmd":"<cred script> <args…>"` → `"<script> ***"`.
- R5: `stats.job_runs.error_message`, which is plain text: `Command failed: <cred script> <args…>`
  → `<script> ***`, up to the real end of line. A `"` isn't a delimiter there, so R3 can't be
  reused.

Every section is opt-in through a psql variable. Without one, the script only sets up and
stops. Without `-v cutoff=…` it refuses to run.

| Flag | Section | Writes? | Duration |
|---|---|---|---|
| (always) | 0. setup: session-temp helpers in `pg_temp` (nothing permanent), table list with sizes | no | seconds |
| `-v rehearse=1` (+ `rehearse_tbl`, `rehearse_day`) | 2. one-day rehearsal; expect `bad_json=0`, `residual_after=0`, `not_idempotent=0` | no | ~1 min |
| `-v dryrun=1` | 1. rows that would change per table/app/month | no | hours (full scan) |
| `-v apply=1` | 3. UPDATE per table per day, one transaction each, only rows the rules change; then 4. verify | **yes** | hours |
| `-v verify=1` | 4. residual per table (expect 0) + `stats.job_runs` count | no | hours |
| `-v vacuum_list=1` | 5. prints the `VACUUM FULL` statements to run | no | seconds |
| `-v schemas=util` | limits every section to the live partitions (e.g. after dropping `archive_util`) | | |

The write path was rehearsed end to end on a throwaway PostgreSQL 14 instance in my
scratchpad (fake data, same layout: partitioned `util`, a detached `archive_util` table,
`stats.job_runs`):
- The cutoff guard and the no-flag run change nothing.
- `apply` updated exactly the 8 credential rows. The 9 rows that must stay as they are
  (MMB rsync, `[ip, path]` Siemens, already-masked) and a leaky-looking row written after the
  cutoff were left alone.
- verify reported `residual=0`; a second `apply` updated 0 rows.
- Caveat: prod runs PG 16; the throwaway was PG 14, with a test-only shim for
  `pg_input_is_valid`, a PG 16 function used only by the rehearsal section.

Rehearsed read-only by me, using the exact expressions taken from the file:

| Sample | Candidates | Would change | Held credentials before | After | Bad JSON | Rerun changes |
|---|---:|---:|---:|---:|---:|---:|
| synthetic (fake values, every escape) | 1 | 1 | yes | 0 | 0 | 0 |
| `util.app_run_logs_2026_11`, 2026-11-10 | 1,177 | 343 | 343 | **0** | 0 | 0 |
| `archive_util.app_run_logs_2025_03`, 2025-03-15 | 1,248 | 386 | 386 | **0** | 0 | 0 |

On both days the rows rewritten equal the rows holding credentials, and no other app's rows
are touched. MMB rsync failures, `[ip, path]` Siemens calls and argument-less failures stay
as they are. A first draft with path-agnostic rules would have rewritten 1,112 rows on the
November day instead of 343, so I narrowed it. On the archive day my first residual check
flagged 47 rows wrongly: `siemens_cerb.sh` was then called as `[ip, data_path]`, with no
credentials. The check now needs ≥ 3 args.

**What to expect.**
- `apply` updates about the "affected" numbers in §2.2: ~65k rows in the live partitions,
  ~71k (+ 2025-03 → 09) in the archive.
- Those rows are small: about **1 GB** of `verbose_log` in the live partitions, ~1 GB in the
  archive so far. Most of the table volume is other apps. So WAL and bloat stay modest.
- The time goes into reading: each table is scanned day by day, about 40 s per GB of table,
  so ~40 min for the live partitions and ~1.5 h for the archive.
- `VACUUM FULL` then rewrites each table in full: minutes per table, and it needs free space
  for one copy (largest ~11 GB).

**Recommendation:**
- **live partitions (2026-05 → 11): UPDATE (redact in place)**, keeping six months of
  collector diagnostics. Then `VACUUM (FULL, ANALYZE)` per partition. Without it the old row
  versions, credentials included, stay in the table files: plain VACUUM only marks them
  reusable. Closed months can go any time. The current month blocks collector INSERTs while
  it runs (~minutes for ~3 GB), so pick a quiet window. `pg_repack` is available on the server
  (not installed) if you want that online.
- **`archive_util` (detached, 2025-03 → 2026-04, ~140 GB): DROP** the tables if nobody needs
  them. That's instant, frees the space at once and needs no VACUUM. If they're kept, run
  §3–5 of the SQL on them too (the table list already includes them).
- DELETE instead of UPDATE (in the SQL as an alternative) is cheaper but loses those rows'
  diagnostics.

Facts that the clean-up does not change:
- Azure PITR backups keep the old pages until the backup retention ages out.
- WAL generated by the UPDATE is proportional to the rows rewritten. Check free storage first:
  VACUUM FULL needs room for one copy of the largest table (~11 GB).

### 6.2 Local run-log files on prod (you run these, as `prod`)

What:
- `/home/prod/hhm_data_acquisition/utils/logger/` (§2.2): loose
  `data_acquisition-log.prod.*.js`, `aa-save-logs/`, `YYYY-MM-DD/*.js.gz` and `01-04-24/`.
- The DEV checkout's `utils/logger/data_acquisition-log.*.js` (26 files). Those are mine to
  clean on DEV if you want; I haven't touched them.
- The parser apps (`hhm_rpp`, `mmb-rpp`, alerts) have no credential pattern in the DB (§2.2),
  so their local logs aren't in scope. I didn't scan `hhm_rpp_ge`'s files.

These files duplicate the DB rows (`writeLogEvents` writes the same JSON as `verbose_log`).
For 2024-02 → 2025-02, the files are the only copy left.

How (recommended: delete what you don't need, redact what you keep):

```bash
cd /home/prod/hhm_data_acquisition
# 0) after the fix is deployed; note the time T0 of the first post-fix run
# 1) dry run, counts only (reads ~88 GB; nice it)
ionice -c3 nice -n19 node maintenance/credlog/redact_run_log_files.js utils/logger
# 2a) delete (simplest, certain, frees ~88 GB):
#     old-format and the archive dir
rm -r utils/logger/01-04-24 utils/logger/aa-save-logs
#     daily gz dirs (and the empty ones since 2026-03-05)
find utils/logger -mindepth 1 -maxdepth 1 -type d -name '20??-??-??' -exec rm -r {} +
#     loose files written before the fix (adjust T0)
find utils/logger -maxdepth 1 -type f -name 'data_acquisition-log.prod.*.js' ! -newermt "<T0>" -delete
# 2b) or redact in place, keeping the files (atomic per file, keeps mode/mtime, handles .gz):
ionice -c3 nice -n19 node maintenance/credlog/redact_run_log_files.js --apply utils/logger
#     exit 2 = something left over / would break JSON; the summary line says which
# 3) tighten modes (run logs hold diagnostics either way)
chmod 700 utils/logger && find utils/logger -type f -exec chmod 600 {} +
```

The file tool was rehearsed on a copy of the 26 DEV logs plus a `.gz`: 26 rewritten, 0
residual, 0 broken JSON, second run changes nothing, mode and mtime kept. One DEV file was
already invalid JSON before (truncated); it is still redacted as text.

Also fix `stamp_compress.sh hhm_data_acquisition` (name mismatch, §2.2), or rotation keeps
piling up loose files.

## 7. Rotation: facts for your decision

- **Which credentials:** every credential group the scheduled collectors decrypt.
  - GE CT (4 groups / 29 systems), GE CV/IR (1/2), GE MRI (4/12), Philips CT (1/9),
    Philips CV/IR (3/39), Philips MRI (1/7), Siemens CV/IR (1/1): 15 groups, 99 active systems.
  - `hhm_credentials` has 25 rows. Two are `avante` rows: `arts` is used by 1 active system,
    `mmb` by none.
  - Siemens CT/MRI use no password.
- **Since when:** the code has logged them since 2023-06-23. The oldest retained copy is a
  file from 2024-02 and a DB table from 2025-03. Older DB partitions were dropped at some
  point, so whether backups or copies of those exist is unknown to me.
- **Who could read them:**
  - DB: roles with SELECT on the log tables are `avantehs_admin` and one personal Entra ID
    role (4 login roles exist in total). Every app `.env` on vm-debian is `0644`, so any of
    the **20 local accounts** can get the `avantehs_admin` connection and read the rows.
  - Files: run logs are `0644` in a home directory that is `0777`.
  - While scripts run: anyone on the box, through `ps`.
- **The encryption doesn't separate these groups:** `util/encrypt/index.js` uses
  `crypto.createCipher` (deprecated, MD5-derived key, no IV) with a **key literal in the
  tracked source** (line 3). Anyone with DB read and the repo can decrypt every
  `hhm_credentials.*_enc` value directly. So whoever could read the leaked logs could probably
  read the credentials anyway. Rotating without also moving the key out of the repo would let
  the same people read the new values.
- **Exposure outside the org:** I found none (no external log shipping; cron output is
  discarded). Unknowns: DB backups and exports, copies of the run-log files, the Docker
  deployments (same leak there).
- **Practicalities you know better:** these look like shared service or vendor accounts per
  group (one group covers up to 29 systems), so rotating means coordinating with the vendor,
  site or customer for each group.

## 8. Other findings (not fixed; for your list)

1. Hardcoded encryption key and deprecated `createCipher` in `util/encrypt/index.js`
   (tracked, identical on prod). Move the key to the environment or a secret store, and
   re-encrypt with `createCipheriv` + a random IV.
2. `util/encrypt/index.js:19-26` (tracked) is a commented-out block with a literal value that
   looks like a real credential, plus sample ciphertexts. Remove it; it's also in git history.
   Same kind of placeholder in `read/sh/GE/ge_mri_spawn.sh:6`.
3. File modes on vm-debian: `/home/prod` is `0777` with no sticky bit (any local user can
   rename or replace entries in prod's home, including the app directories). The `.env`
   files and run logs are `0644`.
4. The Docker line (`DEV_docker`, `PROD_docker`, `STAGING_docker`) has the same leak; the
   fix needs porting there.
5. Broken log rotation since 2026-03-05 (§2.2).
6. `read/exec-list_dirs.js:127` references `extracted_err_message`, which is never defined, so
   every failure of `exec_list_dirs` throws a `ReferenceError` inside its catch.
7. The existing jest suites fail on DEV (imports from the Docker line).
8. Optional: make the shared logger (`AvanteHS-RTT/utils` `logger/log.js`) redact for every
   app, through an optional hook. Separate repo, separate review (§3.3).
