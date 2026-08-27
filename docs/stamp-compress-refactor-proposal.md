# Proposal: daily log bundling for /opt/run-logs (the stamp_compress refactor)

FLEET-TODO 2b. **APPROVED AND EXECUTED 2026-08-27** (all seven decisions:
Matt approved 1–6 and the proposed values; #7 resolved as "winston is
deprecated — verify and remove" instead of re-homing its output, and the
verification confirmed it: ~70% of its files were empty, none read).
Implemented: the bundle stage in `scripts/prune-run-logs.sh` (first run:
15,644 files → 41 day-bundles, `/opt/run-logs` 2.7 GB → 886 MB, restore
verified), the root-file moves, the winston retirement (`2dca114`), and the
7 vendored stamp_compress.sh deletions. This document remains as the design
record; the living rules are in the script header and doc 2.1 STEP 10.

## What stamp_compress.sh was, and the value worth keeping

The vendored `utils/logger/stamp_compress.sh` (present, dead, in 7 of our
trees) was a pre-Docker daily job: gather an app's per-run JSON logs, file
them into a `YYYY-MM-DD/` directory, gzip, delete the loose originals.

**The value: logs organized by day, compressed, instead of thousands of loose
files that sit raw until a prune deletes them.** That value is real today:

| measured 2026-08-27 | value |
|---|---|
| `/opt/run-logs` total | **2.7 GB**, ~20k loose per-run files |
| biggest (ours) | data_acquisition 8,884 files / 585 MB; philips 6,679 / 524 MB |
| compression sample (real run log) | 90 KB → 5.9 KB (**~15×**) |

The implementation is not worth reviving: hardcoded pre-Docker paths
(`/home/<run_env>/<app>/…`), it scoops **all** current files (today's
half-written logs get filed under yesterday's date), `mkdir` under `set -e`
dies on a same-day re-run, no locking, gzips files individually instead of
bundling.

## Current lifecycle (what the refactor slots into)

- Release runs write per-run JSON to `/opt/run-logs/<app>/` (LOG_DIR mount);
  cron `.out` files are bounded (overwritten per run — no growth; excluded
  from all of this).
- `data_acquisition/scripts/prune-run-logs.sh` (nightly 03:30, matt's
  crontab) already owns the **cross-app** sweep: deletes loose run logs
  >30 days in `/opt/run-logs/*/`, >14 days in dev trees; one summary line to
  `/opt/run-logs/prune.log`.
- The authoritative run record is the DB (`util.app_run_logs` /
  `stats.job_runs`), not these files — files are the verbose forensic copy.

## Proposal — extend the prune script; do NOT resurrect per-app copies

One new stage in `prune-run-logs.sh` (renamed conceptually: prune →
log-lifecycle), running in its existing 03:30 slot:

1. **Bundle**: for each `/opt/run-logs/<app>/`, take per-run files whose
   mtime-day is **≥ 2 days old** (a closed day — nothing still writing), tar
   them into `archive/YYYY-MM-DD.tar.gz` grouped by mtime-day, verify the
   tar reads back (`tar -tzf`), then delete the bundled originals. A day
   whose bundle already exists is skipped (idempotent; re-runs safe).
   `flock -n` on the script as a whole.
2. **Prune (changed)**: loose-file deletion at 30 days becomes a safety net
   only (bundling normally empties the window first). New retention applies
   to bundles: delete `archive/*.tar.gz` older than **180 days**.
3. **Dev trees**: unchanged (14-day delete, no bundling — dev logs are
   scratch).

Net effect: `/opt/run-logs/<app>/` holds ~2 days of loose files + one
compressed bundle per day; storage drops ~15×, so 180-day retention costs
about what 12 days costs today; `ls` becomes readable.

Why this shape and not a modernized per-app script: the writer surface is
central (`/opt/run-logs`), the cross-app sweep owner already exists, and one
script + one cron entry beats 12 vendored copies + 12 cron entries that must
be kept byte-identical (the fleet's own hand-copy lesson).

## Uniform layout standard (naming + compartmentalization — Matt, 2026-08-27)

One shape for every app's dir; the bundler ENFORCES it by only ever touching
files that conform:

```
/opt/run-logs/<app>/                      # exactly one dir per app, named as /opt/apps/<app>
  <APP_NAME>-log.<USER_ID>.<run_id>.json  # per-run structured log — loose for ≤2 days
  cron.<job>.out                          # bounded per-job cron capture — overwritten, NEVER bundled
  <name>.log                              # append-mode script log (e.g. cron.backup's) — NEVER bundled
  archive/YYYY-MM-DD.tar.gz               # the daily bundles
```

Rules, and the deviations found 2026-08-27 that each one corrects:

1. **Nothing loose at `/opt/run-logs` root.** Today: `prune.log`
   (data_acquisition's) and `partition-watchdog.log` (pg_manage_v2's) sit at
   root. Move each into its owner's app dir — two one-line path edits in the
   owning scripts, shipped with this refactor.
2. **Every file log an app writes lives under its ONE dir.** Today:
   data_acquisition's winston side-logger writes `adp.<USER_ID>_<ISO>.log`
   into the release tree (`/opt/apps/data_acquisition/logs/`, 7 MB and
   growing — inside build output, invisible to the prune). Fix with the
   established mount pattern: `${SIDE_LOG_DIR:-./logs}` compose mount,
   `#RELEASE:SIDE_LOG_DIR=/opt/run-logs/data_acquisition`. Optional rename
   of the `adp.` prefix to `data_acquisition-side.` (a logger.js touch) —
   decision 7.
3. **Structured per-run logs**: `<APP_NAME>-log.<USER_ID>.<run_id>.json`.
   Ours all conform. Accepted deviations, documented not fought:
   part-source-pipeline's prefix is `part_source_pipeline` (APP_NAME is a DB
   identity — the underscore/hyphen split stays); legacy `-log.dev.*` /
   `-log.staging.*` tags (retired-era files) age out via bundling+retention;
   the other fleet's `.js` extension on JSON logs is theirs to keep or fix.
4. **Bundle stage matches ONLY `<APP_NAME>-log.*` per-run files** — never
   `cron.*.out`, never `*.log` append files, never subdirs (acquisition-v2's
   `shadow-windows/` is left alone). Naming discipline and the bundler's
   file-selection are the same rule, which is what keeps both honest.

## Cross-fleet note (flag to the other fleet, don't block on it)

`/opt/run-logs` also holds mmb-rpp / alert-processor / odd-jobs /
alert-notify dirs (1.5 GB of the 2.7 GB). The prune script **already
sweeps them** — bundling would too, under the same established ownership.
Courtesy note to their owner before enabling; an `EXCLUDE` list ships in the
script if they want out.

## What happens to the 7 vendored stamp_compress.sh copies

Superseded the day this lands: delete in the next natural commit to each
repo (their function lives centrally). Until then they stay as-is.

## Decisions requested (Matt)

Settled 2026-08-27: naming conventions uniform to the extent reasonable;
uniform compartmentalization of logs (the layout standard above).

1. Ship it? (implementation ~60 lines in prune-run-logs.sh + tests)
2. Bundle-after threshold: **2 days** proposed.
3. Bundle retention: **180 days** proposed (vs 30 today — near-free).
4. Other fleet's dirs: include (default) or EXCLUDE list from day one?
5. After it lands: delete the 7 vendored copies as described?
6. Root-file moves (rule 1): `prune.log` → `data_acquisition/`,
   `partition-watchdog.log` → `pg_manage_v2/` — ship with the refactor?
7. Winston side-logger (rule 2): mount move ships with the refactor
   (data_acquisition release required); also rename the `adp.` prefix to
   `data_acquisition-side.`, or keep `adp.`?

Verification plan (when approved): dry-run mode printing the per-day file
sets first; one manual run; verify a bundle restores (`tar -xzf` + spot-open
a JSON); next 03:30 cron cycle produces the prune.log summary line with
bundle counts; file counts in `/opt/run-logs` drop to the 2-day window.
