# Runbook: data_acquisition → dev/release paradigm (pilot)

Companion to the approved plan (2026-08-24). Spec: `docs/migration_CLAUDE.md` Parts 1+3.
Reference implementation: `/opt/apps/mmb-rpp`. Full plan:
`~/.claude/plans/i-m-not-too-worried-shimmering-kurzweil.md`.

## Phase map

| Phase | What happens | Where |
| ----- | ------------ | ----- |
| A | Commit docs + CLAUDE.md stub, snapshot crontab, push, FREEZE this tree | live tree `/opt/apps/data_acquisition` |
| B | All code alignment commits (entrypoint repair, USER_ID, LOG_DIR/logger, signal handlers, build.sh, build-release.sh, preflight, CLAUDE.md) | dev clone `~/apps/data_acquisition` |
| C | Dev round-trip: preflight zero-warnings, build, smoke runs, guard negative-test | dev clone |
| D | Cutover: stop schedule → host prep → first release (wipes old tree at `/opt/apps`) → hardened cron | both |
| E | 2-cycle DB verification, kill test, BACKLOG/memory updates | release copy + DB |

After Phase A, nothing edits `/opt/apps/data_acquisition` by hand ever again — it becomes
`build-release.sh` output only. Production cron keeps running the frozen old code until D.

## Where Matt jumps in (everything else is Claude's)

| Step | What you do | Why it's you |
| ---- | ----------- | ------------ |
| A-1 | Approve/adjust the commit + `git push origin STAGING_docker` (or authorize Claude to push) | Your SSH key / your call on pushing the 19 backlog commits |
| A-1 | `sudo crontab -u svc -l > /opt/apps/data_acquisition/cron-bk/svc.crontab.2026-08-24.bak` | sudo has no TTY in Claude's session |
| A-3 | Review the dev clone's `.env` (Claude copies it from the live one; real creds carry over — same model as mmb-rpp) | Secrets custody |
| C-13 | Confirm which hhm/mmb job is safest to smoke-run off-schedule | You know which systems tolerate an extra pull |
| D-15 | `sudo crontab -u svc -e` — comment out the data_acquisition entries (exact lines provided) | sudo + shared-crontab safety |
| D-16 | Run the handed sudo commands: `.env` backup, optional `logs/` tar, `/opt/run-logs` chown/chmod | sudo |
| D-16 | Decide: keep or discard the 268 MB winston `logs/` history | Data-retention call |
| D-17 | Run `bash build-release.sh` from the dev clone; paste output back | sudo inside the script |
| D-18 | `sudo crontab -u svc -e` — paste in the rewritten hardened entries (provided) | sudo |
| E-19 | Stay reachable ~1h while cycles verify | Rollback decisions are yours |

## Definition of done

- Dev run: logs only in-tree (`utils/logger/logs/` + `logs/`), `RELEASE_SHA=dev-tree`,
  `/opt/run-logs/data_acquisition` untouched.
- `build-release.sh`: refuses dirty tree; clean release stamps HEAD's short SHA; release diff
  vs dev tree clean.
- Release run as svc: logs only to `/opt/run-logs/data_acquisition`, real SHA in
  `util.app_run_logs`.
- `preflight-check.sh`: zero warnings in both copies.
- 2 cron cycles: all job families present on the released SHA; ops-dashboard + incident-engine
  unaffected; SIGTERM test flushes both sinks exactly once with honest non-zero exit.
