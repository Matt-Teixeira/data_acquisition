# Proposal: daily log bundling for /opt/run-logs (the stamp_compress refactor)

FLEET-TODO 2b. Decision requested at the bottom; nothing here is implemented.
Drafted 2026-08-27 from measured state.

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

1. Ship it? (implementation ~60 lines in prune-run-logs.sh + tests)
2. Bundle-after threshold: **2 days** proposed.
3. Bundle retention: **180 days** proposed (vs 30 today — near-free).
4. Other fleet's dirs: include (default) or EXCLUDE list from day one?
5. After it lands: delete the 7 vendored copies as described?

Verification plan (when approved): dry-run mode printing the per-day file
sets first; one manual run; verify a bundle restores (`tar -xzf` + spot-open
a JSON); next 03:30 cron cycle produces the prune.log summary line with
bundle counts; file counts in `/opt/run-logs` drop to the 2-day window.
