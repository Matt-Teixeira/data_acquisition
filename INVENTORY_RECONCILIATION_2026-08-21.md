# Inventory Reconciliation Worksheet (BACKLOG 4a)

**Built 2026-08-21** from 44 h of `stats.acquisition_history` (post-migration steady
state), joined with `alert.offline_*` current state and `public.systems`. A system
appears here if it was attempted ≥20 times and **never succeeded once** — the
stable-failing set inherited with prod's inventory. Everything else in the fleet is
acquiring (mmb: 134 systems OK, hhm: 73 OK).

Scale check: doc 2.1 §5.5 recorded prod carrying 14 systems dark since Jul 7 — this
set (27) is that population plus the re-keyed/credential cases the stricter staging
posture now surfaces honestly.

Snapshot before any data change: `crontab`-style pattern —
`docker exec pg_db psql -U postgres -d staging -c "..." > /opt/resources/backups/systems-flags-snapshot-$(date +%Y%m%d).txt`

## Clusters (27 systems; decision per cluster, exceptions per system)

### A. mmb — `credentials` / publickey refused (5) — GE MRI
`SME15605 SME16377 SME16380 SME16381 SME20004`
Our `id_dev` key is not authorized on these collectors. Prod pushes the same key
lineage, so either prod fails these too, or prod uses a key we didn't inherit.
**Recommended:** ask prod-side (one `grep`/log check) whether these acquire there;
if not → retire candidates; if yes → identify prod's key and add it to the bundle.
- [ ] Decision: ______

### B. mmb — `host_key_changed` (4) — the former 1a "unknown" mmb systems
`SME01097 SME12631 SME13615 SME18352`
Post-import twist: prod's file DID hold entries for these endpoints (e.g. SME01097 →
`172.31.2.36`), but with **older keys than the hosts now present** — they were
re-keyed at some point, and prod's accept-new client hard-fails changed keys, so
prod is failing them today too. **Recommended:** if the sites are known to have had
maintenance/re-imaging, verify current keys out-of-band, then `ssh-keygen -R <host>`
the stale line + append the verified new one (manual, deliberate — exactly the
"pruning stale keys stays manual" case from the migrate script's design).
- [ ] Decision: ______

### C. mmb — `host_key_unknown` residual (~3 endpoints, systems incl. SME21284/21824/20556/21580/22407/22721/22722)
Collector endpoints never keyed anywhere (`10.154.16.180`, `170.232.120.204/.205`,
`172.31.3.71/.79/.85/.96` — some shared by several SMEs; note SME21284 acquires
fine via hhm at a neighboring IP, so the *system* is alive, the *mmb collector*
address is the question). **Recommended:** per-endpoint — reachable & legitimate →
verify key + append; unreachable → wrong-IP or retired collector → fix config or
flag out of mmb polling.
- [ ] Decision: ______

### D. hhm — `max_retries` (8)
`SME01434 SME02583 SME18536 SME19034 SME20487 SME20594 SME21853 SME21928`
Tunnel path exhausts retries — classic dark/offline sites. **Recommended:** retire
or accept-as-dark per system; these are the core §5.5 population.
- [ ] Decision: ______

### E. hhm — `connection_timeout` (6) — Philips CT cluster
`SME18530 SME18976 SME18980 SME20602 SME20605 SME20611`
Hosts time out at TCP — dark. Striking that it's one modality family; possibly one
site/network segment. **Recommended:** same as D, but check if they share a site —
one network fix might revive all six.
- [ ] Decision: ______

### F. hhm — `host_key_new` (2) — GE MRI
`SME21917 SME21923`
The hhm pipeline's lax-checking scp auto-accepted a NEW key and still exited
nonzero — re-keyed hosts with a further failure behind them. **Recommended:**
treat with cluster B (re-keyed population); verify fingerprints if kept.
- [ ] Decision: ______

### G. Singles
`SME21922` (connection_refused — port closed; service down on host) ·
`SME19647` (session_timeout — answers then goes silent; flaky host or mid-transfer
drop). **Recommended:** individual look or accept-as-dark.
- [ ] Decision: ______

## The B0a policy decision (doc 2.1 §5.5 — still open)

How do inventory changes flow prod → staging from now on?
1. **Manual on change, named owner** — cheapest; relies on discipline.
2. **Scheduled snapshot + diff alert** — small read-only cron comparing
   staging's `public.systems`/flags against a prod snapshot shipped by the same
   push pattern as `known_hosts_migrate.sh` / `redis_migrate.sh`; alerts on delta.
   Implementation ~an afternoon, fits the existing script family.
- [ ] Decision: ______

## Bookkeeping
- 1a folds in here: its 7-IP question is clusters B+C. Close 1a when B/C are decided.
- Flag-out mechanism: to be confirmed in code before any change (which knob stops
  polling per pipeline — `config.acquisition` rows vs `process_*` flags vs Redis
  schedule state). No data changes until decisions above are made and a snapshot
  is taken.
