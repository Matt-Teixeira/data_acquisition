# Review handoff: Philips CT collector export (PCT-C, DEV, uncommitted)

Date: 2026-11-20 · Repo: `hhm_data_acquisition` · Branch: `DEV` · Nothing committed or deployed.
Reviewer output goes to `REVIEW-PCTC-COLLECTOR-CODEX.md`.
Context: `hhm_rpp_philips/PLAN-PHILIPS-CT-INSIGHTS.md` §3.2 (ingest defects I1–I6), §5 Q2 (this
session's scope), §7.4 (Events lines that never reach the DB).

**Ground rules for the review:**
- Never print, quote or copy a credential, host IP or site name. The tests use fake values and a
  TEST-NET address only.
- Make no network connection to any scanner. Run nothing against `/home/prod/*`; it is the live app.
- Don't touch the unrelated uncommitted WIP in this repo (`db/normalize/prod/*.sql`,
  `db/tables/TABLES.sql`, `handoff/`). It is someone else's work.

**Files to review:**
- `read/sh/Philips/phil_ct_data_grab_1.sh` (modified).
- `read/__tests__/phil_ct_data_grab_1.test.js` (new).

## Problem in one paragraph

Every 15 minutes the Philips CT collector downloads `D:\Data_Logger\Logger.mdb` (an Access DB on
the scanner) with `lftp`/sftp and rewrites two text exports that `hhm_rpp_philips` parses:
`EALInfo.output` and `Events.output`. All 9 systems with `process_log = true` use this one script,
`phil_ct_data_grab_1.sh` (`config.acquisition.acquisition_script`).

The old script had four problems:
1. **The Events export loses rows.** `tr -cd` deletes characters, and `awk -v FS=","` reorders
   columns on commas, so a `Msg` containing a comma shifts the columns and the `sed` filter drops
   the row. A `Msg` with a line break (5.1% of non-relay Events rows) also breaks the line-oriented
   pipeline. Measured on real copies: 4–7% of Events rows are lost. They include the only lines that
   say who cancelled a series (`GANTRY_CANCEL_SOURCE_<CTBOX|HOST|…>`), so operator-versus-system
   aborts are invisible today.
2. **Nothing is written atomically.** The outputs were truncated and refilled in place, so the
   parser could read a half-written file. `lftp` also overwrote `Logger.mdb` in place, so a failed
   transfer left a broken database behind.
3. **Export failures were silent.** The script always exited 0 with whatever had been written.
4. **We can't tell what happens at a reset.** Nobody knows whether the scanner keeps the old
   `Logger.mdb` when it starts a new one. The rows written between the last grab and a reset are
   lost, an estimated 1–2% (I4).

## What changed

**Design choice: additive, so the running parser is unaffected.** The two legacy `.output` files
are produced by the **same commands as before**, so they are byte-identical. The complete data goes
into **new files** that only the future parser change (PCT-1b, `hhm_rpp_philips`, not in this diff)
will read. The two changes can therefore deploy independently, and this one can go first.

| Part | Change |
|---|---|
| Shebang | `#!/bin/sh`, made explicit. Before, `execFile` → `execvp` fell back to `/bin/sh` (dash 0.5.11) on the missing shebang, so the interpreter is unchanged. POSIX only: dash has no `pipefail`. |
| Guard (l. 25–28) | Exit 1 if `$4` is empty or `/`, before any file operation. `$4` is used for `rm -rf "$4/.incoming"`. The runner always passes `<PROD_HHM_FILES>/<SME>`. |
| Lock (l. 31–36) | `flock -n` on `$4/.grab.lock`. A second concurrent grab of the same system exits 0 with a `phil_ct:` message and touches nothing. The lock fd is closed for `lftp` (`9>&-`, l. 48), so an orphaned ssh can't hold it. |
| Staging (l. 38–44) | Everything is written in `$4/.incoming` (same filesystem), which is removed on exit (`trap … EXIT`). |
| Download (l. 46–48) | Same `lftp` settings and `open`. `mget -O` targets staging. New: `cd … && cls -l > $inc/Data_Logger.ls` lists `D:\Data_Logger\` (answers question 4). Because of `&&` the listing runs only after a successful `cd`, so stderr on a failed connection is unchanged. |
| Connection failure (l. 50–53) | Unchanged: `Connection timed out` on stderr, exit 0, and now nothing in `$4` changes. |
| Empty download (l. 55–59) | New: exit 1 with `phil_ct: … previous outputs kept`. |
| Legacy exports (l. 67–87) | The same `mdb-tables`, `tr`, `awk`, `sort`, `sed`, `tail` commands. `mdb-export` now writes to a staging file first, so its exit status is checked, and the pipeline reads from that file (`… < file` is byte-equivalent to `mdb-export … \|`). |
| Complete exports (l. 89–93) | New: `mdb-export -e -b strip -T '%Y-%m-%d %H:%M:%S' <mdb> EALInfo\|Events`, then `tr -d '\000'`, into `EALInfo.csv` and `Events.csv`. `-e` escapes `\n \r \t \\` inside fields, so there is one physical line per row. Quotes are doubled (mdb-export's default). BLOB is stripped (binary OLE, never used). Datetimes are device-local ISO. Table order. |
| Publish (l. 95–100) | `mv -f` from staging, database first, then the four exports, then the listing if non-empty. Any failure before this point leaves `$4` exactly as it was. |

## Outcome → what `read/exec-hhm_data_grab.js` does (prod copy byte-identical to DEV)

| Outcome | Exit | stderr | Runner branch | Before |
|---|---|---|---|---|
| success | 0 | empty | online queue, `successful_acquisition: true` | same |
| connect timeout / max-retries | 0 | `Connection timed out` + lftp lines | `connection_regexes` match → redis queue + reset totalizer | same (outputs were already untouched) |
| grab already running | 0 | `phil_ct: previous grab … skipped` | no regex match → online queue `successful_acquisition: true` | n/a (no lock before) |
| empty download, export or publish failure | 1 | `phil_ct: … failed; previous outputs kept` | `catch`: no regex match, not 124 → `addLogEvent(E, …, error)`, returns `null`, no queue update | exit 0 with truncated or partial outputs |

On the exit-1 path, `error.message`/`stack` contain `Command failed: <script> <ip> <user> <pass> …`.
The credential redaction (`util/redact.js`, `util/flush_run_log.js`, commit `71e1c52`) is live on
prod: the files are present, `index.js` calls `flushRunLog`, and `util/__tests__/credential-redaction.test.js`
covers exactly this "script fails" shape.

## Evidence

1. **Jest: `npx jest read/__tests__/phil_ct_data_grab_1.test.js` passes 10/10.** No network; `lftp`,
   `mdb-tables` and `mdb-export` are PATH stubs that produce synthetic tables with a comma-bearing
   `Msg`, a multi-line `Msg` and a NUL byte. It covers:
   - success (all six files published, staging removed, NUL removed, one line per row);
   - the legacy format kept;
   - the `lftp` command (listing only after `cd`, download into staging);
   - connection failure (exit 0, regex classifies it, files untouched);
   - legacy export failure and csv export failure (exit 1, no regex match, no fake credential in
     stderr, files untouched);
   - empty download;
   - `$4` empty and `$4 = /`;
   - lock contention (`lftp` never called).
2. **Mutations, each caught:**
   - csv export failure ignored (1 test fails);
   - no lock (1);
   - NUL not stripped (1);
   - database published before the exports (3);
   - no staging cleanup (5).
3. **Equivalence on real data** (outside the repo, `~/philips_ct_evidence/pctc/`; real data stays
   there):
   - **Setup:** old and new script, each run with a stub `lftp` that copies one of 5 real
     `Logger.mdb` copies (SME20598, SME18534, SME18535 from 2026-10/11; SME17372, SME18976 from
     2025-10).
   - **`EALInfo.output` and `Events.output` are byte-identical, old versus new, on all 10.** For
     SME20598 the new output is also byte-identical to the file on prod.
   - **`EALInfo.csv` and `Events.csv` match the database exactly on all 10** (179,478 rows): row
     count equal to the table, one physical line per row plus the header, and every field equal to
     a reference `mdb-export` parse after unescaping. That includes 1,785 `Msg` values with line
     breaks. No NUL bytes.
   - Script: `pctc/scripts/equivalence.sh`, output `pctc/out/04_equivalence.txt`.
4. **Real `lftp` 4.8.4** (installed here) over its local `file://` protocol, with no network: `cd X &&
   cls -l > f; mget Logger.mdb -O d; exit` writes the listing and downloads. When `cd` fails, `cls`
   is skipped, stderr shows only the same `cd:`/`mget:` lines as today, and the exit status is 1.
5. **dash:** an EXIT trap keeps the status passed to `exit` (checked, including bare `exit` after
   `echo`). `sh -n` is clean.

## Please look hard at

1. **Atomicity and partial publish.** Each `mv` is atomic. A failure in the middle of the publish
   loop (l. 96–99) would leave some new and some old files. The `.output` files are parsed
   independently, each with its own Redis byte offset, so a mixed pair is not a correctness problem
   for today's parser. Is that reasoning sound?
2. **Interaction with the parser's byte-offset tail** (`hhm_rpp_philips` `data_acquisition/Philips_CT.js`).
   The old script also replaced the whole file content on every grab; only the inode changes now.
   Any reader that holds an fd across grabs? (None found: the parser re-opens by path each run.)
3. **Lock semantics.** Is the fd inherited by anything besides `lftp`/ssh? Is `flock` on a file in
   `$4` safe with the parser reading other files in the same directory? Is exit 0 on contention
   the right signal for the runner?
4. **`lftp`.** The `&&` and `>` redirection inside `-c` against a real cygwin sftp server (only tested
   over `file://`). Could `cls` on a slow link noticeably extend each grab? It's one directory
   listing in the same session.
5. **The csv dialect for PCT-1b.** Header names from `mdb-export`, doubled quotes, `-e` backslash
   escapes. Any ambiguity, for example a literal backslash before `n` in a message: it becomes `\\n`,
   which unescapes correctly.
6. **dash portability** of every line. In particular `exec 9>`, `trap … EXIT`, `fail()` inside `||`
   lists, and `[ … ] && mv` as the last list before `exit 0`.
7. **Pre-existing behaviour kept on purpose**, and said here so it isn't mistaken for new: the
   unquoted glob `[:alnum:]` in `tr` (cwd is the app root, which has no one-letter files); the
   password in the lftp URL and argv (the process list); `exit` 0 with "Connection timed out" for
   any `lftp` failure, including a missing file.

## Out of scope (separate work)

- **Reachability:** all 9 systems time out at TCP connect on port 22, as recently as 2026-11-20
  15:42 UTC. That's network or site work, not code.
- **The parser change (PCT-1b, `hhm_rpp_philips`):** read the `.csv` files, accept the `__NN`
  suffix, parse the whole file with key-based dedupe. Not before 2026-11-24 18:53 UTC. Until then
  the `.csv` files are written but not read.
- **`phil_ct_data_grab_2.sh`, `_3.sh`, `phil_ct_v2.sh`:** used only by systems with
  `process_log = false` (1–2 each), and unchanged. A system that is re-enabled should be pointed at
  `_1.sh` (a config change).
- **Retiring the `.output` files:** after PCT-1b has run on the `.csv` files for 5 clean days.

## Deploy notes (for the owner, after the review closes)

- Commit on `DEV`, then promote `STAGING` → `PROD` the usual way.
- No config, DB or crontab change.
- The new files appear only once a system is reachable again; nothing reads them yet.
- Disk: about +1.1× the current outputs per system (about 6 MB for a full `Logger.mdb`), plus a
  `.grab.lock` and a small `Data_Logger.ls`.
- Rollback: revert the script. The extra files can then be deleted.
- Verify after the first successful grab:
  - row counts of `EALInfo.csv` / `Events.csv` = `mdb-export | python csv` of the same `Logger.mdb`;
  - `.output` = the old script's output;
  - `Data_Logger.ls` shows whether older databases are kept.
