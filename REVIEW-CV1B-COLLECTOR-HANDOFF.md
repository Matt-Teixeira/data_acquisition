# Review handoff: Philips CV collector, unzip sweep and atomic unzip (CV-1b)

Please review the **implementation** of the collector part of CV-1b. The authoritative design is
`~/hep3/hhm_rpp_philips/PLAN-PHILIPS-CV-INSIGHTS.md`: §7.3 (design, items 1–2; items 3–4 dropped
there with reasons), §7.10 (this build and its evidence) and §7.11 (deploy order). Write findings to
`REVIEW-CV1B-COLLECTOR-CODEX.md`, as P1 / P2 / P3, each with a concrete failure (input → wrong
result). One round is planned: please separate what must change before deploy from what can wait.

## Why

The tunnel-reset job (`jobs/tunnel_reset/philips/philips_cv.js`) fetches daily `Event.zip` folders
but never unzips them. The regular run unzipped only `last_aquired_dir` and the folders it had just
fetched. So when one tunnel reset fetched two or more folders, all but the newest stayed zipped and
never reached `log.philips_cv_eventlog`: 129 intact zips in 2026. The parser (`hhm_rpp_philips`,
reviewed and closed separately) now waits at a folder without `EventLog.txe`, and skips it after
48 h measured on the **daily folder's mtime**.

## Scope

Repo `hhm_data_acquisition`, branch `DEV`, the commit that adds this handoff
(`git log -1 -- REVIEW-CV1B-COLLECTOR-HANDOFF.md`). These files only; the other
modified files in the tree (`db/normalize/*`, `db/tables/TABLES.sql`, `handoff/`) are someone else's
work and out of scope.

| File | What it is |
|---|---|
| `read/sh/Philips/parse_event_zip.sh` | atomic unzip: a temp folder next to (not inside) the daily folder; `mv` in, `EventLog.txe` last |
| `util/tools/phil_cv_unzip_sweep.js` (new) | `folders_to_unzip` (pure), `scan_system_folder` |
| `jobs/hhm/philips/philips_cv.js` | the sweep at the end of `run_phil_cv`, replacing the two old unzip calls |
| `read/__tests__/parse_event_zip.test.js`, `util/tools/__tests__/phil_cv_unzip_sweep.test.js` (new) | 10 jest tests |

## How to check

- `npx jest read/__tests__ util/tools/__tests__` (Node 16.20; no network, no DB): 61 of 61 pass.
  The equivalence test runs the pre-change script from commit `aa68ceb`.
- Real-data evidence (outside the repo; raw device data **with PHI**, please don't copy from it):
  `~/philips_cv_evidence/cv1b/15_collector_unzip_real.txt`, the new script on copies of 4 real zips,
  byte-identical to `unzip -p`.

## Already established

- 7 of the 10 tests fail against the pre-change code. The 3 that pass are by design: the two new
  pure functions, and a truncated zip, which the old script also refused, though in place.
- Schedules from 14 days of run logs: regular runs at :00/:30 (≤ 50 s); tunnel reset at :10/:40
  (≤ 7 min 10 s); the parser at :18/:48.
- The first deployed run unzips 123 pending old zips once (868 MB uncompressed; 1.1 TB free). They
  sit behind the parser's pointers, so the live parser ignores them.

## Judgement calls (please challenge)

1. **No "download finished" check in the sweep.** It relies on the two schedules not overlapping,
   and on `unzip` failing on a partial zip with nothing published. Is there a partial-zip shape that
   `unzip` accepts?
2. **The temp folder sits in `files/<SME>/`** (`.unzip_tmp.<daily>.<pid>`). The parser lists that
   folder with `ls` (no dot files) and only takes `daily_*` names. A crash leaves a dot folder that
   no one removes (the next run uses a new pid).
3. **All files in the zip are moved in**, not only the two expected ones, to match the old
   `unzip -o -d`. `EventLog.txe` goes last; earlier `mv`s can leave `EventLogSystem.txe` published
   when the final `mv` fails.
4. **Every pending folder, every run.** A permanently bad zip on a polled system fails and is logged
   every 30 minutes, with no quarantine (kept visible on purpose).
5. **`scan_system_folder` lists `system.debian_server_path`, while `exec_phil_cv_unzip` builds
   `${data_store_path}/${sme}/${daily_dir}` from `RUN_ENV`.** This is the same assumption the old
   `file_exists` + unzip pair made. On prod both resolve to `/home/prod/hhm_data_acquisition/files/<SME>`.
6. **Not changed:** the tunnel-reset path (it still doesn't unzip; the next regular run does),
   including its hard-coded `phil_cv_21_lod.sh` for SFTP systems (noted in §7.10); the lod scripts
   (they already publish `lod_EventLog.txe` with one `mv`).
