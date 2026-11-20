// Philips CT grab script (read/sh/Philips/phil_ct_data_grab_1.sh): control flow and outputs.
//
// No network and no real scanner data: lftp, mdb-tables and mdb-export are replaced by stubs on
// PATH that produce small synthetic tables. Byte-equivalence of the legacy .output files and the
// exactness of the .csv exports were checked separately on real Logger.mdb copies (handoff).
// Run: npx jest read/__tests__/phil_ct_data_grab_1.test.js

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync, spawn } = require("child_process");
const { extractConnectionError, connection_regexes } = require("../../util/tools/connection_regex");

const SCRIPT = path.resolve(__dirname, "../sh/Philips/phil_ct_data_grab_1.sh");
const FAKE = ["192.0.2.10", "fakeuser_ct", "fake-pass-ct"]; // TEST-NET address, fake credentials

// --- stubs ----------------------------------------------------------------------------
// Synthetic Events table: a Msg with a comma and a Msg with a line break (the two shapes the
// legacy export loses) plus an ordinary row. mdb-export -e escapes the line break as \n.
const EVENTS_RAW =
  "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime\n" +
  '"EVENT_MINOR",4,"GSE",1,"2026/11/01 10:00:00.001","STUDY_STARTED was sent",,,"11/01/26 10:00:00"\n' +
  '"EVENT_MINOR",4,"GSE",2,"2026/11/01 10:00:01.002","Series 3 cancelled, due to X, in state Y",,,"11/01/26 10:00:01"\n' +
  '"EVENT_MINOR",4,"GSE",3,"2026/11/01 10:00:02.003__01","line one\nline two",,,"11/01/26 10:00:02"\n';
const EVENTS_CSV =
  "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime\n" +
  '"EVENT_MINOR",4,"GSE",1,"2026/11/01 10:00:00.001","STUDY_STARTED was sent",,,"2026-11-01 10:00:00"\n' +
  '"EVENT_MINOR",4,"GSE",2,"2026/11/01 10:00:01.002","Series 3 cancelled, due to X, in state Y",,,"2026-11-01 10:00:01"\n' +
  '"EVENT_MINOR",4,"GSE",3,"2026/11/01 10:00:02.003__01","line one\\nline two",,,"2026-11-01 10:00:02"\n';
const EAL_RAW =
  "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime\n" +
  '"2026/11/01 10:00:00.001",1,"EAL",0,0,"FATAL",,0,,0,0,0,"Gen Shot120x200LO*","11/01/26 10:00:00"\n';
const EAL_CSV = EAL_RAW.replace('"11/01/26 10:00:00"', '"2026-11-01 10:00:00"');

const sh = (s) => s.replace(/^\n/, "");
const STUB_LFTP = sh(`
#!/bin/sh
echo "$2" > "$STUB_DIR/lftp.args"
case "\${STUB_MODE:-ok}" in
  timeout)
    echo "cd: Fatal error: max-retries exceeded (connect to host 192.0.2.10 port 22: Connection timed out)" >&2
    exit 1 ;;
esac
dest=$(printf '%s' "$2" | sed -n 's/.*mget Logger\\.mdb -O \\([^;]*\\);.*/\\1/p' | tr -d ' ')
lst=$(printf '%s' "$2" | sed -n 's/.*cls -l > \\([^;]*\\);.*/\\1/p' | tr -d ' ')
[ -n "$lst" ] && echo "-rw-r--r-- 1 svc none 1234 Nov  2 15:26 Logger.mdb" > "$lst"
if [ "\${STUB_MODE:-ok}" = empty ]; then : > "$dest/Logger.mdb"; else echo "synthetic mdb" > "$dest/Logger.mdb"; fi
exit 0
`);
const STUB_MDB_TABLES = sh(`
#!/bin/sh
echo "EALInfo Events "
`);
// $1 = -e when called for the complete export; the last two args are <file> <table>
const STUB_MDB_EXPORT = sh(`
#!/bin/sh
eval "table=\\\${$#}"
mode=legacy; [ "$1" = "-e" ] && mode=csv
case "\${STUB_EXPORT_FAIL:-}" in "$mode") echo "mdb-export: synthetic failure" >&2; exit 2 ;; esac
cat "$STUB_DIR/$table.$mode"
`);

let tmp, stubDir;
const writeExec = (p, body) => { fs.writeFileSync(p, body); fs.chmodSync(p, 0o755); };

beforeAll(() => {
  tmp = fs.mkdtempSync(path.join(os.tmpdir(), "philct-"));
  stubDir = path.join(tmp, "stub");
  fs.mkdirSync(stubDir);
  writeExec(path.join(stubDir, "lftp"), STUB_LFTP);
  writeExec(path.join(stubDir, "mdb-tables"), STUB_MDB_TABLES);
  writeExec(path.join(stubDir, "mdb-export"), STUB_MDB_EXPORT);
  fs.writeFileSync(path.join(stubDir, "Events.legacy"), EVENTS_RAW);
  fs.writeFileSync(path.join(stubDir, "EALInfo.legacy"), EAL_RAW);
  // the csv export carries a NUL byte, as real Logger.mdb exports sometimes do; the script removes it
  fs.writeFileSync(path.join(stubDir, "Events.csv"), EVENTS_CSV.replace("STUDY_STARTED", "STUDY_\0STARTED"));
  fs.writeFileSync(path.join(stubDir, "EALInfo.csv"), EAL_CSV);
});
afterAll(() => fs.rmSync(tmp, { recursive: true, force: true }));

let n = 0;
const sysDir = () => path.join(tmp, `SME0000${++n}`);
const run = (dir, env = {}) =>
  spawnSync(SCRIPT, [...FAKE, dir], {
    env: { ...process.env, PATH: `${stubDir}:${process.env.PATH}`, STUB_DIR: stubDir, ...env },
    encoding: "utf8",
  });
const PUBLISHED = ["Logger.mdb", "EALInfo.output", "Events.output", "EALInfo.csv", "Events.csv", "Data_Logger.ls"];
const seed = (dir) => {
  fs.mkdirSync(dir, { recursive: true });
  for (const f of PUBLISHED) fs.writeFileSync(path.join(dir, f), `previous ${f}\n`);
};
const expectUntouched = (dir) => {
  for (const f of PUBLISHED) expect(fs.readFileSync(path.join(dir, f), "utf8")).toBe(`previous ${f}\n`);
  expect(fs.existsSync(path.join(dir, ".incoming"))).toBe(false);
};
const expectNoCreds = (text) => { expect(text).not.toContain(FAKE[1]); expect(text).not.toContain(FAKE[2]); };

describe("phil_ct_data_grab_1.sh", () => {
  test("success: publishes the database, both legacy exports, both complete exports and the listing", () => {
    const dir = sysDir();
    seed(dir);
    const r = run(dir);
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(fs.readFileSync(path.join(dir, "Logger.mdb"), "utf8")).toBe("synthetic mdb\n");
    expect(fs.readFileSync(path.join(dir, "Events.csv"), "utf8")).toBe(EVENTS_CSV); // NUL removed, rows intact
    expect(fs.readFileSync(path.join(dir, "EALInfo.csv"), "utf8")).toBe(EAL_CSV);
    expect(fs.readFileSync(path.join(dir, "Data_Logger.ls"), "utf8")).toMatch(/Logger\.mdb/);
    expect(fs.existsSync(path.join(dir, ".incoming"))).toBe(false);
    // complete export: one physical line per row (+ header)
    expect(fs.readFileSync(path.join(dir, "Events.csv"), "utf8").trimEnd().split("\n")).toHaveLength(4);
  });

  test("success: legacy .output files keep the legacy format (header, tr/awk/sort/sed for Events)", () => {
    const dir = sysDir();
    expect(run(dir).status).toBe(0);
    const ev = fs.readFileSync(path.join(dir, "Events.output"), "utf8").split("\n");
    expect(ev[0]).toBe("Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime");
    // the legacy filter keeps only lines that start with the quoted EventTime after the awk reorder
    expect(ev.slice(1).filter(Boolean).every((l) => /^"[0-9][0-9]\//.test(l))).toBe(true);
    const eal = fs.readFileSync(path.join(dir, "EALInfo.output"), "utf8").split("\n");
    expect(eal[0]).toBe("DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime");
    expect(eal[1]).toBe(EAL_RAW.split("\n")[1]);
  });

  test("lftp: lists D:\\Data_Logger only after cd succeeds, and downloads into staging", () => {
    const dir = sysDir();
    run(dir);
    const args = fs.readFileSync(path.join(stubDir, "lftp.args"), "utf8");
    expect(args).toContain(`cd /cygdrive/d/Data_Logger/ && cls -l > ${dir}/.incoming/Data_Logger.ls;`);
    expect(args).toContain(`mget Logger.mdb -O ${dir}/.incoming;`);
  });

  test("connection failure: same stderr and exit status as before, nothing changes", () => {
    const dir = sysDir();
    seed(dir);
    const r = run(dir, { STUB_MODE: "timeout" });
    expect(r.status).toBe(0);
    expect(r.stderr).toContain("Connection timed out");
    expect(extractConnectionError(r.stderr, connection_regexes)?.connection_error).toBe(true);
    expectUntouched(dir);
  });

  test.each([
    ["legacy", "mdb-export Events (legacy)"],
    ["csv", "mdb-export EALInfo (csv)"],
  ])("export failure (%s): exit 1, phil_ct message, previous files kept", (mode, what) => {
    const dir = sysDir();
    seed(dir);
    const r = run(dir, { STUB_EXPORT_FAIL: mode });
    expect(r.status).toBe(1);
    expect(r.stderr).toContain(`phil_ct: ${what} failed; previous outputs kept`);
    // not mistaken for a connection or key problem by read/exec-hhm_data_grab.js
    expect(extractConnectionError(r.stderr, connection_regexes)).toBeNull();
    expectNoCreds(r.stderr);
    expectUntouched(dir);
  });

  test("empty download: exit 1, previous files kept", () => {
    const dir = sysDir();
    seed(dir);
    const r = run(dir, { STUB_MODE: "empty" });
    expect(r.status).toBe(1);
    expect(r.stderr).toContain("phil_ct: downloaded Logger.mdb is empty; previous outputs kept");
    expect(extractConnectionError(r.stderr, connection_regexes)).toBeNull();
    expectUntouched(dir);
  });

  test.each([[""], ["/"]])("no usable system directory (%j): exit 1 before touching anything", (dir) => {
    fs.rmSync(path.join(stubDir, "lftp.args"), { force: true });
    const r = spawnSync(SCRIPT, [...FAKE, dir], {
      env: { ...process.env, PATH: `${stubDir}:${process.env.PATH}`, STUB_DIR: stubDir },
      encoding: "utf8",
    });
    expect(r.status).toBe(1);
    expect(r.stderr).toContain("phil_ct: no system directory given");
    expect(fs.existsSync(path.join(stubDir, "lftp.args"))).toBe(false);
  });

  test("a second grab of the same system while one runs: skipped, nothing changes", async () => {
    const dir = sysDir();
    seed(dir);
    fs.rmSync(path.join(stubDir, "lftp.args"), { force: true });
    const holder = spawn("flock", [path.join(dir, ".grab.lock"), "sleep", "5"], { detached: true, stdio: "ignore" });
    const exited = new Promise((res) => holder.on("exit", res));
    await new Promise((res) => setTimeout(res, 300));
    try {
      const r = run(dir);
      expect(r.status).toBe(0);
      expect(r.stderr).toContain("phil_ct: previous grab of this system still running; skipped");
      expect(extractConnectionError(r.stderr, connection_regexes)).toBeNull();
      expect(fs.existsSync(path.join(stubDir, "lftp.args"))).toBe(false); // never connected
      expectUntouched(dir);
    } finally {
      process.kill(-holder.pid, "SIGTERM"); // flock and its sleep child
      await exited;
    }
  });
});
