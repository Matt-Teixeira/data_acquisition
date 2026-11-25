// Philips CV: which daily folders still need their Event.zip unzipped (hhm_rpp_philips
// PLAN-PHILIPS-CV-INSIGHTS.md §7.3, §7.13, I3).
//
// Before: a run unzipped only the folders it had just fetched, plus `last_aquired_dir`. The tunnel-reset
// job (jobs/tunnel_reset/philips/philips_cv.js) fetches folders without unzipping them, so when it
// fetched two or more, all but the newest stayed zipped and never reached the DB.
// Now: at the end of every regular run, every daily folder with an Event.zip and no EventLog.txe is
// unzipped, whoever fetched it, if the daily folder itself changed in the last WINDOW_DAYS.
//
// The window (§7.13): without it the first run would unzip 2,557 old zips (13.4 GB, mostly 2024-2025,
// which no parser or backfill reads) and retry 21 unreadable ones every run forever. It is measured on
// the daily folder's mtime, the local fetch time, NOT on the date in its name: a system back after weeks
// offline has old-named folders fetched today, and those must still be unzipped. Older pending folders
// are unzipped explicitly by the backfill step (§7.11) with read/sh/Philips/parse_event_zip.sh.
//
// No "download finished" rule: downloads are staged and moved in only when complete (phil_cv_21.sh /
// phil_cv_22.sh, §7.12), and unzipping a damaged zip publishes nothing.

const fs = require("fs");
const path = require("path");

const DAILY_RE = /^daily_\d{4}_?\d{2}_?\d{2}$/;
const WINDOW_DAYS = 30;
const DAY_MS = 24 * 3600 * 1000;

/** entries: [{ name, has_zip, has_txe, dir_mtime_ms }] -> folder names to unzip, oldest first. */
function folders_to_unzip(entries, now_ms = Date.now()) {
  return entries
    .filter((e) => DAILY_RE.test(e.name) && e.has_zip && !e.has_txe && now_ms - e.dir_mtime_ms <= WINDOW_DAYS * DAY_MS)
    .map((e) => e.name)
    .sort((a, b) => a.replace(/_/g, "").localeCompare(b.replace(/_/g, "")));
}

/** Read a system folder (files/<SME>) into entries for folders_to_unzip. Missing folder -> []. */
function scan_system_folder(system_dir) {
  let names;
  try {
    names = fs.readdirSync(system_dir);
  } catch (e) {
    return [];
  }
  const entries = [];
  for (const name of names) {
    if (!DAILY_RE.test(name)) continue;
    const dir = path.join(system_dir, name);
    let dir_mtime_ms;
    try {
      dir_mtime_ms = fs.statSync(dir).mtimeMs;
    } catch (e) {
      continue;
    }
    entries.push({
      name,
      has_zip: fs.existsSync(path.join(dir, "Event.zip")),
      has_txe: fs.existsSync(path.join(dir, "EventLog.txe")),
      dir_mtime_ms
    });
  }
  return entries;
}

module.exports = { folders_to_unzip, scan_system_folder, WINDOW_DAYS };
