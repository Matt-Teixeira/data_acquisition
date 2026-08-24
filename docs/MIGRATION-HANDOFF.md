# Migration handoff prompt

Paste the block below into a Claude Code session opened in the app you are migrating.
Attach `CLAUDE.md` from an already-migrated app (or point at its `docker` branch).

Nothing in the block is app-specific — it works for any app in the fleet.

---

I want to align this app to our standardized Docker/release paradigm. The attached
CLAUDE.md is from an app that has already been migrated — treat it as the reference
implementation, not as something to copy wholesale.

**How to read the attached file**

- **Part 1 — Shared app architecture** is the set of conventions. These should end up
  essentially identical in every app.
- **Part 3 → "Aligning an existing app to this paradigm"** is the actual checklist.
  Start there. Every item is a real misalignment hit during a previous migration,
  paired with the failure it causes.
- **Parts 2 and 4 describe that other app specifically** — its domain logic, its
  schedule, its open to-do list. Worked examples only. Do not copy them here.

**Which document wins**

This app has its own `CLAUDE.md`, and it is auto-loaded as project instructions — so it
arrives labelled as something you must follow, while the attached reference arrives as a
mere attachment. That is backwards, and it is the single easiest way to get this migration
wrong. For conventions, **the attached CLAUDE.md is authoritative and this app's own
CLAUDE.md is the thing being fixed.**

Read the local file as *evidence of the current state*, not as the target. It is useful
that way — it tells you what this app believes about itself — but expect it to document
defects as standards. Real examples from the previous migration: it documented a `utils/`
`npm install` as required when the directory has no `package.json` and the install is a
no-op; it documented the production log mount as unconditional, which is precisely the bug
that put dev runs into the production log record; and it described the pattern as "4 files"
when it is five. An agent following it faithfully would have preserved all three.

So: when the local file and the reference disagree, the local file is wrong until proven
otherwise — but say so explicitly in the audit rather than silently following either one.
If the local file has its own migration checklist, treat it as superseded by Part 3 and
delete it rather than maintaining two.

**What I want first**

Audit this app against the Part 3 checklist and **report the gaps before changing
anything**. For each: what is here now, what it should be, and whether it is actually
broken or merely non-conforming. I want to see the whole list and pick the order —
the sequencing matters more than the individual fixes.

Part 3's **"Known dependencies"** block already fixes a handful of orderings that are
app-independent (and that cost a debugging session when done backwards). Treat those
as given, propose an order for everything else, and say which items you found are
inert until an earlier one lands — that last part is what I actually want from the
audit.

**Do not assume this app resembles the reference app**

It may not use Redis, may not have run groups, may not read from a shared data mount,
and may already be deployed and running on a schedule. Verify what is actually here.
Where the checklist says "if the app does X", check whether it does.

**Host facts (shared box, not visible in this repo)**

- Release copies live at `/opt/apps/<app>`, owned `svc:docker`
- Production logs at `/opt/run-logs/<app>`, `svc:docker` mode `2775`
- `svc` is the service account: a system account with **no host home**
  (`/nonexistent`), in the `docker` group. Read Part 1's *"The svc account, and the
  HOME trap"* before setting `HOME` anywhere
- Secrets are root-only under `/opt/resources/secrets/`, synced into each app's
  `.env` by a host rotation script. An app must be registered to be included
- **All apps share one crontab under `svc`.** Edit with `sudo crontab -u svc -e` —
  never `crontab -u svc <file>`, which replaces it and wipes other apps' entries.
  Other apps already have entries there; give this app its own ALL-CAPS section
- Anyone in the `docker` group is effectively root on this box

**Working constraints**

- `sudo` has no TTY in your session and will fail. Hand me the exact command and I
  will run it
- Do not push or merge without asking
- Verify against the database and filesystem, not just what a run log claims. The log
  states intent; the tables are the fact
- If you rewrite a file wholesale instead of editing it, say so — my editor will be
  holding a stale buffer
- Prefer small commits with real reasoning in the message over one large one

**Definition of done**

The dev/release round trip in Part 3 → *"Verify"* passes:

- a dev run writes only to `./utils/logger/logs`, reports `RELEASE_SHA=dev-tree`, and
  leaves `/opt/run-logs/<app>` untouched
- a release run as `svc` writes only to `/opt/run-logs/<app>` and reports the real
  commit SHA
- `preflight-check.sh` reports **zero** warnings
- the app's own `CLAUDE.md` is updated to match what was actually built — corrected
  **as each step lands**, not all at the end. Put a short "mid-migration, see <reference>
  for conventions" note at the top of it as your first edit, so every later step is judged
  against something honest. Leaving it until last means the whole migration runs against a
  document describing the app as it was before you started.

Start with the audit.

---

## Notes for whoever hands this over

- **Report-before-change is deliberate.** The checklist is long enough that working
  top-down produces a pile of edits before the shape of the problem is visible. In
  practice the ordering mattered more than any single fix — some changes are inert
  until an earlier one lands.
- **The main risk is cargo-culting the reference app.** An app with no cursor to
  advance does not need `flock`; an app with one job does not need eight cron
  entries. The checklist is phrased conditionally, but an eager agent will still
  reach for the reference shape.
- **Part 1 is copied, not shared.** Every app carries its own CLAUDE.md, so the
  conventions exist in as many copies as there are apps and will drift. When you
  change a convention, note that the other apps need syncing.
