Fourth review of PCT-C at local DEV HEAD `00e94e1`, including original commit `aca5b3d` and the committed review fixes. Source references are relative to `hhm_data_acquisition`.

**Findings: P1: 0, P2: 1, P3: 0.** The one finding is a remaining R3-2 interruption scenario. No additional independent regression or blocking P3 was established.

**Verdict: not ready to promote to STAGING or PROD.** The sole blocker is R4-1 below. It is unblocked by moving session monitoring/cleanup into a supervisor that survives collector-shell termination, and passing the combined interruption test plus the existing suite. No other blocking items are requested.

**R3 dispositions**

| Previous finding | Fixed? | Assessment |
|---|---|---|
| R3-1: optional state writes terminate dash | **Yes** | External touch replaces the fatal special-builtin redirections; failed attempt recording skips the optional session. A shrink independently forces an immediate attempt even if the pending flag cannot be created. The surrounding subshell also contains exit/fatal-shell behavior. Tests cover failed attempt recording, a read-only existing attempt and failed pending-flag creation without losing primary acquisition success. |
| R3-2: resistant descendants outlive timeout | **Partly** | When the collector survives, session() now kills remaining same-group descendants after success, failure or deadline. The tests exercise these paths and the runner's pipe completion. If the collector shell is terminated while it waits, its post-wait cleanup never executes, reopening the lock leak (R4-1). |
| R3-3: zero disables deadlines | **Yes** | Validation rejects zero, all-zero strings, non-digits, overlong values and values outside 1–86400; leading zeros are normalized through decimal expr arithmetic. Actual timeout-argv assertions verify defaults and valid overrides. No zero-duration hole remains in the reviewed code. |

**Blocking finding**

**R4-1 — P2: killing the collector shell bypasses the remaining-descendant cleanup.** `read/sh/Philips/phil_ct_data_grab_1.sh:52–58`, called for the main download at `:89`.

The new process-group cleanup belongs to the collector shell itself. A concrete remaining sequence is:

1. The main lftp session starts a same-group child that retains fd 9 and ignores TERM—the descendant scenario already covered by R3-2 and the new fixtures.
2. The collector shell is terminated while its session() function is waiting for timeout. Timeout and its children survive, retaining the lock.
3. At the transfer deadline, lftp accepts TERM and exits. GNU timeout returns after its direct child exits, without the later KILL escalation to the resistant descendant.
4. There is no collector shell left to execute line 57. The descendant retains the lock indefinitely; subsequent grabs exit 75 and the runner logs errors without recording an acquisition.

This requires interruption plus a resistant descendant; it is not a claim that the installed SSH normally ignores TERM. Both interruption of a running grab and the resistant-descendant condition are part of the lifecycle cases this change explicitly addresses. The existing tests exercise them separately, leaving this combination uncovered.

Reproduced with the committed script, dash and GNU timeout 8.32, using a stub lftp and a child in timeout's own group. The child retained fd 9. With positive one-second deadline and grace:

- Collector alive: timeout exited, session() killed the descendant, and another lock acquisition succeeded.
- Collector SIGKILLed after child readiness: timeout exited, but the descendant remained alive after deadline plus grace; another lock acquisition returned 75.

The reduced durations exercise the same control flow as the positive defaults; with default settings the hole occurs after the main deadline rather than after one second. All resistant experimental processes were explicitly SIGKILLed and reaped afterward.

**Suggested fix / what unblocks promotion:** put the wait-and-group-cleanup responsibility in an independent supervising child that survives the original collector shell, rather than relying on an EXIT/TERM trap in that shell. A function body using a subshell is one possible small implementation. In a throwaway copy only, changing session() to execute its body in a subshell made the same interrupted-parent experiment release the lock; a normal stubbed acquisition also completed and published all required files. This prototype was not applied to the repository and is not a substitute for running the complete suite on the eventual fix.

Add a deterministic test combining collector-shell termination with a monitored parent that exits on TERM and a resistant same-group child. Require that the descendant and inherited pipes close, the lock becomes available after the configured limit/grace, and the next grab can run without manual cleanup. Keep the existing success, ordinary timeout and resistant-leader tests.

**Answers to the four “Please look hard at” items**

1. **session(): group identity, reuse, wait, background stdin.** For the specified GNU timeout without --foreground, using its PID as its process-group ID is correct. Backgrounding the command does not insert another shell process in front of the direct external command; the timeout test wrapper uses exec and preserves that PID. The local interruption experiment also confirmed that the actual timeout PID equaled the session group ID.

   If descendants remain in that group, Linux retains its group identity, supporting the handoff's PID-reuse reasoning for the cleanup that matters here. If no members remain, the group kill normally fails harmlessly and its status is deliberately excluded from the returned session status. Reaping the leader and sending the group signal are not an atomic operation; I did not establish a realistic unrelated-group kill scenario and am not blocking on a hypothetical PID-reuse race.

   There are no caught-signal traps in the current collector that make an interrupted wait resume into special handling. Default terminating signals end the collector and bypass cleanup—R4-1. If signal traps are later introduced, an interrupted wait must also be distinguished from actual child completion.

   The background form gives the command /dev/null stdin under noninteractive dash. That is consistent with scripted lftp -c use: the commands are supplied as an argument, the runner already supplies no interactive terminal, and SFTP's SSH protocol streams are created by lftp rather than being an interactive collector stdin. The handoff's local file-protocol evidence supports this mode. I made no scanner/SFTP connection and cannot independently claim a real-server interoperability test.

   session() preserves the waited status despite the cleanup kill failing when the group is already gone. Main-session nonzero status still produces the synthetic timeout marker and exit 0; read/exec-hhm_data_grab.js:78–79 and :106–142 classify it for connection retry/reset. Success reaches :144–154. Lock contention and ordinary checked processing failures enter the nonzero catch path instead. The runner integration tests cover these outcomes. No new status-classification bug was found.

2. **Listing subshell and the uncaught braces mutation.** Keep the subshell. I found no remaining ordinary state-update fatal path equivalent to the old colon redirection: touch is external, failures are handled, and diagnostics stay inside the optional operation. The current block does contain explicit exit 0 guards. With braces, those would exit the collector, but today the parent would immediately exit 0 after the block anyway. Thus the documented passing braces mutation is consistent with the current observable behavior; it does not invalidate the direct state-failure tests. The subshell remains useful isolation for future changes, and there is no reason to manufacture a production-fatal operation solely to kill that mutation. It does not by itself solve the main session's separate supervisor-lifetime problem.

3. **Remaining unbounded lifetime with defaults.** R4-1 leaves a session descendant and lock unbounded even though its collector shell is gone. Apart from that demonstrated blocker, this is a network-session deadline design, not an overall wall-clock limit on every part of a grab. Export, transformation, filesystem and cleanup commands are not separately timed. An indefinitely stuck utility or uninterruptible kernel I/O can therefore still prolong a grab/lock. Those are retained/general limits, not newly demonstrated regressions or additional promotion blockers here. Same-group cleanup also assumes descendants remain in that group; no evidence was found that the reviewed normal command sequence deliberately daemonizes or escapes it.

4. **Verdict.** Not ready for STAGING or PROD until R4-1 is fixed and the combined interruption test passes. R3-1 and R3-3 are resolved; the passing normal-session R3-2 tests should remain. No other blocking items were found.

**Validation and scope**

- Local DEV HEAD was `00e94e1`; the requested source and tests had no uncommitted edits. Reviewed the specified fixes diff and the script before `aca5b3d`, plus the unchanged runner and connection regexes. No network fetch was performed.
- The permitted Jest suite passed **50/50**; sh -n passed. Tests used an additional outer deny stub, and command -v lftp was verified against a stub before experiments.
- Experiments were confined to temporary directories, synthetic data, stubs, dash and the installed GNU timeout. No real lftp or remote connection was needed. A subreaper was used to collect orphaned experimental children. Final checks found **zero live recorded experimental processes and zero distinctive deadline-test sleeps**.
- Only the requested review artifact was added. Source, unrelated SQL/WIP, staging and commits were untouched. No prohibited production tree was accessed. No production redaction deployment or scanner behavior was independently revalidated.
