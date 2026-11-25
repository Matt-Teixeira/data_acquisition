// Philips CV: which daily folders still need their Event.zip unzipped (hhm_rpp_philips
// PLAN-PHILIPS-CV-INSIGHTS.md §7.3, I3).
//
// Before: a run unzipped only the folders it had just fetched, plus `last_aquired_dir`. The tunnel-reset
// job (jobs/tunnel_reset/philips/philips_cv.js) fetches folders without unzipping them, so when it
// fetched two or more, all but the newest stayed zipped and never reached the DB.
// Now: at the end of every regular run, every daily folder with an Event.zip and no EventLog.txe is
// unzipped, whoever fetched it.
//
// No age rule: the tunnel-reset job (:10/:40, at most ~7 min) and the regular run (:00/:30, under a
// minute) don't overlap, and unzipping a half-downloaded zip just fails (no central directory yet):
// parse_event_zip.sh then publishes nothing, and the next run tries again.

const fs = require("fs");
const path = require("path");

const DAILY_RE = /^daily_\d{4}_?\d{2}_?\d{2}$/;

/** entries: [{ name, has_zip, has_txe }] -> folder names to unzip, oldest first. */
function folders_to_unzip(entries) {
  return entries
    .filter((e) => DAILY_RE.test(e.name) && e.has_zip && !e.has_txe)
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
    entries.push({
      name,
      has_zip: fs.existsSync(path.join(dir, "Event.zip")),
      has_txe: fs.existsSync(path.join(dir, "EventLog.txe"))
    });
  }
  return entries;
}

module.exports = { folders_to_unzip, scan_system_folder };
