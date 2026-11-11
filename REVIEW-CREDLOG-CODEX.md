# Codex review: credential redaction (REVIEW-CREDLOG-HANDOFF.md)

Date: 2026-11-11. Pasted from the Codex session; saved verbatim. Fixes are listed in
`REVIEW-CREDLOG-HANDOFF.md`, "Fixes after the Codex review".

## Findings

- [P2] Historical cleanup leaves credentials in stats.job_runs — [redact_app_run_logs.sql (line 192)](/home/matt-teixeira/hep3/hhm_data_acquisition/maintenance/credlog/redact_app_run_logs.sql:192) only counts rows whose error_message contains Command failed:; it doesn't redact them. The handoff identifies this column as a credential sink, and the runtime fix only protects new rows. Add cleanup and residual verification for existing error_message values, or explicitly exclude this table from the cleanup scope.
- [P2] console.trace bypasses the console guard — [redact.js (line 70)](/home/matt-teixeira/hep3/hhm_data_acquisition/util/redact.js:70) wraps log, info, warn, error, and debug, but not trace. The handoff says console.trace goes through wrapped error; Node's console trace method does not provide that guarantee. I found no current console.trace calls, so this is a coverage gap rather than a present call-site leak. Wrap it or correct the handoff claim.

I reviewed the runtime redaction, logger changes, and cleanup scripts. I did not run tests. The handoff's .m filename appears to be a typo; I reviewed REVIEW-CREDLOG-HANDOFF.md.
