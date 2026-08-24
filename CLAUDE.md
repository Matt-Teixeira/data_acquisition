# CLAUDE.md — data_acquisition

> **⚠️ MID-MIGRATION (started 2026-08-24).** This app is being aligned to the fleet
> Docker/release paradigm. For conventions, `docs/migration_CLAUDE.md` (Parts 1 and 3) is
> authoritative; this file is being built out as each migration step lands and is NOT yet a
> complete description of the app. Steps and sequencing:
> `docs/MIGRATION-RUNBOOK-data_acquisition.md`. Older setup docs (`setup.md`,
> `docs/docker_server_full_setup_2.1.md`) remain authoritative for *server-wide* provisioning
> but are superseded by the paradigm docs for *app-level* Docker/release conventions.

**data_acquisition** is a Node.js run-once pipeline fleet: HHM equipment data pulls (GE /
Philips / Siemens over lftp/rsync/ssh), MMB log acquisition (run groups 0–7), Philips MRI
rsync, althea env pulls, VPN/tunnel resets, offline-alert heartbeats — dispatched by
`index.js <run_group> [schedule] [manufacturer] [modality]` and scheduled from the shared
`svc` crontab.

Sections on architecture, jobs, environment, and operations will be corrected here as the
migration lands them. Until then, verify against the code and the paradigm docs rather than
this file.
