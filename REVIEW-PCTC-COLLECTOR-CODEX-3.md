Third review of PCT-C: uncommitted DEV changes above `aca5b3d`, 2026-11-20.

All source references below are relative to `hhm_data_acquisition`. Reviewed the handoff, the script and tests, and their diffs against `aca5b3d`. Unrelated WIP was excluded.

**Findings: P1: 0, P2: 3, P3: 0.** These are newly reported issues on this revision, including a remaining descendant-lifetime variant of N2. No new CSV-format or required-output publication regression was established.

**Verdict: not ready to commit and promote—optional state-file failures can terminate acquisition, and the finite-deadline guarantees still have two holes.**

**Findings, most severe first**

**R3-1 — P2: a failed listing-state redirection terminates the entire dash script.** `read/sh/Philips/phil_ct_data_grab_1.sh:153`, also `:148`.

The listing block uses `{ …; }`, so it executes in the collector shell. The state writes use `:`, a special builtin. Under the specified dash, failure to open its redirected output is fatal to that noninteractive shell; suppressing stderr does not contain the failure. The final `exit 0` is never reached.

Concrete scenario: the collector can write its output directory, but an existing, old `.listing.attempt` is a read-only regular file. The required database and four exports publish successfully. When the daily listing is due, `: >"$attempt"` fails, the collector exits 2 with empty stderr, and the runner takes its generic error path instead of recording acquisition success. A failed `: >"$pending"` during a shrink has the same effect. This contradicts the premise in review question 2 that failed state creation merely causes more listing attempts.

Reproduced both directory-at-state-path cases and a read-only regular attempt file: exit 2, empty stderr, required exports already installed. This is a control-flow bug, not just a missing optional diagnostic.

Suggested fix: isolate optional listing work in a subshell, `( … ) >/dev/null 2>&1`, with the parent explicitly retaining its success outcome. Also check state updates using operations whose failure can be handled without terminating the parent. If attempt time cannot be recorded, skip that optional attempt rather than opening an unthrottled session. Preserve the primary acquisition regardless. A local subshell-isolation experiment with the same failing state redirection returned 0 from the parent.

**R3-2 — P2: GNU timeout stops supervising when its direct child exits, even if a descendant still holds the lock.** `read/sh/Philips/phil_ct_data_grab_1.sh:68` and `:154`.

With GNU timeout 8.32, `-k` is not an unconditional process-tree cleanup deadline. Suppose the lftp process starts a child in the same process group that retains fd 9 and ignores TERM. At the initial deadline, lftp accepts TERM and exits. Timeout observes its direct child's exit and returns without staying alive to deliver the later KILL to that remaining descendant. The descendant can then hold `.grab.lock` indefinitely, so later grabs return 75 even after the advertised limit plus grace.

Reproduced with real GNU timeout 8.32 and synthetic lftp/child processes, using positive one-second limit and one-second grace. For both the main download and the listing, the collector returned 0, but after more than two seconds the descendant was still alive, held fd 9, and a new lock attempt returned 75. The main case emitted the intended timeout marker; the listing case remained silent. The children were explicitly killed afterward. The experiment establishes this conditional failure; it does not assert that the installed SSH normally ignores TERM.

The current N2 test makes the monitored lftp stub itself ignore TERM, so timeout remains alive long enough to perform KILL. That tests a different lifetime from a monitored parent that exits before its resistant child.

Suggested fix: use supervision that remains responsible for the process group through descendant cleanup, including when the direct child exits during the TERM grace. Keep the group supervised and the writer lock held until remaining members are terminated, rather than assuming `timeout -k` will always perform that cleanup. Retain private staging. Verify both a resistant leader and an exiting leader with a resistant child. A descendant retaining the runner's stdout/stderr pipes can additionally delay execFile completion; avoiding that pipe retention in an experiment does not solve the lock leak.

**R3-3 — P2: accepted zero settings disable the new deadlines or KILL escalation.** `read/sh/Philips/phil_ct_data_grab_1.sh:38–41`.

The validator accepts every nonempty digit string, including `0` and all-zero strings. GNU timeout treats a zero duration as disabling the corresponding timeout. Thus `PHIL_CT_DL_TIMEOUT=0` or `PHIL_CT_LIST_TIMEOUT=0` permits an unbounded session, while `PHIL_CT_KILL_GRACE=0` disables the forced KILL after TERM. These accepted values silently remove the safety mechanisms that N2 and the download-deadline change are intended to establish.

Reproduced a zero main-download limit with a gated stub: it remained running and held the lock until explicitly released. Separately, with a positive one-second listing limit, zero grace and a TERM-ignoring stub, the collector remained running beyond the limit and another lock attempt returned 75. These cases are not covered by the existing negative/non-digit settings test.

Suggested fix: accept positive, finite whole-second durations, rejecting all-zero strings and falling back to the defaults. Bound the accepted numeric range so it is representable by the actual timeout implementation. If disabling deadlines is deliberately supported instead, document that exception explicitly and withdraw the unconditional finite-lifetime guarantee; it would leave the original liveness risk available through configuration.

**Disposition of the requested round-two fixes**

| Item | Fixed? | Assessment |
|---|---|---|
| N1, partial failed listing published | **Yes** | The complete success chain now requires timeout/lftp success, nonempty output, chmod success and successful move. A failure before installation preserves the prior listing and mtime; the new partial-output test verifies this. |
| N2, TERM-resistant listing holds lock forever | **Partly** | Fixed for a resistant monitored lftp process with positive durations. The same-group resistant-descendant scenario remains (R3-2), and zero grace reopens the original behavior (R3-3). |
| N3, retries on every normal failed grab | **Yes, when state updates succeed** | Attempt time is independent of listing success; pending reset evidence gets immediate and then hourly retries. Tests exercise both policies. State-update failure is not safely degraded yet (R3-1). |
| Main-download deadline | **Partly** | The positive default deadline bounds the ordinary monitored transfer and routes timeout failures correctly. R3-2 and R3-3 prevent claiming a universal finite lifetime. |
| Q4 residue, listing-install diagnostic escapes | **Yes for stderr** | The whole brace block redirects stdout/stderr, including chmod/mv errors. The new directory-target test verifies silence. That redirection does not isolate a fatal shell error or exit status (R3-1). |
| R1 residue, table-name sed pipelines unchecked | **Yes in the code** | Lines 90–92 now check the split and each extraction independently; dash propagates the substitution's status to the assignment. The handoff overstates test coverage: the mdb-tables failure test exits at line 89 before reaching those new guards. |

The peak-disk changes also address the specific early-retention problems from round two: Events raw data is removed before awk processing, and EALInfo raw data is generated only when its processing begins. This reduces simultaneous large inputs without changing the intended exporter invocation order.

**Answers to the four “Please look hard at” items**

1. **Timeout, execFile, lock and classification.** GNU timeout's separate process group is appropriate here: normal deadline signals target timeout/lftp and their same-group children, rather than the collector shell or the Node runner. Inheriting fd 9 in timeout and the writer maintains exclusion while the monitored transfer is active. If only the collector shell is killed, timeout can continue supervising its direct child; the new handshake-based orphan test supports exclusion during that interval. It does not prove descendant cleanup after that direct child exits (R3-2).

   The 124/137 outcomes taking the existing download-failure branch are appropriate for this scope: preserved required outputs, the synthetic timeout marker, exit 0, and the runner's connection retry/reset classification. The real-runner test verifies the ordinary deadline route. I additionally exercised a main stub that itself ignores TERM and requires KILL: the collector returned 0 with the timeout marker, preserved the old database, released the lock, and did not expose the synthetic arguments in stderr. This verifies the hard-kill branch under dash as well as the ordinary TERM branch. Zero values and descendant lifetimes still need the fixes above. The defaults remain a reasonable initial budget, subject to measuring actual successful transfer times.

2. **Listing state races and creation failure.** The lock serializes ordinary collectors, so there is no newly established inter-grab race in these two state files. The failure premise is incorrect under dash: unsuccessful `:` redirection can terminate the collector, rather than simply failing to advance the throttle (R3-1). Optional bookkeeping failure must not alter a completed primary acquisition. A safe policy is to skip optional work when attempt state cannot be recorded; do not launch untracked retries on every grab. Failure to record a reset flag can lose the desired retry persistence, but should still be contained within optional work.

3. **Can the silenced block affect exit status or required outputs?** It does not intentionally rewrite the required database or four exports, which are already published. It can nevertheless terminate their acquisition invocation with exit 2 through a special-builtin redirection (R3-1). It can also leave a descendant holding the lock after returning (R3-2), or block indefinitely with zero settings (R3-3). Silence only redirects diagnostic streams. Ordinary unsuccessful find/chmod/mv commands are otherwise followed by the explicit final exit 0; that ordinary behavior is correctly tested for listing installation failure.

4. **Round-two items 2–6, revisited.** Stale cleanup still relies on a stable lock inode and cooperative current staging writers retaining the descriptor; private staging remains valuable. An orphaned descendant retaining the descriptor causes overlong exclusion rather than unsafe concurrent cleanup, which is why R3-2 matters. Exit 75 remains an acceptable honest skip with error-log noise; a dedicated runner skip outcome is still a later interface improvement.

   The listing policy now handles failed attempts and persistent reset evidence more usefully. A shrink remains a heuristic, not a complete reset detector. Daily/hourly retry spacing applies between shrink events: every newly observed shrink forces an immediate attempt even if the last attempt was fresh. Consequently, the handoff's “worst case about 24 attempts/day” is not an unconditional bound under repeated shrink events, and its deploy note about one listing per day describes only the ordinary no-pending, no-new-shrink case. Those exceptions follow the stated immediate-on-shrink policy and are not additional counted bugs.

   Partial publication of the required files remains intentionally possible and correctly diagnosed. Separate legacy reader cursors still support the narrow mixed-pair reasoning; no whole-generation consistency guarantee or cursor-race fix has appeared. Peak staging is improved, but large input/output pairs still coexist during transformations, and sort may need its own scratch space. Budget old published files + staged database + completed staged outputs + the current transformation's input/output overlap, with separate allowance for sort scratch. I did not independently rerun real-data equivalence or inspect production.

**Remaining test gaps that matter**

- **State failures:** failed creation/truncation of each state file, including a read-only regular file and a directory at the path. Assert required publication, collector success, no optional session if throttle state cannot be recorded, and the runner's correct acquisition result. Cover the absent-file creation failure as well as existing-file update failure.
- **Descendant supervision:** monitored parent exits on TERM while a same-group child ignores TERM and retains fd 9 (both sessions). Check the lock after limit plus grace, remaining children, and runner-pipe completion. Killing the collector shell during supervision is a separate useful case; the existing orphan test releases its writer voluntarily instead of waiting for forced deadline cleanup.
- **Configuration boundaries:** zero and all-zero strings for each duration, plus an out-of-range digit string. Verify actual timeout argv/default substitution as well as behavior. The present malformed-settings test cannot establish these bounds.
- **New sed guards:** inject nonzero status from the split and each table-name extraction, including output-before-failure, and assert that published files are kept. A failure injected into mdb-tables does not exercise these guards.
- **Failure-test harness deadlines:** the synchronous tests for a resistant listing and stalled download do not specify a child-process timeout. Their elapsed-time assertions execute only after spawnSync returns, so removing `-k` or the main deadline can block until the fixture's 30-second sleep ends. Give the test child an independent bounded cleanup path so future deadline regressions fail promptly and leave no descendants. This is a test robustness gap, not another collector finding.

CSV decoding edge cases remain appropriately assigned to PCT-1b, as acknowledged in the handoff. Additional tests that merely mirror every ordinary command are not required to resolve this review.

**Validation and scope**

The permitted Jest suite passed **38/38**; `sh -n` passed. GNU timeout reports **8.32**. Tests ran with an additional outer deny stub, and `command -v lftp` was checked against the experiment stub before the local experiments. Experiments used temporary directories, synthetic data, stubs and the installed timeout; no real lftp session or remote connection was needed. Known resistant experiment descendants were explicitly terminated. No prohibited production tree was accessed, and no source, unrelated WIP, index or commit was modified. Only this requested review artifact was added to the target repository.
