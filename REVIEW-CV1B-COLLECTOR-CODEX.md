# Philips CV collector implementation review

Reviewed `hhm_data_acquisition` `DEV` commit **`43888d9`**, against
`REVIEW-CV1B-COLLECTOR-HANDOFF.md` and `hhm_rpp_philips` plan §7.3,
§7.10 and §7.11. The previous parser review is closed and was not reopened.

**Verdict: address findings 1–2 before collector deploy: two P2 findings.
Finding 3 is a P3 follow-up that can wait. No P1 finding.**

All **61 tests pass** on Node **16.20.2** using the installed Jest:

```bash
cd /home/matt-teixeira/hep3/hhm_data_acquisition
./node_modules/.bin/jest read/__tests__ util/tools/__tests__ --runInBand --cacheDirectory=/tmp/cv1b-collector-jest-cache
```

The sandbox initially caused `spawnSync`/`execFileSync` to report `EPERM`
even when child programs completed. The same suite passed outside that
restriction; those errors are not implementation findings.

Additional probes used the actual shell script, system `unzip`/`mv`, and
the actual sweep selector with synthetic archives in `/tmp`. Only one probe
injects a failing `mv`; the existing-directory and incomplete-archive cases
use the real commands. The pre-change script from `aa68ceb` was used for the
compatibility comparisons. Reproducer: `/tmp/cv1b_collector_review.py`;
results: `/tmp/cv1b_collector_review_results.json`.

The supplied four-real-archive summary was inspected, not rerun. No `.env`
was read, no DB/Redis or device connection was made, and no raw device data
was copied into this report. Only this report was added to the collector
repository; the unrelated SQL and `handoff/` work was left intact.

## Must change before deploy

### 1. P2 — Failed publication can refresh the daily folder forever and prevent the 48-hour skip

**Location:** [parse_event_zip.sh:27](/home/matt-teixeira/hep3/hhm_data_acquisition/read/sh/Philips/parse_event_zip.sh:27)
through the final move at line 31.

The temp directory is correctly outside the daily folder, but each successful
companion-file move changes the daily folder's mtime **before** publication
of `EventLog.txe` has succeeded. If a later move fails, the primary file
remains absent and the next sweep repeats those companion-file replacements.
Every attempt resets the very clock used to decide when to skip the folder.

**Ordinary two-file input → wrong result:** an archive contains only
`EventLog.txe` and `EventLogSystem.txe`. The daily folder starts 72 hours
old. Inject failure of the final `mv` only, returning exit 73. The companion
is published, the primary is absent, and the folder is now approximately
**0.01 seconds old**. Repeating the attempt refreshes the mtime again. Thus
the parser keeps waiting at an error folder instead of skipping it after
48 hours. The current tests stop at unzip failure and do not exercise failure
during the publication loop.

**A permanent failure without injected commands:** add `Trace/new.txt` to
the archive and start with a nonempty `daily_*/Trace/` already present.
This is accepted by the old `unzip -o -d` behavior that the new script aims
to preserve. The real new script:

1. Moves `EventLogSystem.txe` into the daily folder.
2. Fails moving `Trace` over the existing nonempty directory, with
   `Directory not empty` and exit 1.
3. Never publishes `EventLog.txe`; every retry refreshes the folder mtime.

The old script exits **0**, merges `Trace/new.txt`, and publishes the primary
on the same input. The new behavior can therefore both prevent recovery of
an export and hold up later daily ingestion indefinitely. No extra directory
was shown in the supplied four real-archive samples; the ordinary two-file
publication-failure case does not require one.

**Change:** preserve a stable missing-file age across **publication** failures,
not only unzip failures. Make auxiliary-directory handling compatible with
the stated all-entries policy, or explicitly narrow that policy and validate
unsupported entries before modifying the daily folder. Keep `EventLog.txe`
publication atomic. Add repeated-attempt tests for a failed final move and
for an existing nonempty auxiliary directory, asserting both primary-file
behavior and the parser's 48-hour decision. The claim that every failure
publishes nothing and leaves mtime unchanged needs to match these paths.

### 2. P2 — A valid ZIP prefix can be published from an incomplete download and never repaired

**Locations:** the eligibility predicate at
[phil_cv_unzip_sweep.js:22](/home/matt-teixeira/hep3/hhm_data_acquisition/util/tools/phil_cv_unzip_sweep.js:22),
the sweep after download attempts at
[philips_cv.js:181](/home/matt-teixeira/hep3/hhm_data_acquisition/jobs/hhm/philips/philips_cv.js:181),
and [parse_event_zip.sh:24](/home/matt-teixeira/hep3/hhm_data_acquisition/read/sh/Philips/parse_event_zip.sh:24).

The handoff asks whether any incomplete-download shape can pass `unzip`.
**Yes.** An append-style ZIP can retain an earlier valid central directory
and end record before a later archive revision. Its earlier prefix is itself
a valid ZIP. CRC checks and `unzip` success establish the integrity of the
selected archive revision, not that the transfer reached the remote file's
end.

**Concrete input → wrong result:** the probe constructs a **429-byte** valid
archive. It begins with a **141-byte** valid older archive containing
`EventLog.txe`; the later revision contains the replacement primary and a
companion file. The complete 429-byte file is accepted by the real script
with exit **0** and publishes the new log. Downloading only its first 141
bytes is also accepted with exit **0**, but publishes the old log.

After replacing `Event.zip` with the complete 429-byte file, the actual sweep
selector excludes that folder because `EventLog.txe` already exists. The
old primary remains published. A parser can consequently advance past an
incomplete export, and a later successful transfer does not repair it.

This does **not** require scheduled jobs to overlap: a failed transfer can
leave that prefix at the final `Event.zip` pathname, and this run's sweep
checks existence without consulting the failed download result. The existing
fetch scripts write `Event.zip` directly; they do not explicitly arrange a
success-only publication. The synthetic archive demonstrates the ZIP-format
counterexample; it is not evidence that Philips currently emits this layout.
The supplied flat-archive examples establish no general producer guarantee
excluding it.

**Change:** make sweep eligibility depend on a finalized download, rather
than ZIP validity or file existence alone. A download to a temporary name
followed by a success-only rename is one small way to establish that boundary
for both regular and tunnel-reset fetches. Handle already-present historical
zips explicitly, rather than treating a new finalization rule as proof about
old files. An age delay or another `unzip -t` does not prove completion of a
failed transfer. Add a failed-transfer/valid-prefix case and ensure a later
completed transfer produces the correct primary instead of being skipped.

## Follow-up that can wait

### 3. P3 — Hidden archive entries are silently discarded on a successful run

**Location:** [parse_event_zip.sh:27](/home/matt-teixeira/hep3/hhm_data_acquisition/read/sh/Philips/parse_event_zip.sh:27).

**Input → wrong result:** an archive contains the two expected `.txe` files
and `.export-info`. The new script exits **0**, publishes the primary, and
deletes `.export-info` with the temp directory: Bash's `*` glob omits dot
entries. The old script exits **0** and leaves `.export-info` in the daily
folder. Both results were reproduced using the same archive.

Include dot entries if preserving all archive contents remains the policy,
or state and test the intended entry allowlist. This can wait because the
known two `.txe` outputs and the supplied real-archive results do not depend
on hidden entries. It does mean the existing equivalence test proves only
the selected flat, visible-file case.

## Other handoff decisions

- **Temp location:** correct for extraction failures: the daily folder is
  untouched until publication starts. A crash can leave an orphan dot folder
  as acknowledged; stale-temp cleanup can remain a later maintenance task.
- **Repeated bad archives:** visible retry without quarantine is an explicit
  policy. Finding 1 concerns the unintended effect of retries on the skip
  clock, not a request to suppress their errors.
- **Partial auxiliary publication:** exposing `EventLogSystem.txe` before
  the primary does not by itself expose a half-written primary. Its mtime
  effect and retry behavior are the blocker in finding 1.
- **Paths:** the scan/exec path equivalence is an existing deployment
  assumption and is stated to hold in prod. No additional path change is
  required by this review.
- **Tunnel reset and LOD:** the existing hard-coded FTP LOD script is outside
  this change. The sweep test correctly covers recovery while remote listing
  is unavailable; the primary publication issues above are not covered by
  that test's mocked unzip function.
