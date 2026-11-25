// Philips CV fetch scripts (read/sh/Philips/phil_cv_21.sh FTP, phil_cv_22.sh SFTP): a download is staged
// next to the daily folder and only a finished, non-empty one becomes Event.zip (hhm_rpp_philips
// PLAN-PHILIPS-CV-INSIGHTS.md §7.12, review CV1B-COLLECTOR finding 2).
// No network: lftp is a stub on PATH. Synthetic zips, fake credentials, a TEST-NET address.
// Run: npx jest read/__tests__/phil_cv_grab.test.js

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync, execFileSync } = require("child_process");
const { folders_to_unzip, scan_system_folder } = require("../../util/tools/phil_cv_unzip_sweep");

const UNZIP = path.resolve(__dirname, "../sh/Philips/parse_event_zip.sh");
const FAKE = ["192.0.2.10", "fakeuser_cv", "fake-pass-cv"];
const DAILY = "daily_2026_11_25";
const OLD = new Date("2026-11-22T00:00:00Z");

// stub lftp: finds `-O <dir>` in the command string, then acts by $STUB_LFTP
const LFTP = `#!/bin/bash
dir=$(printf '%s' "$2" | sed -n 's/.*-O \\([^;]*\\);.*/\\1/p')
printf '%s\\n' "$2" > "$STUB_LOG"
case "$STUB_LFTP" in
  ok) cp "$STUB_ZIP" "$dir/Event.zip"; exit 0 ;;
  cut) cp "$STUB_ZIP" "$dir/Event.zip"; echo "mget: Event.zip: Fatal error: max-retries exceeded" >&2; exit 1 ;;
  550) echo "mget: Access failed: 550 Event.zip: The system cannot find the file specified." >&2; exit 1 ;;
  empty) : > "$dir/Event.zip"; exit 0 ;;
  none) exit 0 ;;
esac
exit 9
`;

let root, bin, sys;
beforeEach(() => {
  root = fs.mkdtempSync(path.join(os.tmpdir(), "cv-grab-"));
  bin = path.join(root, "bin");
  fs.mkdirSync(bin);
  fs.writeFileSync(path.join(bin, "lftp"), LFTP, { mode: 0o755 });
  sys = path.join(root, "SME00001");
});
afterEach(() => { fs.rmSync(root, { recursive: true, force: true }); });

/** a zip holding EventLog.txe = `text` */
function zip_of(name, text) {
  const src = fs.mkdtempSync(path.join(os.tmpdir(), "cv-zipsrc-"));
  fs.writeFileSync(path.join(src, "EventLog.txe"), Buffer.from(text, "latin1"));
  const out = path.join(root, name);
  execFileSync("zip", ["-q", "-j", out, path.join(src, "EventLog.txe")]);
  fs.rmSync(src, { recursive: true });
  return out;
}
const grab = (script, mode, stub_zip) =>
  spawnSync(path.resolve(__dirname, `../sh/Philips/${script}`), [...FAKE, DAILY, sys], {
    encoding: "utf8",
    env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, STUB_LFTP: mode, STUB_ZIP: stub_zip || "", STUB_LOG: path.join(root, "lftp.log") }
  });
const staging = () => (fs.existsSync(sys) ? fs.readdirSync(sys).filter((n) => n.startsWith(".incoming")) : []);
const daily_dir = () => path.join(sys, DAILY);
/** the daily folder exists from an earlier attempt, with an old mtime */
function earlier_attempt() {
  fs.mkdirSync(daily_dir(), { recursive: true });
  fs.utimesSync(daily_dir(), OLD, OLD);
}

describe.each(["phil_cv_21.sh", "phil_cv_22.sh"])("%s", (script) => {
  test("a finished download becomes Event.zip; nothing staged is left; stderr empty", () => {
    const z = zip_of("full.zip", "full\xe1export\r\n");
    const r = grab(script, "ok", z);
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(fs.readFileSync(path.join(daily_dir(), "Event.zip")).equals(fs.readFileSync(z))).toBe(true);
    expect(staging()).toEqual([]);
    expect(fs.readFileSync(path.join(root, "lftp.log"), "utf8")).toMatch(new RegExp(`mget Event.zip -O ${sys}/\\.incoming\\.${DAILY}\\.\\d+;`));
  });

  test("review F2: a cut transfer whose bytes are a valid zip is never published; the next complete one is, and is unzipped", () => {
    earlier_attempt();
    const prefix = zip_of("prefix.zip", "OLD\xe1revision\r\n"); // a valid zip: what a cut append-style transfer can leave
    const r = grab(script, "cut", prefix);
    expect(r.status).not.toBe(0);
    expect(r.stderr).toMatch(/max-retries exceeded/); // lftp's own message, classified as before
    expect(fs.existsSync(path.join(daily_dir(), "Event.zip"))).toBe(false);
    expect(fs.statSync(daily_dir()).mtimeMs).toBe(OLD.getTime());
    expect(staging()).toEqual([]);
    expect(folders_to_unzip(scan_system_folder(sys))).toEqual([]);
    // a later run: the transfer completes
    const full = zip_of("full.zip", "NEW\xe1complete\r\n");
    expect(grab(script, "ok", full).status).toBe(0);
    expect(folders_to_unzip(scan_system_folder(sys))).toEqual([DAILY]);
    expect(spawnSync(UNZIP, [daily_dir()]).status).toBe(0);
    expect(fs.readFileSync(path.join(daily_dir(), "EventLog.txe"), "latin1")).toBe("NEW\xe1complete\r\n");
  });

  test("550 (the device never wrote the zip): lftp's error and status, nothing published, mtime unchanged", () => {
    earlier_attempt();
    const r = grab(script, "550");
    expect(r.status).toBe(1);
    expect(r.stderr).toMatch(/550 Event\.zip/);
    expect(fs.readdirSync(daily_dir())).toEqual([]);
    expect(fs.statSync(daily_dir()).mtimeMs).toBe(OLD.getTime());
    expect(staging()).toEqual([]);
  });

  test.each(["empty", "none"])("lftp exits 0 with %s Event.zip: exit 1, nothing published", (mode) => {
    earlier_attempt();
    const r = grab(script, mode);
    expect(r.status).toBe(1);
    expect(r.stderr).toMatch(/missing or empty; nothing published/);
    expect(fs.readdirSync(daily_dir())).toEqual([]);
    expect(staging()).toEqual([]);
  });
});
