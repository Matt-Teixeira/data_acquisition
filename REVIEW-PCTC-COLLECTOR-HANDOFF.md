# Review handoff: Philips CT collector export (PCT-C, DEV)

Date: 2026-11-20 · Repo: `hhm_data_acquisition` · Branch: `DEV`.
- **First review:** commit `aca5b3d`. The Codex review is `hhm_rpp_philips/REVIEW-PCTC-COLLECTOR-CODEX.md`
  (written in the sibling repo).
- **Round 2:** `REVIEW-PCTC-COLLECTOR-CODEX-2.md` (this repo). It found 0 P1, 3 P2 (N1–N3), all
  in the optional listing.
- **Round 3:** `REVIEW-PCTC-COLLECTOR-CODEX-3.md` (this repo). It found 0 P1, 3 P2 (R3-1 to R3-3);
  verdict "not ready".
- **Round 4:** `REVIEW-PCTC-COLLECTOR-CODEX-4.md` (this repo), on `00e94e1` (round 1–3 fixes,
  pushed). It found 0 P1, 1 P2 (R4-1); verdict "not ready", with R4-1 as the only blocker.
- **Round 5:** `REVIEW-PCTC-COLLECTOR-CODEX-5.md` (this repo), on the R4-1 fix (uncommitted on top
  of `00e94e1`). It found 0 P1, 0 P2, 0 P3. **Verdict: ready to promote to STAGING and PROD** once
  the reviewed fix and test are committed. One non-blocking precision note: the combined test's
  readiness file is written by the stub's lftp right after it forks the resistant child, not by the
  child after its trap. Codex confirmed the stronger case independently.
- **Context:** `hhm_rpp_philips/PLAN-PHILIPS-CT-INSIGHTS.md` §3.2 (ingest defects I1–I6), §5 Q2
  (scope), §7.4 (Events lines that never reach the DB), §8 (this session).

**Ground rules for the review:**
- Never print, quote or copy a credential, host IP or site name. The tests use fake values and the
  TEST-NET address 192.0.2.10.
- Make no network connection to any scanner. Run nothing against `/home/prod/*`.
- Don't touch the unrelated uncommitted WIP in this repo (`db/normalize/prod/*.sql`,
  `db/tables/TABLES.sql`, `handoff/`).
- The script runs under `/bin/sh`, which is dash 0.5.11 here.

**Files to review:**
- `read/sh/Philips/phil_ct_data_grab_1.sh`.
- `read/__tests__/phil_ct_data_grab_1.test.js`.

## Fix after round 4 (`REVIEW-PCTC-COLLECTOR-CODEX-4.md`, 2026-11-20)

| Finding | Fix | Checked |
|---|---|---|
| **R4-1 P2**: if the collector shell is killed while `session()` waits, its group cleanup never runs, so a TERM-resistant descendant keeps the lock forever | `session()`'s body is now a **subshell** `session() ( … )`: a separate supervising process (Codex's prototype). It keeps waiting on `timeout` and then kills the session's process group even if the collector shell is killed, and it holds fd 9 until that cleanup is done. Its status is passed out with `exit`. Nothing else changed. | New jest test (Codex's combined case): the stub's lftp starts a TERM-resistant same-group child and signals readiness; **only the collector shell is SIGKILLed**. Then the lock is free within limit + grace (1 s + 1 s, measured < 8 s), every holder of the collector's stdout/stderr pipes is gone (`close` event), no resistant child is left, nothing was published, the killed grab's private staging is left, and the next grab runs, publishes and removes that staging. Mutation: `session()` back to `{ … }` with `return` → this test fails (the R4-1 reproduction). All 51 pass, nothing left running. Real-data equivalence rerun: `pctc/out/08_equivalence_round4.txt`, all OK. |

**Limits that remain (Codex round 4, item 3), not changed:**
- **Group kill.** If someone kills the collector's whole process group rather than just its shell,
  the supervising subshell (same group as the collector) dies too, while `timeout` and lftp (their
  own group) survive. Lock lifetime is then bounded only by `timeout -k` and the lftp process
  itself, i.e. the round-3 position. The runner signals no one; cron doesn't kill groups.
- **Untimed steps.** Exports, transformations and filesystem steps have no timers; a stuck utility
  or uninterruptible I/O can still prolong a grab. These are general limits, not new.

## Fixes after round 3 (`REVIEW-PCTC-COLLECTOR-CODEX-3.md`, 2026-11-20)

| Finding | Fix | Checked |
|---|---|---|
| **R3-1 P2**: a failed `: >state` redirection (a special builtin) killed the dash script after the outputs were published | (a) State files are updated with `touch` (an external command, so a failure can't end the shell). (b) The whole listing block runs in a **subshell** `( … ) >/dev/null 2>&1`, so even a fatal error there can't end the parent. (c) If the attempt time can't be recorded, **no** listing session is opened. (d) A shrink forces an attempt on its own, so a reset flag that can't be created still gets the immediate attempt (it loses only the hourly persistence). | Jest: a dangling symlink at `.listing.attempt` → exit 0, stderr empty, outputs published, **no** listing session. A read-only old attempt file → exit 0, listing attempted (the owner can `touch`). A reset flag that can't be created plus a shrink → exit 0, listing attempted. Mutations: proceed when the attempt can't be recorded (fails); shrink only via the flag (3 fail). **Not caught:** replacing the subshell with `{ }` passes all 50, because after (a) nothing left in the block can be fatal. The subshell is now a second layer; say if you see a remaining fatal path. |
| **R3-2 P2**: GNU timeout stops supervising when its direct child exits, so a TERM-resistant descendant could keep the lock | Each `lftp` session runs through `session()`: `timeout -k …` as a **background job**, `wait`, then `kill -s KILL -- -<pid>` for the whole process group (timeout leads its own group). It runs after **every** session (success, failure or deadline), so nothing from a session outlives it. Verified on this dash that `kill -s KILL -- -PGID` works; the `kill -KILL -- …` form does **not** (status 2). Background jobs in a non-interactive shell get stdin from `/dev/null`; `lftp -c` doesn't read stdin (real `lftp` over `file://` checked in this form). | Jest: the stub's lftp starts a same-group child that ignores TERM (`sleep 47.25`), then dies on TERM (Codex's scenario), for both the download and the listing (limit 1 s, grace 1 s). Grab done in < 10 s, no `sleep 47.25` left, lock free. A child left by a **successful** download is killed too. **Real runner:** the same descendant during a download deadline → `execFile` returns, redis queue, nothing left. Mutation: no group kill (5 fail). |
| **R3-3 P2**: `0` disabled a deadline or the KILL escalation | `num()` accepts only 1–86400 (up to 6 digits, read as decimal with `expr`, so `0030` is 30, not octal). Anything else, including `0`, `000`, `86401`, empty and non-digits, falls back to the default. | Jest, on the **actual `timeout` argv** (recording stub that `exec`s the real timeout): `0/000/9999999` and `86401/''/0` → `-k 15 600` and `-k 15 120`; `0030/45/5` → `-k 5 30` and `-k 5 45`. Mutation: zero and huge accepted (2 fail). |
| R1 residue (coverage): the `sed` table-name guards were untested | A `sed` stub fails on the `tables.txt` split, or prints and then fails when reading `tables.lines`. | Jest: both → exit 1 with the matching message, files untouched. |
| Test robustness | Every direct script run has `spawnSync` `timeout: 20000`, `killSignal: SIGKILL`. `afterEach` SIGKILLs the deadline tests' distinctive sleeps. A deadline regression now fails in ≤ 20 s and leaves nothing behind. | No `lftp`, no leftover sleeps after the suite and after every mutation run (checked). |

**Handoff claims corrected (Codex round 3, item 4):**
- "At most about 24 attempts/day" holds only between shrinks: **every newly observed shrink forces
  an immediate attempt**. That's on purpose, since that's when the old database might still be on
  the scanner.
- The deploy note's "one listing a day" is the ordinary case: no reset pending, no new shrink.

## Fixes after round 2 (`REVIEW-PCTC-COLLECTOR-CODEX-2.md`, 2026-11-20)

| Finding | Fix | Checked |
|---|---|---|
| **N1 P2**: a listing that failed part-way replaced the good one | The listing is installed only if the `timeout … lftp` session exits 0 **and** the file is non-empty; then `chmod` and `mv -fT`. Otherwise the previous listing and its mtime stay. | Jest: a partial listing plus exit 1 → previous content and mtime unchanged, stderr empty. Mutation: install despite failure (fails). |
| **N2 P2**: TERM-only listing timeout could hold the lock forever | `timeout -k <grace> <limit>` on the listing, so GNU timeout signals the whole process group (lftp and ssh) and KILLs it after the grace. | Jest: a listing stub that ignores TERM (limit 1 s, grace 1 s) → the grab ends in about 2 s, exit 0, lock free, next grab 0. Mutation: no `-k` (fails). |
| **N3 P2**: failed listings retried every grab | The throttle uses the **attempt** time (`$4/.listing.attempt`, touched before each attempt), not the listing's age: at most one attempt per 24 h. A shrunk database sets `$4/.listing.reset_pending` and attempts at once; while pending it retries at most hourly; success clears it. Worst case about 24 attempts/day, only while a reset listing is pending. | Jest: 3 grabs with failing listings → listing sessions 1, 0, 0. Shrink with a fresh attempt → attempt now; same size within 1 h → none; after 61 min → retry, succeeds, flag cleared; then the daily throttle. Mutations: throttle on listing age (fails); no hourly pending retry (fails). |
| Q4 residue: an `mv` diagnostic from installing the listing reached stderr | The whole listing block, decision through install, runs inside `{ … } >/dev/null 2>&1`. | Jest: a directory at `Data_Logger.ls` → grab 0, stderr empty, exports published. Mutation: block not silenced (4 tests fail). |
| Item 1 (Codex recommendation): no overall deadline on the main download | `timeout -k 15 600 lftp …` (configurable: `PHIL_CT_DL_TIMEOUT`, `PHIL_CT_LIST_TIMEOUT`, `PHIL_CT_KILL_GRACE`; whole seconds only, anything else falls back to the default). A deadline hit exits nonzero, which takes the existing "Connection timed out", exit 0 path, so the runner treats it as a connection failure (redis retry queue), as Codex said it would. 600 s means ≥ about 17 KiB/s for 10 MiB. It leaves room in the 15-minute cycle for the exports and the 120 s listing. Tune it once real durations are measured. | Jest: the download stub sleeps 30 s with limit 1 s → about 1 s, "Connection timed out", files untouched, lock free; **real runner** → redis queue, not online. Bad settings (`"1; rm -rf /"`, `-5`, `x`) → defaults, exit 0. Mutations: no download timeout (2 fail); settings unvalidated (fails). |
| R1 residue: table-name `sed` pipelines unchecked | `sed` writes `tables.lines` (checked), then `NAME=$(sed -n Np …) \|\| fail` for each name. | Covered by the mdb-tables failure test. Byte equivalence rerun. |
| Item 6, peak disk | `events.raw` is removed right after `tr`. The EALInfo raw export now runs only when EALInfo processing starts (same `mdb-export` call order: Events, then EALInfo). | The argv test still asserts the four calls in order. Equivalence rerun. |

**Round-2 test gaps, now covered:**
- a partial listing;
- a listing that ignores TERM;
- the download deadline (script and runner);
- the failed-listing throttle and the reset-pending retry;
- a listing install failure;
- the later EALInfo `sort` failure;
- a CSV `tr` (NUL removal) failure;
- a publish failure at a later file (`EALInfo.csv`), with the exact list of published files;
- distinct staging per grab;
- handshakes instead of fixed sleeps in the orphan and lock tests (start and release files, and
  `flock -n` polling);
- **every** script run, direct ones included, now goes through the guard wrapper, which exits 99
  unless `lftp` is the stub.

**Not changed, by choice:**
- Exit 75 is still logged as an error by the runner. Codex: "acceptable now"; a dedicated runner
  outcome is the later interface if overlap becomes routine.
- A shrink is still a reset *heuristic*, and the handoff calls it that. A reset that doesn't shrink
  the file is caught by the daily listing.

## Fixes after round 1 (`REVIEW-PCTC-COLLECTOR-CODEX.md`, 2026-11-20)

| Finding | Fix | Checked |
|---|---|---|
| **F1 P1**: an orphaned `lftp` could write into the next grab's shared `.incoming` | (a) `lftp` no longer closes fd 9, so the lock stays held while any writer of the grab is alive, including after the shell is killed. (b) Staging is private per invocation: `mktemp -d "$4/.incoming.XXXXXX"` (l. 52). (c) Leftover `.incoming*` directories are removed only while holding the lock (l. 51); holding the lock means no earlier writer is alive. | Jest "orphaned download": shell A is `SIGKILL`ed while its `lftp` sleeps. Grab B is refused (75) while the orphan lives. After the orphan finishes, B publishes **its own** database and A's staging is gone. Mutations: put `9>&-` back (fails); drop the stale cleanup (fails). |
| **F2 P2**: a skip, or a lock error, was recorded as a successful acquisition | `flock -n -E 75 9` (l. 40). Status 75 (lock taken) → `exit 75` with a `phil_ct:` message. Any other `flock` status → `exit 1`, `flock failed (status N)`. Both are nonzero, so `read/exec-hhm_data_grab.js` takes its `catch` path: `addLogEvent(E, …)`, return `null`, **no queue entry**. No runner change was needed. | Jest: lock held → 75, `lftp` never called. Stub `flock` returning 69 → exit 1. **Real runner** (Redis and logger mocked): skip → no online/redis queue, 1 error logged. Mutations: skip exits 0 (3 tests fail); any nonzero treated as a skip (fails). |
| **F3 P2**: atomic replacement dropped the reader's permissions | `chmod 0644` on every staged file before publishing (l. 111, 131), whatever the umask. That is the mode the prod files have today (`-rw-r--r-- prod prod`, no ACLs). | Jest under `umask 077`: all published files are 0644. Mutation: no chmod (fails). |
| **F4 P3**: a publish failure claimed "previous outputs kept" | The publish loop (l. 113–123) tracks what was published. On failure: `phil_ct: publish <f> failed; outputs partly updated (already published: …)`. `mv -fT`, so a directory at a target path fails instead of swallowing the file. | Jest: `Events.output` is a directory → exit 1, exact message, `Logger.mdb` and `EALInfo.output` new, `EALInfo.csv` old, staging removed. Mutation: `mv` without `-T` (fails). |
| **R1 P1 (inherited)**: the legacy pipelines were unchecked | Every legacy step writes a file and checks its own status: `mdb-tables`, each `mdb-export`, header writes, `tr`, `awk`, `sort`, `sed`, `tail`. Intermediates are removed as soon as they've been used, to cut peak disk. The commands and their order are unchanged, so the bytes are unchanged (see Evidence). | Jest: failing `mdb-tables` and failing `sort` each → exit 1, files untouched. Mutation: `sort` unchecked (fails). |
| **Q4**: `cls` stderr in the main session could make a successful grab look like a connection failure | The listing moved out of the main session. It's a separate best-effort session (`timeout 120 lftp … >/dev/null 2>&1`, l. 125–133) **after** publishing, so it can't change the exit status, stderr or outputs. It runs when there is no listing yet, when the listing is older than 24 h, or when the new database is smaller than the published one (a reset: exactly when the old-file question matters). That's at most about 1 extra connection per system per day. The main `lftp` command is back to its original two commands. | Jest: a failing listing session that prints a max-retries line → grab exit 0, **stderr empty**, outputs published, old listing kept. Policy test: fresh → no listing; 24 h old → listing; shrunk database → listing. Mutation: listing stderr not discarded (fails). |

**Test gaps Codex listed, now covered:**
- The full legacy `.output` content is asserted against an oracle produced by the pre-PCT-C script
  on the same fixture. The fixture includes the comma and multi-line rows the legacy export drops,
  plus a relay row.
- The exact `mdb-export` argv for all four calls.
- Each table's export failing in each mode.
- `sort`, `mdb-tables` and `flock` failures.
- The listing policy and its stderr isolation.
- The real runner's queue behaviour for success, timeout, skip and export failure.

**Not covered here:** the CSV dialect edge cases Codex asked for (literal `\n` text, doubled quotes,
CRLF, tabs, non-ASCII). The script passes `mdb-export -e` output through and only removes NUL, so
those belong to the PCT-1b reader's tests. They are recorded there with Codex's decoder requirement:
parse CSV quoting first, then **one left-to-right** unescape pass per field.

**A harness fault found and fixed while writing this.** Jest sandboxes `process.env`, but
`child_process` (used by the runner without an `env`) reads the real one. So in a first draft of the
runner tests, three tests ran the **real** `lftp` against the TEST-NET address 192.0.2.10. That
address is never routed, so the connection hung and timed out, and nothing was reached. Fake
credentials only. No processes were left behind (checked). The runner tests now go through a wrapper
that puts the stubs first on `PATH` and exits 99 unless `lftp` resolves to the stub. A suite-level
test asserts the same for the direct tests.

## Problem in one paragraph (unchanged)

The Philips CT collector downloads `D:\Data_Logger\Logger.mdb` every 15 minutes and rewrites
`EALInfo.output` and `Events.output`, which `hhm_rpp_philips` parses. All 9 systems with
`process_log = true` use `phil_ct_data_grab_1.sh`.

The old script had four problems:
1. The Events export loses 4–7% of rows: `tr -cd`, an `awk` column reorder on commas, and line
   breaks inside `Msg`. Among the lost rows are the only ones that carry the series-cancel source.
2. Nothing is written atomically.
3. Failures are silent.
4. Nobody knows whether the scanner keeps the old database at a reset.

## Design (unchanged in intent)

**Additive.**
- The legacy `.output` files are produced by the same commands, byte-identical, so the running
  parser is unaffected.
- `EALInfo.csv` / `Events.csv` are the complete exports (`mdb-export -e -b strip -T '%Y-%m-%d %H:%M:%S'`,
  NUL removed) that PCT-1b will read.
- `Data_Logger.ls` answers the reset question.
- Nothing in `$4` changes until the download and every export succeed. Then each file is replaced by
  `mv -fT` from private staging.

## Outcome → what `read/exec-hhm_data_grab.js` does (prod copy byte-identical to DEV)

| Outcome | Exit | stderr | Runner branch | Before PCT-C |
|---|---|---|---|---|
| success (listing ok or not) | 0 | empty | online queue, `successful_acquisition: true` | same |
| connect timeout / max-retries / download deadline (600 s + 15 s kill; leftovers in the session's process group killed) | 0 | `Connection timed out` (+ lftp lines) | regex match → redis queue + reset totalizer | same (no deadline before) |
| lock held by another grab | **75** | `phil_ct: previous grab … skipped` | catch: E logged, `null`, no queue | n/a |
| lock error, empty download, any export/legacy step failure | 1 | `phil_ct: … failed; previous outputs kept` | catch: E logged, `null`, no queue | exit 0 with truncated/partial outputs |
| publish failure part-way | 1 | `phil_ct: publish <f> failed; outputs partly updated (…)` | same | n/a |

On the exit-1/75 path, `error.message`/`stack` contain `Command failed: <script> <ip> <user> <pass> …`.
The credential redaction (`71e1c52`: `util/redact.js`, `util/flush_run_log.js`, `index.js`) is live
on prod; its files are present and identical to DEV. `util/__tests__/credential-redaction.test.js`
covers the "script fails" shape.

## Evidence

1. **Jest: `npx jest read/__tests__/phil_ct_data_grab_1.test.js` passes 51/51** in about 20 s, with no
   open handles, no `lftp` and no leftover descendants afterwards. That's 44 script tests, 6
   real-runner tests and 1 stub guard (7 stubbed tools).
2. **Mutations, each caught:**
   - lock not held by `lftp`;
   - no stale staging cleanup;
   - any `flock` error treated as a skip;
   - skip exits 0;
   - no chmod;
   - `mv` without `-T`;
   - `sort` unchecked;
   - listing stderr not discarded;
   - from the first round: csv export failure ignored, no lock, NUL not stripped, database
     published first, no staging cleanup;
   - round 2: listing installed despite failure, no `-k`, no download timeout, throttle on listing
     age, no pending retry, listing not silenced, settings unvalidated;
   - round 3: proceed without a recorded attempt, no process-group kill, zero/huge settings
     accepted, shrink only via the flag. Subshell → braces is **not** caught (see the R3-1 row;
     Codex round 4 agreed to keep the subshell as isolation);
   - round 4: `session()` without its supervising subshell.
3. **Real data, rerun on this revision** (`~/philips_ct_evidence/pctc/scripts/equivalence.sh`,
   output `pctc/out/08_equivalence_round4.txt`). This is the old script versus the new one on
   5 real `Logger.mdb` copies, with a stub `lftp`:
   - `.output` files are **byte-identical on all 10**. For SME20598 they also match the file on prod.
   - `.csv` files **match the database on all 10** (179,478 rows, including 1,785 multi-line `Msg`
     values): row count, one physical line per row, every field equal after unescaping, no NUL.
4. **Real `lftp` 4.8.4 over `file://`** (no network):
   - the listing-only session `cd X && cls -l > f` writes the listing and exits 0;
   - when `cd` fails, it exits 1 and writes no file;
   - `flock -E 75` returns 75 under contention (util-linux 2.36.1).
5. **dash:** `sh -n` is clean. The EXIT trap keeps the `exit` status.

## Please look hard at

1. **`session() ( … )`.**
   - Is the supervising subshell the right shape?
   - Does it change anything else? Status propagation through `exit`; `$!` and `wait` inside the
     subshell; fd 9 now held by the subshell too; stdin of the background job.
   - Codex round 4 prototyped this; please confirm on the committed form.
2. **The new combined test.** Is it deterministic (readiness file, then SIGKILL of the shell pid
   only)? Does it prove what R4-1 needs: lock free, pipes closed, no descendants, next grab runs?
3. **Verdict:** ready to promote to STAGING and PROD, or not? If not, list only the blocking items.

## Out of scope (separate work)

- **Reachability** (network or site): all 9 systems still time out at TCP connect.
- **PCT-1b** (`hhm_rpp_philips`): read the `.csv` files. Its tests should carry the CSV-dialect
  cases above.
- **`phil_ct_data_grab_2.sh` / `_3.sh` / `phil_ct_v2.sh`:** used only by systems with
  `process_log = false`. Unchanged.

## Deploy notes (for the owner, after the review closes)

- Commit on `DEV`, then promote `STAGING` → `PROD`.
- No config, DB or crontab change.
- Steady state: about +1.1× the current outputs per system, plus `.grab.lock` and a small
  `Data_Logger.ls`. Peak during a grab: see "Please look hard at" item 6.
- Rollback: revert the script.
- First successful grab, check:
  - `.csv` row counts equal the database's;
  - `.output` equals the old script's output;
  - read `Data_Logger.ls`;
  - expect at most one listing session per system per day.
