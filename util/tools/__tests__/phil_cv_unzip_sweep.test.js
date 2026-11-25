// Philips CV unzip sweep (util/tools/phil_cv_unzip_sweep.js) and its call in run_phil_cv
// (hhm_rpp_philips PLAN-PHILIPS-CV-INSIGHTS.md §7.3). Temp folders only; no network, no Redis, no Postgres.
// Run: npx jest util/tools/__tests__/phil_cv_unzip_sweep.test.js

const fs = require("fs");
const os = require("os");
const path = require("path");
const { folders_to_unzip, scan_system_folder, WINDOW_DAYS } = require("../phil_cv_unzip_sweep");
const NOW = Date.parse("2026-11-25T16:00:00Z");
const DAY = 24 * 3600 * 1000;

// --- mocks for the run_phil_cv test (hoisted by jest) ---
const mockUnzip = jest.fn(async () => "ok");
const mockGrab = jest.fn(async () => true);
jest.mock("../../../read/exec-phil_cv_unzip", () => (...a) => mockUnzip(...a));
jest.mock("../../../read/exec-phil_cv_data_grab", () => (...a) => mockGrab(...a));
jest.mock("../../../sql/qf-provider", () => ({ get_hhm: async () => [], getHhmCreds: async () => [] }));
jest.mock("../../../redis/redis_helpers", () => ({ get_previous_dir: async (_j, _r, _s, type) => (type === "last_phil_cv_daily" ? "daily_2026_11_13" : null) }));
jest.mock("../../../util", () => ({
  decryptString: (s) => s,
  list_new_phil_cv_files: async () => ({ daily_files_to_pull: null, lod_files_to_pull: null }), // device unreachable
  file_exists: async (dir, rel) => require("fs").existsSync(require("path").join(dir, rel))
}));
jest.mock("../../../utils/logger/log", () => [async () => {}]);
jest.mock("../../../utils/logger/enums", () => ({ type: { I: "I", W: "W", E: "E" }, tag: { cal: "cal", det: "det", cat: "cat", seq: "seq", qaf: "qaf" } }));

let root;
beforeEach(() => { root = fs.mkdtempSync(path.join(os.tmpdir(), "cv-sweep-")); mockUnzip.mockClear(); mockGrab.mockClear(); });
afterEach(() => { fs.rmSync(root, { recursive: true, force: true }); });
function tree(spec, ages_days = {}) {
  for (const [name, files] of Object.entries(spec)) {
    const p = path.join(root, name);
    if (files === null) { fs.writeFileSync(p, "x"); continue; } // a plain file
    fs.mkdirSync(p, { recursive: true });
    for (const f of files) fs.writeFileSync(path.join(p, f), "x");
    if (ages_days[name] !== undefined) { const t = new Date(Date.now() - ages_days[name] * DAY); fs.utimesSync(p, t, t); }
  }
}

test("folders_to_unzip: Event.zip and no EventLog.txe, daily folders only, oldest first, both name formats", () => {
  const e = (name, has_zip, has_txe) => ({ name, has_zip, has_txe, dir_mtime_ms: NOW });
  expect(folders_to_unzip([
    e("daily_2026_11_12", true, false), e("daily_20261111", true, false), e("daily_2026_11_10", true, true),
    e("daily_2026_11_13", false, false), e("lod_20261111_0900", true, false), e(".unzip_tmp.daily_2026_11_14.1", true, false)
  ], NOW)).toEqual(["daily_20261111", "daily_2026_11_12"]);
});

test("window (§7.13): the daily folder's mtime within WINDOW_DAYS, not the date in its name", () => {
  expect(WINDOW_DAYS).toBe(30);
  const e = (name, age_days) => ({ name, has_zip: true, has_txe: false, dir_mtime_ms: NOW - age_days * DAY });
  expect(folders_to_unzip([
    e("daily_2025_03_10", 400),  // a 2025 folder fetched in 2025: never again
    e("daily_2026_09_22", 31),   // fetched 31 days ago: left for the backfill step
    e("daily_2026_10_26", 30),   // exactly 30 days: still in
    e("daily_2026_08_01", 0.1)   // an old name fetched today (a system back after weeks offline): in
  ], NOW)).toEqual(["daily_2026_08_01", "daily_2026_10_26"]);
});

test("scan_system_folder reads the folder tree; a missing folder gives []", () => {
  tree({ daily_2026_11_10: ["Event.zip", "EventLog.txe"], daily_2026_11_11: ["Event.zip"], daily_2026_11_13: [], daily_2025_02_03: ["Event.zip"], "lod_EventLog.txe": null }, { daily_2025_02_03: 400 });
  expect(folders_to_unzip(scan_system_folder(root))).toEqual(["daily_2026_11_11"]);
  expect(scan_system_folder(path.join(root, "missing"))).toEqual([]);
});

test("run_phil_cv sweeps every pending folder, even when the device can't be reached (a tunnel-reset fetch)", async () => {
  process.env.RUN_ENV = "test"; // not "dev": keep the temp debian_server_path
  // 11_11 and 11_12 were fetched by the tunnel-reset job and never unzipped; 11_10 is done; 11_13 has no zip
  // daily_2025_01_20 is an old pending zip (fetched long ago): outside the window, never touched
  tree({ daily_2025_01_20: ["Event.zip"], daily_2026_11_10: ["Event.zip", "EventLog.txe"], daily_2026_11_11: ["Event.zip"], daily_2026_11_12: ["Event.zip"], daily_2026_11_13: [] }, { daily_2025_01_20: 300 });
  const { run_phil_cv } = require("../../../jobs/hhm/philips/philips_cv");
  const system = { id: "SME00001", acquisition_script: "phil_cv_21.sh", host_ip: "192.0.2.10", credentials_group: 1, debian_server_path: root };
  const creds = [{ id: 1, user_enc: "fakeuser", password_enc: "fake-pass" }];
  await run_phil_cv("job", [], system, creds, "2026-11-25T12:00:00Z");
  expect(mockUnzip.mock.calls.map((c) => c[5])).toEqual(["daily_2026_11_11", "daily_2026_11_12"]);
  // the existing re-fetch of a zip missing from last_aquired_dir is unchanged
  expect(mockGrab.mock.calls.map((c) => c[5][3])).toEqual(["daily_2026_11_13"]);
});
