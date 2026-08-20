# Audit prompt — independent verification of docker_server_full_setup_2.1.md

Copy everything below the line into a fresh Claude Code session started in
`/opt/apps/data_acquisition`.

---

You are performing an **independent, read-only audit**. You were not involved in
writing the document you are auditing; treat every claim in it as unverified until
you have checked it yourself.

## The subject

`docs/docker_server_full_setup_2.1.md` (in this repo) claims to be a complete,
proven recipe for building an acquisition server of any of three types — dev,
staging, or prod — from a blank VM. The **staging server you are running on
(acq-vm-0) is the reference implementation**: the doc says it was verified against
this live server on 2026-08-18. Your job is to find every place where that claim
fails.

## The one question that matters

**If a competent operator sat down at a blank VM with only this document, would they
end up with a working server — and would it match this one?**

Audit against that question, not against style. Specifically hunt for these failure
classes, in priority order:

1. **Off-repo host dependencies the doc doesn't create.** This is the owner's
   biggest stated concern. The running server accumulated state over months: files,
   directories, permissions, ACLs, sysctl entries, systemd units, docker volumes/
   networks created by hand, secret files, SSH material, cron entries (both the
   user crontab and the `svc` crontab), node_modules caches, data directories.
   For each piece of host state a running app actually depends on, verify the doc
   contains a step that creates it, with the right ownership and mode. Enumerate
   from the *live server* toward the doc (what exists and is depended on?), not
   only from the doc toward the server — the doc cannot be trusted to index its
   own omissions.
2. **Ordering and precondition gaps.** Walk the doc top-to-bottom as a dry-run
   build: for every command, check its preconditions were satisfied by an earlier
   step (directories exist, secrets exist, networks/volumes exist, images built,
   `.env` keys defined, DB roles created in the right order). Flag anything that
   works on this server only because the state already exists.
3. **Staging-specific values leaking through the server-agnostic language.** The
   doc uses `<DB_NAME>` and an identity table (dev/staging/prod). Check the
   substitution is complete and coherent: commands that still hardcode `staging`,
   tracked files the doc references that hardcode a db name / uid / tag, branch
   instructions that break on a dev build (`DEV_docker`/`DEV`), and any step whose
   dev-server variant is ambiguous or untested.
4. **Doc vs live server disagreements.** Container config (`docker inspect`,
   `docker compose config`), ports, healthchecks, mounts, log caps, Redis auth
   state, pg_hba, branch checkouts, upstreams, crontab lines vs
   `docs/schedules.md`, file permissions the doc specifies.
5. **Doc vs repo disagreements.** Every file, path, script, compose service,
   branch, and image tag the doc names must exist as described in the repos.
6. **Silent-failure traps for the new-server case**: steps that would fail
   *quietly* on a fresh build (auto-created bind-mount paths, missing-but-defaulted
   env vars, `CREATE TABLE IF NOT EXISTS`-style non-upgrades, restore procedures
   that can produce empty state).

## Scope

Repos/apps owned by the operator (all under `/opt/apps/`): `data_acquisition`,
`hhm_rpp_ge`, `hhm_rpp_philips`, `hhm_rpp_siemens`, `acumatica_sync`, `monday`,
`reports`, `part-source-pipeline`, `incident-engine`, `ops-dashboard`,
`redis-admin`, `pg_manage_v2`, `imprivata-poc`, `acquisition-v2` (paused — verify
the doc describes its state correctly, nothing more). Plus the host state under
`/opt/resources/`, `/opt/run-logs/`, `/etc/sysctl.d/`, `/etc/systemd/system/`,
the user crontab, and the docker daemon state.

**Out of scope / hard boundaries:**
- **`odd-jobs` is another person's app — never modify, never run it.** Read-only
  observation is allowed and relevant (the doc names it as the owner of monthly
  partition maintenance); verify the doc's claims about it only through read-only
  means (its schedule lives in the `svc` crontab, which needs root — see
  "when you cannot verify" below).
- This is an **audit, not a fix pass**: change no code, no configs, no containers,
  no cron, no database state. Do not run application jobs (`npm run ...`,
  `docker compose run ...` of app services) — scheduled jobs fire every 15–30
  minutes and your run could collide or double-process. Safe verification tools:
  `git` read commands, `ls`/`stat`/`getfacl`, `grep`, `docker inspect`,
  `docker ps`, `docker compose config`, read-only `psql` SELECTs, `redis-cli`
  read commands (three instances require auth — the doc explains access),
  `crontab -l`, reading any file you have permission to read.
- **Push nothing, commit nothing** except your single findings file (below).

## Known accepted decisions — verify, but classify separately

These are deliberate owner decisions, not fresh findings. Confirm the doc records
them accurately; report drift from them, but do not re-litigate them:
- All four Redis instances, **including `redis-STAGING`, require auth** (standardized
  2026-08-19; reverses the earlier passwordless exception for odd-jobs — Jonathan is
  adding client-side auth to his apps).
- The SFTP credential in part-source-pipeline's git history stays (vendor cannot
  rotate; owner accepted the risk 2026-08-18).
- Backups are local-only for now (off-host target decision is parked).
- `incident-engine`/`ops-dashboard`/`reports` carry hardcoded `105:987`/uid
  literals — known tracked debt, listed in the doc's follow-ups.
- The two large reference dumps in `/opt/resources/backups/` sit outside retention
  on purpose.
- `acquisition-v2` is paused with a deliberately stale DB password and a
  commented-out cron line.

## When you cannot verify

You have no sudo. Some claims (the `svc` crontab, root-only secret file modes and
contents, `/opt/resources/ssl/private/` internals) are unverifiable directly.
**Never mark such a claim as passed or failed — list it in a dedicated
"needs-privileged-verification" section** with the exact command the owner should
run and the expected output. The same applies to claims about GitHub-side state
you cannot reach and to anything that would require running a job to prove.

## Independence protocol

Form your own findings **before** reading any prior audit material. The repo root
contains earlier audit and plan documents (`AUDIT_RECONCILIATION_*`,
`PLAN_OF_ATTACK_2026-08.md`, `TRIAGE_*`) — do not open them until your findings
list is drafted. Then reconcile: anything they flagged that you missed goes into
your findings with a note that you missed it on the first pass (that is signal
about the doc, not about you); anything you flagged that they marked
resolved/accepted gets cross-referenced rather than duplicated.

## Deliverable

One file: `AUDIT_DOC21_<today's date>.md` at this repo's root. Structure:

1. **Verdict paragraph** — would the blank-VM build succeed? Where would it first
   break?
2. **Findings**, ID'd `A21-01…`, ordered by severity, each with: severity
   (blocker-on-new-build / drift / gap / nit), the doc section it contradicts or
   that omits it, the exact evidence (command + output excerpt), and what the doc
   would need to say — **described, not applied**.
3. **Needs-privileged-verification** list (claim, command for the owner, expected
   result).
4. **Verified-true sample** — a short list of load-bearing claims you checked that
   held, so the owner knows what was covered, not just what failed.
5. **Coverage statement** — what you did not check and why.

Do not sugarcoat and do not pad. A short list of real findings beats a long list of
theater. If a claim is fine, it appears (at most) in the verified-true sample. No
code changes anywhere — findings only.
