Fifth review of PCT-C: the uncommitted R4-1 fix and regression test above local DEV HEAD `00e94e1`.

**Findings: P1: 0, P2: 0, P3: 0.** No new correctness bug or regression found.

**Verdict: ready to promote the reviewed revision to STAGING and PROD through the normal workflow, after committing the reviewed fix and test. No blocking items remain.** This review performs no commit or promotion.

**R4-1: fixed**

In `read/sh/Philips/phil_ct_data_grab_1.sh:54–61`, session() now runs its monitoring and cleanup in a separate subshell. Killing only the collector shell no longer removes the process responsible for waiting on timeout and killing remaining members of the session's process group. The supervisor retains fd 9 until that cleanup completes.

I independently repeated the round-four combined case against the current script, with GNU timeout 8.32 and positive one-second limit/grace. The synthetic lftp started a same-group child that retained the lock and inherited stdout/stderr; the child installed its TERM-ignore handler before signalling readiness. Only the collector-shell PID was then SIGKILLed. Results:

- The separate supervisor survived and performed group cleanup after the monitored process exited.
- The resistant child was gone, inherited pipes closed, and a new lock acquisition succeeded within the configured deadline/grace budget.
- Published files remained unchanged. One private staging directory remained after the killed collector.
- The next grab exited 0, published its own synthetic database and removed the abandoned staging directory.

The ordinary, uninterrupted deadline case also preserved published files, emitted the expected timeout marker, closed the pipes and released the lock. No remaining failure was found for the combined scenario that blocked round four.

The handoff correctly distinguishes termination of the collector's entire process group: that can kill the new supervisor too. It is a documented broader termination limit, not a newly introduced regression or a remaining instance of the reviewed single-shell-PID failure. Untimed export/filesystem steps likewise remain outside the network-session deadlines. Neither is an additional promotion blocker for this change.

**New bugs or regressions**

None found. There are no P1, P2 or blocking P3 file/line findings to report.

**Answers to the three “Please look hard at” items**

1. **The supervising subshell is the right shape for R4-1.** The subshell owns its timeout child, so its own $! and wait refer to the correct process. GNU timeout still leads its separate session group; adding the supervising subshell does not change that group-ID calculation. The saved wait status is passed through exit, while a harmless failed group kill after all members have already exited cannot overwrite it. The existing success and failure branches therefore retain their prior runner classifications.

   The extra fd 9 holder is intentional: it keeps exclusion until cleanup finishes, including after collector-shell death. The background timeout command still has /dev/null stdin under noninteractive dash; the change does not add a terminal or alter the scripted lftp command argument.

   I found no interaction that prematurely removes staging or publishes from the supervisor. In this dash, exiting the helper does not run the parent's EXIT cleanup trap: normal acquisitions still export and publish successfully, and the killed-collector case leaves staging for the next locked grab. The session bookkeeping variables are now confined to the subshell; the rest of the script does not depend on their parent-shell values. The full current script and the diff against `00e94e1` are consistent with this scope.

2. **The new combined test covers the blocker and recovery.** It waits for a readiness file, kills the collector PID only, waits for lock availability and the child's close event, checks for resistant leftovers, checks that published files were preserved, and verifies the next acquisition and stale-staging cleanup. Resuming both output streams avoids pipe-buffer backpressure. The close promise is registered before termination, so an early close event is not missed.

   One precision point: the fixture's readiness file is written by the lftp parent immediately after forking the resistant child, rather than by that child after installing its trap. Thus the marker strictly proves launch, not the exact instant of handler installation. This does not block promotion: the source fix is correct, the regression test passes, and the independent experiment above used a child-owned acknowledgement after installing TERM resistance and confirmed the stronger case. The stated braces/return mutation targets the intended missing-supervisor behavior.

3. **Ready for STAGING and PROD.** R4-1, round four's sole blocker, is resolved. No additional blocking change or test is required by this review. Commit the reviewed uncommitted fix/test before promoting that revision; promoting unchanged `00e94e1` alone would omit the fix.

**Validation and scope**

The permitted Jest suite passed **51/51**; sh -n passed. Reviewed the requested diff and the complete current script. Tests ran behind an additional outer deny stub, and command -v lftp was checked against the experiment stub before local experiments. No real lftp or remote connection was used. Experiments used synthetic data in temporary directories and a subreaper to collect orphaned children. Resistant experimental processes were SIGKILLed if still live during teardown. Final checks found **zero live recorded experimental processes and zero distinctive deadline-test sleeps**.

No prohibited production tree was accessed. Source, unrelated WIP, index and commits were untouched; only this requested review artifact was added to the target repository. Real-data equivalence and production deployment claims in the handoff were not independently rerun.
