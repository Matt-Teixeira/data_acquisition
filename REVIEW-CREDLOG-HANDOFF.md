# Review handoff: credential redaction in run logs (DEV, uncommitted)

Date: 2026-11-11 · Branch: `DEV` · Context and numbers: `PLAN-CREDENTIAL-LOGS.md`
Reviewer output goes to `REVIEW-CREDLOG-CODEX.md`.

**Ground rule for the review: never print, quote or copy a credential.** The tests use
generated fake values only. If you need to look at real logs or DB rows, count; don't print.

## Problem in one paragraph

Collectors decrypt device credentials (`util/encrypt` `decryptString`) and pass them as argv
to shell scripts (`[host_ip, user, pass, ...]`). The wrappers in `read/exec-*.js` then log
them three ways: (1) on **every** run, the `cal` note holds `args`
(`read/exec-hhm_data_grab.js:27-36`, `exec-phil_cv_data_grab.js:28-34`,
`exec-list_dirs.js:29-34`, `post_tunnel_reset/*`); (2) on failure, `utils/logger/log.js`
stores `err.stack`, which starts `Error: Command failed: <script> <ip> <user> <pass> ...`;
(3) `console.log(error)` / `console.log(note)` print the same, plus `cmd`/`stdout`/`stderr`.
Sinks: `util.app_run_logs.verbose_log` / `warn_error_logs`, the local run-log file (same JSON),
console (cron output; discarded on prod: no MTA), `stats.job_runs.error_message`.

## Fixes after the Codex review (`REVIEW-CREDLOG-CODEX.md`, 2026-11-11)

| Finding | Fix | Checked |
|---|---|---|
| P2: the clean-up only counted `stats.job_runs.error_message`; it didn't redact it | The SQL gets rule R5 `pg_temp.credlog_redact_text`. `error_message` is plain text, so it masks to the real end of line; the JSON rules stop at `"`, which would leave part of a password containing a quote. `apply` now UPDATEs the table, `dryrun` counts it, and `verify` reports `job_runs_residual` (expect 0). | Prod today (read-only): 344,777 rows, 151 with an `error_message` (all job `monday`), 0 with `Command failed:` or a credential shape. Throwaway PG with fake rows: only the credential row changed, the password with `"` fully masked, the stderr line kept; MMB, `monday`, NULL and after-cutoff rows untouched; second `apply` changed nothing. |
| P2: `console.trace` wasn't wrapped | `trace` is added to the wrapped methods, and this handoff's claim is corrected. | On Node 16 `trace` already went through the wrapped `error` (output masked). The test now captures `trace` as a direct writer, so only the explicit wrapper protects it. Mutation (remove `trace` from the list) fails the console test. |

Also since the first handoff:
- Every section of the clean-up SQL is now opt-in (`-v rehearse|dryrun|apply|verify|vacuum_list=1`), and the script refuses to run without `-v cutoff=…`. The write path was rehearsed on a throwaway PG 14 (plan §6.1).

## Design change after the review: the shared logger is no longer modified (please re-review)

At commit time it turned out that **`utils/` is not untracked: it's a separate git repository,
`AvanteHS-RTT/utils`, used by all 8 prod apps** (`hhm_data_acquisition`, `hhm_rpp`,
`hhm_rpp_ge`, `hhm_rpp_siemens`, `mmb-rpp`, `alert-notify`, `alert-processor`, `aws-ff`, all
on its `PROD` branch). The earlier `log.js` patch required `../../util/redact`, which exists only
in this app. Shipped through that repo, it would have broken the other seven. (`git add -f` in
the outer repo also silently did nothing, because the path sits inside the nested repo.)

So:
- `utils/logger/log.js` is restored to its committed version. The `utils` repo is clean,
  and its `log.js` is byte-identical to prod's.
- Redaction now happens in this app, on the events, right before the shared logger serializes
  them: new `util/flush_run_log.js` does `redactInPlace(run_log.log_events)` →
  `dbInsertLogEvents` → `redactInPlace` again (dbInsertLogEvents appends its own event) →
  `writeLogEvents`. `index.js` calls it instead of the two calls it made before; it is their
  only caller.
- The shared logger's own console prints (its dev-mode `console.log(err_msg)` and the
  FIRST/LAST event lines) are covered by the console guard that `index.js` installs.

## What changed

| File | Change |
|---|---|
| `util/redact.js` (new) | Process-wide registry of secret values. `redactString`; `redactInPlace` (scrubs every string reachable through array items and own enumerable properties, i.e. what `JSON.stringify` serializes, including an execFile Error's `cmd`/`stdout`/`stderr`, plus an Error's `message`/`stack`; cycle-safe); `safeStringify` (redacted copy; unit-tested, not used on the runtime path); `redactFormat`; `installConsoleRedaction`. |
| `util/flush_run_log.js` (new) | redact → DB insert → redact → file write, as above. |
| `util/encrypt/index.js` | `decryptString` returns `registerSecret(decrypted)`: every decrypted value is registered at the one place plaintext credentials come into existence. |
| `index.js` | `installConsoleRedaction()` at boot (all cron jobs enter here via `npm run`); `flushRunLog(pgp, run_log)` replaces `dbInsertLogEvents` + `writeLogEvents`; `stats.job_runs.error_message = redactString(error.message)`. |
| `jobs/hhm/run_manual.js` | removed `console.log(user)` / `console.log(pass)`. |
| `jobs/hhm/philips/philips_mri.js` | removed `console.log(system_creds)` (encrypted row; the key is in the repo, so effectively plaintext). |
| `util/__tests__/credential-redaction.test.js` (new) | jest test, below. (`tests/` is gitignored, hence this location.) |
| `maintenance/credlog/redact_app_run_logs.sql` (new) | clean-up SQL for existing rows (separate step, not part of the code fix). |
| `maintenance/credlog/redact_run_log_files.js` (new) | clean-up tool for existing run-log files (separate step). |
| `utils/logger/log.js` (shared repo) | **unchanged**. |

Unchanged on purpose: the `read/exec-*.js` wrappers still put `args` in notes and still
`console.log(error)`. Every sink is covered centrally, so no caller needs to change, and
future callers are covered too.

## Design

- **Exact values, not positions.** What gets masked is the set of values `decryptString`
  returned in this process (one cron run = one process), plus the forms they take when
  embedded elsewhere: JSON-escaped, `util.inspect`-escaped, URL-encoded. Longest first,
  so a value that contains another registered value is masked whole. No regex on argv
  positions, so it doesn't matter which field, which script or which argument order.
- **Redact the objects, not the JSON text.** `redactInPlace` replaces string values before
  the shared logger's `JSON.stringify` runs, so the output is always valid JSON, whatever
  characters the secret contains. Scrubbing the finished JSON text could break the `json`
  column for a secret containing `"` or `\`. Mutating is safe: the flush is the last thing a
  run does.
- **Console:** `installConsoleRedaction` wraps `console.log/info/warn/error/debug/trace`
  once, as `original(redactString(util.format(...args)))`. With no secrets registered it
  passes the args through untouched. `trace` is wrapped explicitly: Node 16's `trace`
  happens to print via `this.error`, but that's an implementation detail.
- IP, script path, stderr text and stack are kept. Only the values are replaced by `***`.

## How it was checked

1. `npx jest util/__tests__/credential-redaction.test.js`: **8/8 pass**, against the
   **unmodified** shared `log.js`.
   - Fake credentials are generated per run and go through the real
     `encryptString`/`decryptString`. The password contains `"`, `\`, a space, `'`, `&`
     and `/`.
   - A real `execFile` runs a temp script that fails and echoes all its args to stderr.
     That goes through the real `exec_hhm_data_grab` wrapper (failure and success paths),
     then `flushRunLog` (Redis and the PG pool mocked; the INSERT text is captured).
   - Control: the raw `error.message`, `.stack`, `.cmd` and `.stderr` do contain the fake
     values, so the scenario is real.
   - The `util.app_run_logs` INSERT, the run-log file and all console output (including
     `console.trace`) contain none of: the raw value, its JSON-escaped, inspect-escaped,
     URL-encoded or SQL-quoted forms.
   - The file is valid JSON. The error event reads
     `Command failed: <script> 10.0.0.1 *** ***`, and the logged `args` are
     `["10.0.0.1","***","***",…]`.
   - A unit test covers `redactInPlace` on nested objects, arrays, Error own props and a cycle.
2. **Mutation check** on a scratch copy (repo untouched): each part of the fix is
   load-bearing.
   - Both `redactInPlace` calls removed from `flushRunLog` → DB and file tests fail.
   - `decryptString` not registering → DB, file and console tests fail.
   - `trace` dropped from the guard → console test fails.
3. `node --check` on every changed file.
4. Cost: `redactInPlace` on a 5.2 MB run log with 40 registered values takes 32 ms. It's a
   no-op when nothing matches.
5. Existing suites `tests/config`, `tests/jobs/hhm` **already fail on DEV before this change**:
   they import `../../config` and `jobs/hhm/acquisition`, which exist only on the Docker
   line. Not touched.

Not run: a live collector run against a real device (that would put real credentials in
play). After deploy, the plan's post-deploy check counts new rows only.

## What to look at

1. **Coverage of sinks.** Is there any path from a decrypted value to storage or output
   that bypasses `flushRunLog`/`redactInPlace`, `redactString` or the console guard? Known residuals:
   `process.stdout.write` (not used in app code), Node's own printing of an *uncaught*
   exception or unhandled rejection (bypasses `console`; exec errors are caught in the
   wrappers), `console.dir`/`console.table` (not wrapped; not used on these paths), and
   the winston `logger.js` (untracked; its callers don't receive credentials:
   `exec-tunnel_reset.js` is dead code).
2. **Registration completeness.** The only plaintext source is `decryptString`. Is there a
   credential that reaches argv without it? `util/encrypt/enc_denc.js` has its own
   `decryptString`, but nothing requires it.
3. **Over-redaction.** A short or common credential value (say a username like `service`)
   gets masked wherever it appears in that run's logs. That's intended (safety over
   readability). A one-character value would make logs ugly but still valid JSON.
4. **`installConsoleRedaction`**: formatting changes only while secrets are registered
   (args are pre-formatted with `util.format`, so no colours on a TTY). Any caller that
   depends on `console.log` receiving objects?
5. **Module identity.** `util/encrypt/index.js`, `util/flush_run_log.js` and `index.js` must
   resolve to the same `util/redact.js` instance (they do: one path, one cache entry).
6. **`redactInPlace` coverage vs `JSON.stringify`.** It walks own enumerable keys, like
   `JSON.stringify`. Is there an event value whose serialized form comes from something
   else, such as a `toJSON()` or a getter returning a fresh string? None in the current
   events (Dates and plain objects only).
7. Clean-up SQL and file tool are a **separate step** (plan §6). Review them for
   correctness and blast radius, but they're not part of this commit's runtime change.
   - They're structural: the values are unknown, and decrypting is off-limits.
   - The rules are limited to the credential scripts (`./read/sh/GE/*`, `Philips/*`,
     `Siemens/siemens_c*`).
   - Rehearsed read-only on two real days: rows changed = rows holding credentials, 0 left,
     valid JSON, idempotent.
   - Points to check: the JSON-string-body regex `(?:[^"\\]|\\.)*`, R3 stopping at the
     escaped `\n`, the `(?!"\*\*\*","\*\*\*")` residual lookahead, and the per-day `COMMIT`
     inside `DO` (PG 16, autocommit).
   - Known gap: a credential echoed verbatim in stderr or stdout text (no script does this
     today) isn't caught by the structural rules.

## Not changed / out of scope (listed in the plan)

Credentials on argv (visible in `ps`; no `hidepid`), the hardcoded encryption key in
`util/encrypt/index.js`, the commented credential-like literal block in that file, file
modes (`/home/prod` 0777, `.env` and run logs 0644), broken log rotation, the same leak on
the `*_docker` branches.
