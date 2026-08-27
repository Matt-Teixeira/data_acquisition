# Fleet findings — what transfers to any app on this host

**Derived document. Not the system of record.** Everything here is extracted from
`MIGRATION-HANDOFF.md` (2,194 lines, five sessions, append-only). That file remains authoritative;
this one exists so a reader who does *not* own mmb-rpp, odd-jobs, alert-processor or alert-notify can
find the parts that apply to him without filtering 2,000 lines of per-app migration detail.

- **Extracted:** 2026-08-24. **Source state:** last entry `[2026-08-24][odd-jobs]`.
- **`HANDOFF:NNNN`** = line number in `MIGRATION-HANDOFF.md`. Go there for full context and the
  original author's tag.
- **Nothing here has been reworded to change meaning**, but items have been re-scoped: the source
  tags entries by *who wrote them*, which buries fleet findings under app headings. Where the source
  says "your app" it means one of the original four; here it means yours.

**One caution about the source.** It is append-only and never rewritten, so status must be
reconstructed by reading forward. The most-cited artifact in it — the 2026-08-22 fleet worklist table
at `HANDOFF:1564` — is stale in at least one row. Current state as of extraction is in §1 below.

---

## §1 — Open code defects

Reshaped from the source's four-app grid (`HANDOFF:1569`), which is useless outside those apps. The
axis you want is *how to tell whether you have it*.

| # | Defect | Detect in your app | Fix |
|---|---|---|---|
| 1 | `writeLogEvents()` does not await its flush | Does it call `write_stream.end()` and return? | Await the `'finish'` event |
| 2 | `pg-pool.js` has no `connectionTimeoutMillis` | Absent from the pool config | Set it — **fleet decision pending**, see §6 |
| 3 | `build.sh` sources `.env` as shell | `source .env` / `. .env` anywhere in it | `grep`/`cut` out the one var it needs |
| 4 | `stamp_compress.sh` present and dead | `utils/logger/stamp_compress.sh` exists | Delete — **fleet decision pending**, see §6 |
| 5 | `preflight-check.sh` masks only `*PW*` | Substring test on `PW` in the masking rule | Widen the glob |
| 6 | Preflight PG probe unguarded under `set -e` | `PG_OUT=$(docker run …)` with no `\|\| true` | Add `\|\| true` |

**Status on the original four:** 1 and 4 were open on some apps at last write; 2, 3 and 5 were open on
**all four**; 6 was mmb-rpp-only. Treat all six as unverified on your apps.

**Not in the table — already closed fleet-wide.** The idle-pg-pool leak. The 08-22 grid does not list
it and the 08-23 entry at `HANDOFF:1631` says mmb-rpp and odd-jobs still leak; both were fixed later
that same day (`HANDOFF:1790`, `HANDOFF:1982`). All four are now clean. **Check yours anyway** — the
symptom is a container lifetime of 10–60s for milliseconds of work, and the tail length tells you
which default you inherited: apps setting no `idleTimeoutMillis` get node-postgres's 10s
(`pg-pool/index.js:99`), apps setting 60s explicitly get 60s. Fix is `db.$pool.end()`, **not**
`pgp.end()` — if `index.js` instantiates its own pg-promise for `pgp.helpers`, ending that one closes
a different, empty instance and changes nothing (`HANDOFF:1631`).

### Why 1 and 2 matter more than they look

Both convert a real failure into **no evidence at all**, which is the hardest class to operate.

- **Flush (`HANDOFF:1579`).** `end()` only *starts* the flush. A stream `EACCES` then arrives as an
  unhandled `'error'` and kills the process, so the catch never sees it. A cron run as `svc` with
  wrong log-dir ownership dies with no log file **and** no `app_run_logs` row — indistinguishable
  from "cron never fired."
- **`connectionTimeoutMillis` (`HANDOFF:1586`).** Absent, an unreachable database *hangs* rather than
  errors. Measured: a container sat until killed. The cron entry produces an empty `.out`, which also
  reads as "never ran."

Two independent silent-death paths converging on the same symptom is the argument for bounding every
cron entry's stdout to a real file rather than `/dev/null`.

### Two warnings attached to fixing these

- **Fixing #1 can remove protection you did not know you had** (`HANDOFF:1695`). On alert-notify the
  flush fix was correct *and* deleted an accidental brake: `svc` failing to write the dev log
  directory used to kill a mis-launched production run before it could send. Post-fix the error is
  caught and the run continues. Ask what your app was getting for free.
- **#1 is also a testing trap, not only a defect** (`HANDOFF:622`). A test or preflight check that
  reads the log file immediately after writing can see 0 bytes and conclude the logger is broken.
  Poll for non-empty content.

### #3, with the part that actually bites

A real `OUTLOOK_PW` containing `$` and `)` produced `syntax error near unexpected token ')'` at build
(`HANDOFF:1204`). **The `)` is the lucky half — it failed loudly.** A value containing only `$`
sources "fine" with the variable expanded to nothing, and you build with a silently mangled secret.

Interim mitigation is ~15 lines and worth copying before the real fix: a preflight check that errors
on any unquoted value containing ``( ) $ \ ` space quote & ; | < > ! * ?``. Negative-tested on
alert-notify.

Debugging note if you hit the error (`HANDOFF:1215`): **the reported line number refers to the
release copy, not your dev tree.** `build-release.sh` strips the two `#RELEASE:` marker lines, so dev
line 17 was release line 15 — a blank line in the dev file. Count in the transformed copy.

---

## §2 — Credential exposure on this host

**Deployed `.env` files are world-readable with live credentials.** Two surveys a day apart disagree
on the count — `16 of 18` (`HANDOFF:1189`) and `15 of 19` (`HANDOFF:1596`) — so **re-survey rather
than trusting either**. The disagreement is itself informative: the denominator moved, meaning apps
are being deployed into this state.

Confirmed by reading: `PG_PW` and `REDIS_PW` are recoverable from mmb-rpp's and odd-jobs' copies as
an ordinary user.

**Correct mode is `640`** (owner `rw`, group `docker` `r`, no world). Jonathan's stated pattern is
that `docker`-group membership is what grants access to `/opt/apps`.

> **Fix the dev tree first.** `build-release.sh` mirrors with `tar`, which **preserves the mode**.
> Fixing only the release copy reverts on the next deploy. Set `640` on the dev `.env` *before* your
> next release, not after.

Related, same blast radius: **`preflight-check.sh` masks only `*PW*`** (`HANDOFF:1225`), so it prints
every other credential in full. It printed `TWILIO_AUTH_TOKEN` verbatim to a terminal the moment real
credentials existed; `PG_PW` and `OUTLOOK_PW` were hidden purely because the test is a substring match
on "PW". Widened rule: `*PW* *PASS* *TOKEN* *SECRET* *KEY*`. Apps holding only `PG_PW`/`REDIS_PW` get
away with the narrow rule by luck, not design.

**Secrets rotation** (`HANDOFF:1604`, `HANDOFF:313`): registration is per-`.env`-path, and an
unregistered app fails **silently and indefinitely**. Requests go to matt-teixeira, and the fleet
convention is one combined ask covering every path rather than one per app. Phrase it as "create
*and* register" — the register half is the half that gets dropped.

---

## §3 — Database-wide (affects every app, not just odd-jobs)

Everything in this section is filed under odd-jobs in the source because odd-jobs found it. It is not
odd-jobs' problem. **`util.app_run_logs` is partitioned**, so every app that logs a run depends on
this subsystem.

### The dated one

**2026-09-01 14:00.** The monthly `pg-part-arch` run must create October partitions, or *every* app's
inserts fail on 2026-10-01. The 2026-08-01 run created nothing and went unnoticed for three weeks
behind a `/dev/null` redirect (`HANDOFF:1601`).

As of 2026-08-23 the DDL halves were both dry-run proven against the live schema inside rolled-back
transactions, so **what 09/01 still tests is only the plumbing** — cron firing, the release copy being
current, docker/auth/logging (`HANDOFF:2045`). Which is exactly the set that failed on 08/01.

Note: **a manual out-of-schedule run cannot pre-create October.** `lookahead_months = 1`, so any run
before September targets September and no-ops (`HANDOFF:2061`).

Diagnostic worth memorising: **a `no partition of relation ... found for row` error in ANY app means
this job failed or has not run.**

### The malformed-suffix class — most likely to be present in your DB

`mag.stt_magnet_2525_06` had a typo'd year in its *name* but the correct `2025-06-01 → 2025-07-01`
*bound*. `archive-partitions.sql` matches cohorts on `RIGHT(relname,7)`, which that name never equals
— so it was skipped when June 2025 came due and **would have been skipped forever**, silently, with
no error and not even the `RAISE NOTICE` that ARCHIVE swallows failures into (`HANDOFF:2066`,
`HANDOFF:2189`).

**Generalises: any partition whose suffix is malformed is permanently invisible to the archive job.**

The staging DB is derived from main production, and the typo came from a hand-run — hand-runs are not
unique to staging. **Expect the class in the main DB.** Detection query, safe to run anywhere
(`HANDOFF:2160`):

```sql
SELECT n.nspname||'.'||k.relname AS malformed, pg_get_expr(k.relpartbound, k.oid) AS real_range,
       pg_size_pretty(pg_total_relation_size(k.oid)) AS size, k.relpages, s.n_live_tup
FROM   pg_class k
JOIN   pg_namespace n ON n.oid = k.relnamespace
LEFT JOIN pg_stat_all_tables s ON s.relid = k.oid
WHERE  k.relkind = 'r' AND k.relname ~ '[0-9]{4}_[0-9]{2}$'
AND    RIGHT(k.relname, 7) !~ '^20(2[0-9])_(0[1-9]|1[0-2])$';
```

**Remediation differs by emptiness, and getting this wrong loses data.**

- **Empty** → `DROP` is safe. Ours was, and was dropped 2026-08-24 inside a transaction guarded by a
  `DO` block that would have raised rather than dropped on a non-zero count.
- **Holds rows** → `ALTER TABLE … RENAME TO <correct_suffix>`. Preserves the data and makes it
  visible to the cohort matcher, so the next run archives it normally. A malformed partition holding
  rows is worse than a naming defect: its month is attached to the live parent permanently and keeps
  growing while every neighbouring month is archived out from under it.

**Confirm emptiness three independent ways** (`HANDOFF:2147`): exact `count(*) = 0`, `relpages = 0`,
and lifetime `n_tup_ins = 0` with `pg_stat_database.stats_reset` NULL. **Never infer it from
`reltuples`** — that reads `-1` on a never-analysed table, which looks like "unknown" but is easily
misread as "empty".

### Two permanent-lockup modes in the same job

Both make `pg-part-arch` fail **forever**, not partially — stronger than CLAUDE.md's "can leave a
partial month" implies.

1. **A 25th partitioned table** (`HANDOFF:2097`). `add-pg-table-partitions.sql` hardcodes 24 parents
   in a `partition_map` JSONB literal; `get-pg-table-partitions.sql` *discovers* `expected_parents`
   from any parent having a `YYYY_MM` child. Add a 25th and give it one partition by hand: discovered
   `expected` becomes 25, ADD still creates 24, the gate at `jobs/pg-part-arch.js:57` can never be
   satisfied, VERIFY reports `missing: 1`, and every subsequent run fails until the map is edited.
   **Both** `add-pg-table-partitions.sql` and `archive-partitions.sql` carry maps that must be
   updated.
2. **A parent whose only child is malformed** (`HANDOFF:2181`). A malformed name still satisfies the
   *discovery* regex (`2525_06` matches `[0-9]{4}_[0-9]{2}$`), so it inflates `expected` while ADD
   never provisions that parent. Same permanent lockup, reached by a typo instead of a schema change
   — **and the source judges this the more likely trigger of the two.**

### Testing gotcha

`archive-partitions.sql` line 3 declares `current_date DATE := CURRENT_DATE;`, and line 4 uses it.
`current_date` is a **reserved SQL keyword**, so line 4 resolves to the *function* and the declaration
is ignored (`HANDOFF:2075`). Zero production impact — identical value — but the cohort date is not
overridable there. A dry run against a shifted cohort silently targets today's instead and produces a
confidently wrong result. **Patch line 4, not line 3.**

---

## §4 — Practices that transfer

Condensed from `HANDOFF:1669`, written by the session that finished last and ordered by how much time
each would have saved.

1. **The release copy is not the code you just wrote, and it goes stale the moment you commit
   again.** Two separate sessions ran a release believing it contained work that existed only in the
   dev tree, and reported a performance fix as done while `/opt/apps` ran the slow version. Verifying
   at release time is not enough — it is a continuous property. **Automate it:** in preflight's
   dev-tree branch, compare deployed `RELEASE_SHA` against `git rev-parse HEAD` and report the commit
   count behind. ~12 lines, catches the whole class.
2. **Test through the real path, and make each check fail once.** `docker compose run --entrypoint
   node` silently runs as **root**, so any probe that skips `entrypoint.sh` proves nothing about
   `svc`. And a check that has only ever seen a healthy environment has been *demonstrated*, not
   *tested* — injecting a wrong `PG_PW`, a malformed address and a missing file is how the team
   learned theirs reported rather than aborted.
3. **A safety mechanism must apply to the invocation cron actually makes.** An argv-gated `dev` mode
   was built then discarded: cron runs `node index.js` with no arguments, so it could never have
   constrained a scheduled run. Config-driven covers every invocation. Enforce at **two independent
   boundaries** — a filter living only in SQL is one bad edit from unbounded behaviour.
4. **Ask what your data shape is hiding.** A test account's 1,628 subscriptions were all *default*
   models, so every run exercised one branch and never touched the `custom_alerts` branch — live for
   8 real users, 3 external. Your test user's data decides which code you never execute.
5. **Measure before sizing schedules.** Every app's apparent runtime was inflated 10–60s by an
   unclosed pool. Cadences chosen against those numbers would have encoded the artifact.

Corroborating specifics worth having:

- **Reproduce the root-owned-log-dir failure without `sudo`** (`HANDOFF:676`): point the log bind
  mount at a host path that does not exist. The daemon runs as root and creates it `root:root`.
- **Run release-copy preflight as `svc`, not as yourself** (`HANDOFF:1178`):
  `sudo -u svc env HOME=/tmp bash -c 'cd /opt/apps/<app> && bash preflight-check.sh'`. It exercises a
  branch the dev tree never reaches. A related defect found later: a check can report
  `User '<you>' is in docker group` — the *invoking* user — and would say the same thing if `svc` were
  not in the group at all (`HANDOFF:2114`). Assert on `id -nG svc`.
- **Check reachability, not just references** (`HANDOFF:1441`): every `.sql` file was referenced and
  every path resolved, and one query was still dead — reachable from no code.
- **`npm audit` noise** (`HANDOFF:1454`): lodash and uuid advisories were verified unreachable and
  deliberately not fixed; `pg-promise` was the one worth bumping (SQL injection, fixed in 11.5.5).
  Same trio likely on your trees.
- **Undeclared transitive dependency** (`HANDOFF:593`): `require('lodash')` resolved despite lodash
  not being a declared dependency — it arrived under `jsonwebtoken` under `twilio`. Works until that
  tree changes.

---

## §5 — Branch and merge traps

Applies to **any** app with a branch predating the utils de-git. Both traps are invisible to merge
tooling.

- **The conflict count lies** (`HANDOFF:1607`). On one 10-month / 30-commit-wide merge git reported 3
  conflicts, while the dangerous parts did not conflict at all: the other branch had refactored
  `index.js` into new directories, so replacement files arrived as clean **adds** containing none of
  the safety work, while the guarded originals appeared as **modify/delete**, which the obvious
  resolution deletes. Net effect of a mechanical merge: recipient guard, awaited status writes, the
  send restriction, `gracefulShutdown` and `RELEASE_SHA` all vanish **with no marker**.
  **Before merging anything:** `git diff --name-status <base> origin/<branch>` and look for *adds*
  that replace files you have modified.
- **Every pre-migration branch has an invisible dependency on a `utils` branch** (`HANDOFF:1619`).
  `utils/` was gitignored while those branches were developed, so the app repo records **nothing**
  about which utils branch its code needs. One branch imports a query that exists on no branch the
  team tracks. Discoverable only by grepping: for each `sql.js` identifier the branch imports, confirm
  it exists in your pruned tree. Same case also calls a query with no argument against SQL that now
  requires `$1::text[]` — a runtime break no merge tool flags.

---

## §6 — Open fleet decisions (need a decision, not a fix)

These are deliberately unresolved and were left that way to avoid divergence. Do not fix them
unilaterally on your apps — that is the outcome the source is trying to prevent.

| Item | State |
|---|---|
| `connectionTimeoutMillis` value | Held as a **fleet** decision rather than a fourth divergent `pg-pool.js` (`HANDOFF:1138`) |
| `stamp_compress.sh` | "Either retire it fleet-wide or fix it fleet-wide; don't let us diverge on it one app at a time" (`HANDOFF:598`) |
| `build.sh` durable fix | Logged, not done — same holding pattern (`HANDOFF:1212`) |
| Cadence + lookback sizing | Was blocked on all four apps being measured; **that blocker is now cleared** (`HANDOFF:1639`) |

Existing conventions two apps converged on independently, so treat as the standard rather than as
someone's preference: `max: 15` and `idleTimeoutMillis: 60000` in `pg-pool.js` (`HANDOFF:649`);
`Dockerfile` and `entrypoint.sh` are genuinely fleet-generic and should be taken **byte-identical**
rather than hand-written near-copies (`HANDOFF:671`); same for `utils/logger/log.js` (`HANDOFF:654`)
— hand-patching preserves a 3-space/4-space indentation difference that turns a future "are we still
in sync?" check into a 200-line whitespace diff.

---

## §7 — Process conventions

- **The shared `svc` crontab is a single-writer resource** (`HANDOFF:309`). Two concurrent
  `crontab -u svc -e` sessions and the last save silently wins, wiping the other. Sequence edits and
  announce in the findings log when yours has landed. Also: never `crontab -u svc <file>` — it
  replaces the whole file.
- **Apps with a data dependency are one ordered pair, not two schedules** (`HANDOFF:305`). Where one
  app writes what another reads, neither should hand over a crontab entry without the other's timing
  settled.
- **The findings log is append-only.** Never edit or reorder someone else's entry; tag yours
  `[YYYY-MM-DD][your-app]`; prefix cross-app requests with `ACTION FOR <app>:` so they are greppable
  (`HANDOFF:245`). Say whether you *verified* a finding or *inherited* it.
- **Supersession is by appending, not amending.** A wrong commit was deliberately left in history
  with a later one correcting it, so the correction stays visible (`HANDOFF:1894`). Consequence for
  you: **reading a single entry can give you the wrong story** — check for later entries on the same
  subject.

---

## Appendix — what this extract deliberately leaves behind

So you know what you are *not* getting, and where to go if you need it.

- Per-app migration step sequences, prune keep/drop lists, and commit-by-commit narratives —
  `HANDOFF:283` (greenfield sequence), `HANDOFF:318` (prune result).
- Three ordering constraints specific to apps starting from the shared-utils `PROD` state
  (`HANDOFF:259`): port `log.js` before anything depends on `LOG_DIR`; the clean-tree release guard
  is a lie while `utils/` is gitignored; land the `pg-pool.js` `ca:`/`cert:` fix before or with the
  preflight PG check, or preflight certifies a connection the app cannot make.
- mmb-rpp's capture-timing and cron-cadence measurements (`HANDOFF:1866`, `HANDOFF:1898`) — host
  specific, but read them before touching the `svc` crontab.
- The two session-opening prompt blocks (`HANDOFF:1`, `HANDOFF:1720`). These are scaffolding for
  Claude Code sessions and are scoped to the original four apps. **Not intended for human reading and
  not safe to paste as-is.**
