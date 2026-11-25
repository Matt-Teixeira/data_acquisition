// Philips CV unzip script (read/sh/Philips/parse_event_zip.sh): atomic publish of EventLog.txe
// (hhm_rpp_philips PLAN-PHILIPS-CV-INSIGHTS.md §7.3). Synthetic zips only; no network, no device data.
// Run: npx jest read/__tests__/parse_event_zip.test.js

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync, execFileSync } = require("child_process");

const SCRIPT = path.resolve(__dirname, "../sh/Philips/parse_event_zip.sh");
const REPO = path.resolve(__dirname, "../..");
// Latin-1 bytes as the devices write them: 0xE1 separators, 0xA0, CRLF.
const TXE = Buffer.from("Acquisition\xe12026-11-25\xe107:01:17\xe1Information\xe120481\xe1Memo: a\xa0b\r\n", "latin1");
const SYS = Buffer.from("GSL Service\xe12026-11-25\xe107:00:54\xe1Information\xe10\xe1started.\r\n", "latin1");

let root;
beforeEach(() => { root = fs.mkdtempSync(path.join(os.tmpdir(), "cv-unzip-")); });
afterEach(() => { fs.rmSync(root, { recursive: true, force: true }); });

/** files/SME00001/<daily>/Event.zip holding `entries` ({name: Buffer}). */
function daily(name, entries, { raw } = {}) {
  const dir = path.join(root, "SME00001", name);
  fs.mkdirSync(dir, { recursive: true });
  const src = fs.mkdtempSync(path.join(os.tmpdir(), "cv-zipsrc-"));
  for (const [n, b] of Object.entries(entries)) fs.writeFileSync(path.join(src, n), b);
  if (Object.keys(entries).length) execFileSync("zip", ["-q", "-j", path.join(dir, "Event.zip"), ...Object.keys(entries).map((n) => path.join(src, n))]);
  fs.rmSync(src, { recursive: true });
  if (raw) fs.writeFileSync(path.join(dir, "Event.zip"), raw);
  const t = new Date("2026-11-20T00:00:00Z"); // a fixed, old folder mtime
  fs.utimesSync(dir, t, t);
  return dir;
}
const run = (script, dir, env = {}) => spawnSync(script, [dir], { encoding: "utf8", env: { ...process.env, ...env } });
const leftovers = () => fs.readdirSync(path.join(root, "SME00001")).filter((n) => n.startsWith(".unzip_tmp"));
const mtime = (dir) => fs.statSync(dir).mtimeMs;

test("publishes EventLog.txe and EventLogSystem.txe byte for byte; no temp left", () => {
  const dir = daily("daily_2026_11_25", { "EventLog.txe": TXE, "EventLogSystem.txe": SYS });
  const r = run(SCRIPT, dir);
  expect(r.status).toBe(0);
  expect(fs.readFileSync(path.join(dir, "EventLog.txe")).equals(TXE)).toBe(true);
  expect(fs.readFileSync(path.join(dir, "EventLogSystem.txe")).equals(SYS)).toBe(true);
  expect(r.stdout).toMatch(/published: .*EventLog\.txe/);
  expect(leftovers()).toEqual([]);
});

test("same result as the script before CV-1b (aa68ceb) on the same zip", () => {
  const old = path.join(root, "old_parse_event_zip.sh");
  fs.writeFileSync(old, execFileSync("git", ["-C", REPO, "show", "aa68ceb:read/sh/Philips/parse_event_zip.sh"]), { mode: 0o755 });
  const a = daily("daily_2026_11_24", { "EventLog.txe": TXE, "EventLogSystem.txe": SYS });
  const b = daily("daily_2026_11_25", { "EventLog.txe": TXE, "EventLogSystem.txe": SYS });
  expect(run(old, a).status).toBe(0);
  expect(run(SCRIPT, b).status).toBe(0);
  for (const f of ["Event.zip", "EventLog.txe", "EventLogSystem.txe"]) {
    expect(fs.readFileSync(path.join(b, f)).equals(fs.readFileSync(path.join(a, f)))).toBe(true);
  }
  expect(fs.readdirSync(b).sort()).toEqual(fs.readdirSync(a).sort());
});

test("re-unzipping replaces EventLog.txe by rename (a new inode, never a half-written file)", () => {
  const dir = daily("daily_2026_11_25", { "EventLog.txe": TXE });
  expect(run(SCRIPT, dir).status).toBe(0);
  const ino = fs.statSync(path.join(dir, "EventLog.txe")).ino;
  expect(run(SCRIPT, dir).status).toBe(0);
  expect(fs.statSync(path.join(dir, "EventLog.txe")).ino).not.toBe(ino);
});

test.each([
  ["a truncated zip", () => daily("daily_2026_11_25", {}, { raw: Buffer.from("PK\x03\x04 truncated download", "latin1") })],
  ["a zip without EventLog.txe", () => daily("daily_2026_11_25", { "EventLogSystem.txe": SYS })]
])("%s: non-zero exit, nothing published, the daily folder's mtime unchanged, no temp left", (_name, make) => {
  const dir = make();
  const before = mtime(dir);
  const r = run(SCRIPT, dir);
  expect(r.status).not.toBe(0);
  expect(fs.existsSync(path.join(dir, "EventLog.txe"))).toBe(false);
  expect(mtime(dir)).toBe(before);
  expect(leftovers()).toEqual([]);
});

test("unzip dying mid-write (stub on PATH): nothing published, mtime unchanged, no temp left", () => {
  const dir = daily("daily_2026_11_25", { "EventLog.txe": TXE });
  const bin = fs.mkdtempSync(path.join(os.tmpdir(), "cv-stub-"));
  // writes half a file into the -d target, then fails like a disk-full or killed unzip
  fs.writeFileSync(path.join(bin, "unzip"), '#!/bin/bash\nfor ((i=1;i<=$#;i++)); do [ "${!i}" = "-d" ] && j=$((i+1)) && out="${!j}"; done\nprintf "Acq\\xe1half" > "$out/EventLog.txe"\nexit 50\n', { mode: 0o755 });
  const before = mtime(dir);
  const r = run(SCRIPT, dir, { PATH: `${bin}:${process.env.PATH}` });
  fs.rmSync(bin, { recursive: true });
  expect(r.status).toBe(50);
  expect(fs.existsSync(path.join(dir, "EventLog.txe"))).toBe(false);
  expect(mtime(dir)).toBe(before);
  expect(leftovers()).toEqual([]);
});

test("refuses a folder without Event.zip, a missing folder, and an empty argument", () => {
  const dir = path.join(root, "SME00001", "daily_2026_11_25");
  fs.mkdirSync(dir, { recursive: true });
  expect(run(SCRIPT, dir).status).toBe(2);
  expect(run(SCRIPT, path.join(root, "nope")).status).toBe(2);
  expect(spawnSync(SCRIPT, [""], { encoding: "utf8" }).status).toBe(2);
});
