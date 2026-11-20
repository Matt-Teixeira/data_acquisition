// Philips CT grab script (read/sh/Philips/phil_ct_data_grab_1.sh): control flow, outputs, and how
// read/exec-hhm_data_grab.js classifies each outcome.
//
// No network and no real scanner data: lftp, mdb-tables, mdb-export (and, per test, sort and flock)
// are replaced by stubs on PATH that produce small synthetic tables. Byte-equivalence of the legacy
// .output files and exactness of the .csv exports on real Logger.mdb copies were checked separately
// (see REVIEW-PCTC-COLLECTOR-HANDOFF.md).
// Run: npx jest read/__tests__/phil_ct_data_grab_1.test.js

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync, spawn } = require("child_process");

// --- runner mocks (only used by the "runner" block; no Redis, no Postgres) ---------------------
const mockQueue = { redis: jest.fn(async () => {}), online: jest.fn(async () => {}), reset: jest.fn(async () => {}) };
jest.mock("../../redis", () => ({
  add_to_redis_queue: (...a) => mockQueue.redis(...a),
  add_to_online_queue: (...a) => mockQueue.online(...a),
  add_system_reset_totalizer: (...a) => mockQueue.reset(...a),
}));
jest.mock("../../util", () => require("../../util/tools/connection_regex"));
const mockLog = jest.fn(async () => {});
jest.mock("../../utils/logger/log", () => [(...a) => mockLog(...a)]);
jest.mock("../../utils/logger/enums", () => ({
  type: { I: "I", W: "W", E: "E" },
  tag: { cal: "cal", det: "det", cat: "cat", seq: "seq", qaf: "qaf" },
}));

const { extractConnectionError, connection_regexes } = require("../../util/tools/connection_regex");

const SCRIPT = path.resolve(__dirname, "../sh/Philips/phil_ct_data_grab_1.sh");
const FAKE = ["192.0.2.10", "fakeuser_ct", "fake-pass-ct"]; // TEST-NET address, fake credentials

// --- synthetic tables ------------------------------------------------------------------------
// Events: a comma-bearing Msg and a multi-line Msg (both lost by the legacy export), an ordinary
// row and a relay row (EAL = Yes). mdb-export -e escapes the line break as \n.
const EVENTS_RAW =
  "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime\n" +
  '"EVENT_MINOR",4,"GSE",1,"2026/11/01 10:00:00.001","STUDY_STARTED was sent",,,"11/01/26 10:00:00"\n' +
  '"EVENT_MINOR",4,"GSE",2,"2026/11/01 10:00:01.002","Series 3 cancelled, due to X, in state Y",,,"11/01/26 10:00:01"\n' +
  '"EVENT_MINOR",4,"GSE",3,"2026/11/01 10:00:02.003__01","line one\nline two",,,"11/01/26 10:00:02"\n' +
  '"INFO",4,"Gantry",4,"2026/11/01 09:59:59.999","CStateShot","Yes",,"11/01/26 09:59:59"\n';
const EVENTS_CSV =
  "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime\n" +
  '"EVENT_MINOR",4,"GSE",1,"2026/11/01 10:00:00.001","STUDY_STARTED was sent",,,"2026-11-01 10:00:00"\n' +
  '"EVENT_MINOR",4,"GSE",2,"2026/11/01 10:00:01.002","Series 3 cancelled, due to X, in state Y",,,"2026-11-01 10:00:01"\n' +
  '"EVENT_MINOR",4,"GSE",3,"2026/11/01 10:00:02.003__01","line one\\nline two",,,"2026-11-01 10:00:02"\n' +
  '"INFO",4,"Gantry",4,"2026/11/01 09:59:59.999","CStateShot","Yes",,"2026-11-01 09:59:59"\n';
const EAL_RAW =
  "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime\n" +
  '"2026/11/01 10:00:00.001",1,"EAL",0,0,"FATAL",,0,,0,0,0,"Gen Shot120x200LO*","11/01/26 10:00:00"\n' +
  '"2026/11/01 09:00:00.500",0,"EAL",0,0,"WARN","S_DMC_SLIP_RING",0,"dmc.c",12,1,2,,"11/01/26 09:00:00"\n';
const EAL_CSV = EAL_RAW.replace(/"11\/01\/26 (\d\d:\d\d:\d\d)"/g, '"2026-11-01 $1"');

// Oracle: what the script before PCT-C (commit 0559fdb) writes for these tables. The comma and
// multi-line Events rows are missing; that loss is kept on purpose (the parser reads these files).
const EVENTS_OUTPUT_LEGACY =
  "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime\n" +
  '"11/01/26 09:59:59" "INFO" 4 "Gantry" 4 "2026/11/01 09:59:59.999" "CStateShot" "Yes" \n' +
  '"11/01/26 10:00:00" "EVENT_MINOR" 4 "GSE" 1 "2026/11/01 10:00:00.001" "STUDY_STARTED was sent"  \n';
const EALINFO_OUTPUT_LEGACY =
  "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime\n" +
  '"2026/11/01 09:00:00.500",0,"EAL",0,0,"WARN","S_DMC_SLIP_RING",0,"dmc.c",12,1,2,,"11/01/26 09:00:00"\n' +
  '"2026/11/01 10:00:00.001",1,"EAL",0,0,"FATAL",,0,,0,0,0,"Gen Shot120x200LO*","11/01/26 10:00:00"\n';

// --- stubs -----------------------------------------------------------------------------------
const sh = (s) => s.replace(/^\n/, "");
// lftp: every call appended to lftp.calls. Main session (has mget) vs listing session (no mget).
const STUB_LFTP = sh(`
#!/bin/sh
printf '%s\\n----\\n' "$2" >> "$STUB_DIR/lftp.calls"
case "$2" in
  *mget*) ;;
  *) # listing session
     lst=$(printf '%s' "$2" | sed -n 's/.*cls -l > \\([^;]*\\)$/\\1/p' | tr -d ' ')
     if [ -n "\${STUB_LIST_FAIL:-}" ]; then
       echo "cd: Fatal error: max-retries exceeded (connect to host 192.0.2.10 port 22: Connection timed out)" >&2
       exit 1
     fi
     if [ -n "\${STUB_LIST_PARTIAL:-}" ]; then
       echo "-rw-r--r-- 1 svc none 1234 Nov  2 15:26 Logger.mdb" > "$lst"
       echo "cls: Fatal error: max-retries exceeded" >&2
       exit 1
     fi
     if [ -n "\${STUB_LIST_IGNORE_TERM:-}" ]; then trap '' TERM; sleep 30.5; fi
     if [ -n "\${STUB_LIST_RESISTANT_CHILD:-}" ]; then ( trap '' TERM; exec sleep 47.25 ) & sleep 30.5; fi
     echo "-rw-r--r-- 1 svc none 1234 Nov  2 15:26 Logger.mdb" > "$lst"
     echo "-rw-r--r-- 1 svc none 1234 Oct  1 08:00 Logger_old.mdb" >> "$lst"
     exit 0 ;;
esac
case "\${STUB_MODE:-ok}" in
  timeout)
    echo "cd: Fatal error: max-retries exceeded (connect to host 192.0.2.10 port 22: Connection timed out)" >&2
    exit 1 ;;
esac
dest=$(printf '%s' "$2" | sed -n 's/.*mget Logger\\.mdb -O \\([^;]*\\);.*/\\1/p' | tr -d ' ')
[ -n "\${STUB_LFTP_SLEEP:-}" ] && sleep "$STUB_LFTP_SLEEP"
# a same-group child that ignores TERM and outlives this process (keeps fd 9)
if [ -n "\${STUB_LFTP_RESISTANT_CHILD:-}" ]; then ( trap '' TERM; exec sleep 47.25 ) & : > "$STUB_DIR/started.\${STUB_MARK:-x}"; sleep 30.5; fi
if [ -n "\${STUB_LFTP_LEAVE_CHILD:-}" ]; then ( trap '' TERM; exec sleep 47.25 ) & fi
if [ -n "\${STUB_LFTP_HANDSHAKE:-}" ]; then
  : > "$STUB_DIR/started.$STUB_MARK"
  i=0; while [ ! -e "$STUB_DIR/release.$STUB_MARK" ] && [ $i -lt 600 ]; do sleep 0.05; i=$((i+1)); done
fi
if [ "\${STUB_MODE:-ok}" = empty ]; then : > "$dest/Logger.mdb"; else printf '%s mdb\\n' "\${STUB_MARK:-synthetic}" > "$dest/Logger.mdb"; fi
exit 0
`);
const STUB_MDB_TABLES = sh(`
#!/bin/sh
[ -n "\${STUB_TABLES_FAIL:-}" ] && { echo "EALInfo Events "; exit 1; }
echo "EALInfo Events "
`);
// $1 = -e for the complete export; the last arg is the table. Fails for STUB_EXPORT_FAIL=<mode>:<table>.
const STUB_MDB_EXPORT = sh(`
#!/bin/sh
printf '%s|' "$@" >> "$STUB_DIR/export.calls"; echo >> "$STUB_DIR/export.calls"
eval "table=\\\${$#}"
mode=legacy; [ "$1" = "-e" ] && mode=csv
[ "\${STUB_EXPORT_FAIL:-}" = "$mode:$table" ] && { echo "mdb-export: synthetic failure" >&2; exit 2; }
cat "$STUB_DIR/$table.$mode"
`);
// sort: fails for STUB_SORT_FAIL=events (sorting ev.2) or =eal (sorting eal.1), else the real sort
const STUB_SORT = sh(`
#!/bin/sh
case "\${STUB_SORT_FAIL:-}:$*" in
  events:*ev.2*|eal:*eal.1*) cat "$@" > /dev/null; exit 2 ;;
esac
exec /usr/bin/sort "$@"
`);
// timeout: records its argv, then the real GNU timeout (exec keeps the pid and process group)
const STUB_TIMEOUT = sh(`
#!/bin/sh
printf '%s|' "$1" "$2" "$3" "$4" >> "$STUB_DIR/timeout.calls"; echo >> "$STUB_DIR/timeout.calls"
exec /usr/bin/timeout "$@"
`);
// sed: fails for STUB_SED_FAIL=split (the tables.txt split) or =names (reading tables.lines, after
// printing its output), else the real sed
const STUB_SED = sh(`
#!/bin/sh
case "\${STUB_SED_FAIL:-}:$*" in
  split:*tables.txt*) exit 4 ;;
  names:*tables.lines*) /usr/bin/sed "$@"; exit 4 ;;
esac
exec /usr/bin/sed "$@"
`);
// tr: the NUL-removing call (tr -d '\\000') fails for STUB_TR_FAIL=csv, else the real tr
const STUB_TR = sh(`
#!/bin/sh
if [ "\${STUB_TR_FAIL:-}" = csv ] && [ "$1" = "-d" ] && [ "$2" = '\\000' ]; then cat > /dev/null; exit 2; fi
exec /usr/bin/tr "$@"
`);
const STUB_FLOCK_ERROR = "#!/bin/sh\nexit 69\n";

let tmp, stubDir, flockErrDir, wrapper;
const writeExec = (p, body) => { fs.writeFileSync(p, body); fs.chmodSync(p, 0o755); };

beforeAll(() => {
  tmp = fs.mkdtempSync(path.join(os.tmpdir(), "philct-"));
  stubDir = path.join(tmp, "stub");
  flockErrDir = path.join(tmp, "stub-flock");
  fs.mkdirSync(stubDir);
  fs.mkdirSync(flockErrDir);
  writeExec(path.join(stubDir, "lftp"), STUB_LFTP);
  writeExec(path.join(stubDir, "mdb-tables"), STUB_MDB_TABLES);
  writeExec(path.join(stubDir, "mdb-export"), STUB_MDB_EXPORT);
  writeExec(path.join(stubDir, "sort"), STUB_SORT);
  writeExec(path.join(stubDir, "tr"), STUB_TR);
  writeExec(path.join(stubDir, "timeout"), STUB_TIMEOUT);
  writeExec(path.join(stubDir, "sed"), STUB_SED);
  fs.writeFileSync(path.join(stubDir, "runner.env"), "");
  // Every script run goes through this wrapper: stubs first on PATH, per-run settings from
  // runner.env (used by the runner tests, whose child env cannot be set from jest), and it
  // refuses to start (exit 99) unless lftp is the stub, so a test can never run the real lftp.
  wrapper = path.join(tmp, "grab-wrapper.sh");
  writeExec(wrapper, [
    "#!/bin/sh",
    `PATH="${stubDir}:$PATH"; STUB_DIR="${stubDir}"; export PATH STUB_DIR`,
    `[ "$(command -v lftp)" = "${stubDir}/lftp" ] || { echo "stub lftp not first on PATH" >&2; exit 99; }`,
    `. "${stubDir}/runner.env"`,
    `exec "${SCRIPT}" "$@"`,
    "",
  ].join("\n"));
  writeExec(path.join(flockErrDir, "flock"), STUB_FLOCK_ERROR);
  fs.writeFileSync(path.join(stubDir, "Events.legacy"), EVENTS_RAW);
  fs.writeFileSync(path.join(stubDir, "EALInfo.legacy"), EAL_RAW);
  // the csv export carries a NUL byte, as real Logger.mdb exports sometimes do; the script removes it
  fs.writeFileSync(path.join(stubDir, "Events.csv"), EVENTS_CSV.replace("STUDY_STARTED", "STUDY_\0STARTED"));
  fs.writeFileSync(path.join(stubDir, "EALInfo.csv"), EAL_CSV);
});
// leftovers of the deadline tests (all use distinctive sleep lengths) are SIGKILLed: they ignore TERM
const killLeftovers = () => spawnSync("pkill", ["-KILL", "-u", String(process.getuid()), "-f", "^sleep (47\\.25|30\\.5)$"]);
const leftovers = () => spawnSync("pgrep", ["-u", String(process.getuid()), "-f", "^sleep 47\\.25$"], { encoding: "utf8" }).stdout.trim();
afterEach(killLeftovers);
afterAll(() => { killLeftovers(); fs.rmSync(tmp, { recursive: true, force: true }); });

// Safety: a test must never run the real lftp (it would try to connect). Every child gets the stubs first.
test("stubs shadow the real tools", () => {
  const tools = ["lftp", "mdb-export", "mdb-tables", "sort", "tr", "timeout", "sed"];
  const r = spawnSync("sh", ["-c", tools.map((t) => `command -v ${t}`).join("; ")], { env: childEnv(), encoding: "utf8" });
  expect(r.stdout.trim().split("\n")).toEqual(tools.map((t) => path.join(stubDir, t)));
});
beforeEach(() => {
  for (const f of fs.readdirSync(stubDir)) {
    if (/^(lftp\.calls|export\.calls|timeout\.calls|started\..*|release\..*)$/.test(f)) fs.rmSync(path.join(stubDir, f), { force: true });
  }
});
const waitFor = async (pred, ms = 10000) => {
  const t0 = Date.now();
  while (!pred()) {
    if (Date.now() - t0 > ms) throw new Error("waitFor: timed out");
    await new Promise((res) => setTimeout(res, 25));
  }
};
const lockHeld = (dir) => spawnSync("flock", ["-n", path.join(dir, ".grab.lock"), "true"]).status === 1;

let n = 0;
const sysDir = () => path.join(tmp, `SME0${String(++n).padStart(4, "0")}`);
const childEnv = (env = {}, extraPath = "") => ({
  ...process.env,
  PATH: `${extraPath ? extraPath + ":" : ""}${stubDir}:${process.env.PATH}`,
  STUB_DIR: stubDir,
  ...env,
});
// bounded: a deadline regression fails the test in 20 s instead of hanging (leftovers are killed afterEach)
const run = (dir, env = {}, extraPath = "") =>
  spawnSync(wrapper, [...FAKE, dir], { env: childEnv(env, extraPath), encoding: "utf8", timeout: 20000, killSignal: "SIGKILL" });
const lftpCalls = () => {
  const p = path.join(stubDir, "lftp.calls");
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8").split("\n----\n").filter(Boolean) : [];
};
const PUBLISHED = ["Logger.mdb", "EALInfo.output", "Events.output", "EALInfo.csv", "Events.csv", "Data_Logger.ls"];
const read = (dir, f) => fs.readFileSync(path.join(dir, f), "utf8");
const staging = (dir) => fs.readdirSync(dir).filter((f) => f.startsWith(".incoming"));
const seed = (dir) => {
  fs.mkdirSync(dir, { recursive: true });
  for (const f of PUBLISHED) fs.writeFileSync(path.join(dir, f), `previous ${f}\n`);
};
const expectUntouched = (dir) => {
  for (const f of PUBLISHED) expect(read(dir, f)).toBe(`previous ${f}\n`);
  expect(staging(dir)).toEqual([]);
};
const expectNoCreds = (text) => { expect(text).not.toContain(FAKE[1]); expect(text).not.toContain(FAKE[2]); };
const holdLock = async (dir) => {
  fs.mkdirSync(dir, { recursive: true });
  const holder = spawn("flock", [path.join(dir, ".grab.lock"), "sleep", "10"], { detached: true, stdio: "ignore" });
  const exited = new Promise((res) => holder.on("exit", res));
  await waitFor(() => lockHeld(dir));
  return async () => { process.kill(-holder.pid, "SIGTERM"); await exited; };
};

describe("phil_ct_data_grab_1.sh", () => {
  test("success: publishes the database, legacy and complete exports and the listing, mode 0644", () => {
    const dir = sysDir();
    const r = run(dir);
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(read(dir, "Logger.mdb")).toBe("synthetic mdb\n");
    expect(read(dir, "Events.csv")).toBe(EVENTS_CSV); // NUL removed, rows intact
    expect(read(dir, "EALInfo.csv")).toBe(EAL_CSV);
    expect(read(dir, "Events.csv").trimEnd().split("\n")).toHaveLength(5); // one physical line per row + header
    expect(read(dir, "Data_Logger.ls")).toMatch(/Logger\.mdb/);
    expect(staging(dir)).toEqual([]);
    for (const f of PUBLISHED) expect(fs.statSync(path.join(dir, f)).mode & 0o777).toBe(0o644);
  });

  test("legacy .output files are byte-identical to the pre-PCT-C script's output", () => {
    const dir = sysDir();
    expect(run(dir).status).toBe(0);
    expect(read(dir, "Events.output")).toBe(EVENTS_OUTPUT_LEGACY);
    expect(read(dir, "EALInfo.output")).toBe(EALINFO_OUTPUT_LEGACY);
  });

  test("mdb-export is called with exactly the legacy and the complete-export arguments", () => {
    const dir = sysDir();
    expect(run(dir).status).toBe(0);
    const calls = fs.readFileSync(path.join(stubDir, "export.calls"), "utf8").trim().split("\n");
    const mdb = `${dir}/.incoming.[A-Za-z0-9]{6}/Logger\\.mdb`;
    expect(calls).toHaveLength(4);
    expect(calls[0]).toMatch(new RegExp(`^${mdb}\\|Events\\|$`));
    expect(calls[1]).toMatch(new RegExp(`^${mdb}\\|EALInfo\\|$`));
    expect(calls[2]).toMatch(new RegExp(`^-e\\|-b\\|strip\\|-T\\|%Y-%m-%d %H:%M:%S\\|${mdb}\\|EALInfo\\|$`));
    expect(calls[3]).toMatch(new RegExp(`^-e\\|-b\\|strip\\|-T\\|%Y-%m-%d %H:%M:%S\\|${mdb}\\|Events\\|$`));
  });

  test("lftp: download into private staging; the listing is a separate session", () => {
    const dir = sysDir();
    run(dir);
    const [main, listing] = lftpCalls();
    expect(main).toMatch(new RegExp(`cd /cygdrive/d/Data_Logger/; ?\\nmget Logger\\.mdb -O ${dir}/\\.incoming\\.[A-Za-z0-9]{6}; exit$`));
    expect(main).not.toContain("cls");
    expect(listing).toMatch(new RegExp(`cd /cygdrive/d/Data_Logger/ && cls -l > ${dir}/\\.incoming\\.[A-Za-z0-9]{6}/Data_Logger\\.ls$`));
    expect(listing).not.toContain("mget");
  });

  test("listing: skipped while fresh; repeated after 24 h and when the database shrank", () => {
    const dir = sysDir();
    expect(run(dir).status).toBe(0);
    expect(lftpCalls()).toHaveLength(2); // first grab lists
    fs.rmSync(path.join(stubDir, "lftp.calls"));
    expect(run(dir).status).toBe(0);
    expect(lftpCalls()).toHaveLength(1); // fresh listing: no second session
    fs.rmSync(path.join(stubDir, "lftp.calls"));
    const old = new Date(Date.now() - 2 * 86400e3);
    fs.utimesSync(path.join(dir, ".listing.attempt"), old, old);
    expect(run(dir).status).toBe(0);
    expect(lftpCalls()).toHaveLength(2); // last attempt older than 24 h
    fs.rmSync(path.join(stubDir, "lftp.calls"));
    fs.writeFileSync(path.join(dir, "Logger.mdb"), "x".repeat(1000)); // previous database larger: a reset
    expect(run(dir).status).toBe(0);
    expect(lftpCalls()).toHaveLength(2);
  });

  test("listing failure: grab still succeeds, stderr empty (never classified as a connection error)", () => {
    const dir = sysDir();
    seed(dir); // no .listing.attempt yet: due
    const r = run(dir, { STUB_LIST_FAIL: "1" });
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(read(dir, "Logger.mdb")).toBe("synthetic mdb\n");
    expect(read(dir, "Data_Logger.ls")).toBe("previous Data_Logger.ls\n");
    expect(staging(dir)).toEqual([]);
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
    ["legacy:Events", "mdb-export Events (legacy)"],
    ["legacy:EALInfo", "mdb-export EALInfo (legacy)"],
    ["csv:EALInfo", "mdb-export EALInfo (csv)"],
    ["csv:Events", "mdb-export Events (csv)"],
  ])("export failure (%s): exit 1, phil_ct message, previous files kept", (which, what) => {
    const dir = sysDir();
    seed(dir);
    const r = run(dir, { STUB_EXPORT_FAIL: which });
    expect(r.status).toBe(1);
    expect(r.stderr).toContain(`phil_ct: ${what} failed; previous outputs kept`);
    expect(extractConnectionError(r.stderr, connection_regexes)).toBeNull(); // not a connection/key problem
    expectNoCreds(r.stderr);
    expectUntouched(dir);
  });

  test.each([
    [{ STUB_TABLES_FAIL: "1" }, "mdb-tables failed"],
    [{ STUB_SORT_FAIL: "events" }, "Events legacy sort failed"],
    [{ STUB_SORT_FAIL: "eal" }, "EALInfo legacy sort failed"],
    [{ STUB_TR_FAIL: "csv" }, "tr EALInfo.csv failed"],
    [{ STUB_SED_FAIL: "split" }, "mdb-tables (split) failed"],
    [{ STUB_SED_FAIL: "names" }, "mdb-tables (table names) failed"],
  ])("processing step failure %j: exit 1, previous files kept", (env, msg) => {
    const dir = sysDir();
    seed(dir);
    const r = run(dir, env);
    expect(r.status).toBe(1);
    expect(r.stderr).toContain(`phil_ct: ${msg}`);
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

  test("restrictive umask: published files are still 0644", () => {
    const dir = sysDir();
    seed(dir);
    for (const f of PUBLISHED) fs.chmodSync(path.join(dir, f), 0o644);
    const r = spawnSync("sh", ["-c", 'umask 077; exec "$0" "$@"', wrapper, ...FAKE, dir], { env: childEnv(), encoding: "utf8" }); // listing due
    expect(r.status).toBe(0);
    for (const f of PUBLISHED) expect(fs.statSync(path.join(dir, f)).mode & 0o777).toBe(0o644);
  });

  test("publish failure part-way: exit 1 and the message names what was already published", () => {
    const dir = sysDir();
    seed(dir);
    fs.rmSync(path.join(dir, "Events.output"));
    fs.mkdirSync(path.join(dir, "Events.output")); // mv -T cannot replace a directory
    const r = run(dir);
    expect(r.status).toBe(1);
    expect(r.stderr).toContain("phil_ct: publish Events.output failed; outputs partly updated (already published: Logger.mdb EALInfo.output)");
    expect(read(dir, "Logger.mdb")).toBe("synthetic mdb\n");
    expect(read(dir, "EALInfo.output")).toBe(EALINFO_OUTPUT_LEGACY);
    expect(read(dir, "EALInfo.csv")).toBe("previous EALInfo.csv\n");
    expect(staging(dir)).toEqual([]);
  });

  test.each([[""], ["/"]])("no usable system directory (%j): exit 1 before touching anything", (dir) => {
    const r = run(dir);
    expect(r.status).toBe(1);
    expect(r.stderr).toContain("phil_ct: no system directory given");
    expect(lftpCalls()).toEqual([]);
  });

  test("lock held by another grab: exit 75, nothing changes, no connection", async () => {
    const dir = sysDir();
    seed(dir);
    const release = await holdLock(dir);
    try {
      const r = run(dir);
      expect(r.status).toBe(75);
      expect(r.stderr).toContain("phil_ct: previous grab of this system still running; skipped");
      expect(extractConnectionError(r.stderr, connection_regexes)).toBeNull();
      expect(lftpCalls()).toEqual([]);
      expectUntouched(dir);
    } finally {
      await release();
    }
  });

  test("flock itself fails: exit 1 (not treated as a skip), nothing changes", () => {
    const dir = sysDir();
    seed(dir);
    const r = run(dir, {}, flockErrDir);
    expect(r.status).toBe(1);
    expect(r.stderr).toContain("phil_ct: flock failed (status 69)");
    expect(lftpCalls()).toEqual([]);
    expectUntouched(dir);
  });

  test("orphaned download after the grab is killed: holds the lock, and never reaches the next grab", async () => {
    const dir = sysDir();
    seed(dir);
    // grab A: its download (lftp) is slow; kill only A's shell while lftp runs
    const a = spawn(wrapper, [...FAKE, dir], { env: childEnv({ STUB_LFTP_HANDSHAKE: "1", STUB_MARK: "A" }), stdio: "ignore" });
    const aExit = new Promise((res) => a.on("exit", res));
    await waitFor(() => fs.existsSync(path.join(stubDir, "started.A"))); // A's download is running
    a.kill("SIGKILL");
    await aExit;
    // A's lftp survives as an orphan and still holds the lock
    const b1 = run(dir, { STUB_MARK: "B" });
    expect(b1.status).toBe(75);
    expect(read(dir, "Logger.mdb")).toBe("previous Logger.mdb\n");
    // release the orphan: it writes into A's private staging and exits; the next grab publishes its own data
    fs.writeFileSync(path.join(stubDir, "release.A"), "");
    await waitFor(() => !lockHeld(dir));
    const b2 = run(dir, { STUB_MARK: "B" });
    expect(b2.status).toBe(0);
    expect(read(dir, "Logger.mdb")).toBe("B mdb\n");
    expect(staging(dir)).toEqual([]); // A's leftover staging removed under the lock
  });

  test("listing fails part-way: the previous listing and its time are kept, stderr empty", () => {
    const dir = sysDir();
    seed(dir);
    const old = new Date(Date.now() - 3 * 86400e3);
    fs.utimesSync(path.join(dir, "Data_Logger.ls"), old, old);
    const r = run(dir, { STUB_LIST_PARTIAL: "1" });
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(read(dir, "Data_Logger.ls")).toBe("previous Data_Logger.ls\n");
    expect(Math.round(fs.statSync(path.join(dir, "Data_Logger.ls")).mtimeMs / 1000)).toBe(Math.round(old.getTime() / 1000));
  });

  test("listing that ignores TERM is killed after the grace period; the lock is free afterwards", () => {
    const dir = sysDir();
    const t0 = Date.now();
    const r = run(dir, { STUB_LIST_IGNORE_TERM: "1", PHIL_CT_LIST_TIMEOUT: "1", PHIL_CT_KILL_GRACE: "1" });
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(Date.now() - t0).toBeLessThan(8000);
    expect(lockHeld(dir)).toBe(false);
    expect(run(dir).status).toBe(0);
  });

  test("download deadline: reported like a failed connection, nothing changes, lock free afterwards", () => {
    const dir = sysDir();
    seed(dir);
    const t0 = Date.now();
    const r = run(dir, { STUB_LFTP_SLEEP: "30", PHIL_CT_DL_TIMEOUT: "1", PHIL_CT_KILL_GRACE: "1" });
    expect(r.status).toBe(0);
    expect(r.stderr).toContain("Connection timed out");
    expect(extractConnectionError(r.stderr, connection_regexes)?.connection_error).toBe(true);
    expect(Date.now() - t0).toBeLessThan(8000);
    expectUntouched(dir);
    expect(lockHeld(dir)).toBe(false);
  });

  test("deadline settings: only whole seconds are accepted", () => {
    const dir = sysDir();
    const r = run(dir, { PHIL_CT_DL_TIMEOUT: "1; rm -rf /", PHIL_CT_LIST_TIMEOUT: "-5", PHIL_CT_KILL_GRACE: "x" });
    expect(r.status).toBe(0); // defaults used
    expect(r.stderr).toBe("");
  });

  test("failed listings are not retried on every grab (throttled by attempt time)", () => {
    const dir = sysDir();
    seed(dir); // listing absent from the throttle's point of view: no attempt yet
    const counts = [];
    for (let i = 0; i < 3; i++) {
      fs.rmSync(path.join(stubDir, "lftp.calls"), { force: true });
      expect(run(dir, { STUB_LIST_FAIL: "1" }).status).toBe(0);
      counts.push(lftpCalls().length);
    }
    expect(counts).toEqual([2, 1, 1]);
    expect(read(dir, "Data_Logger.ls")).toBe("previous Data_Logger.ls\n");
  });

  test("a shrunk database (possible reset): listed now, retried hourly while failing, cleared on success", () => {
    const dir = sysDir();
    expect(run(dir).status).toBe(0); // first grab: listing done, attempt fresh
    const calls = (env) => { fs.rmSync(path.join(stubDir, "lftp.calls"), { force: true }); expect(run(dir, env).status).toBe(0); return lftpCalls().length; };
    fs.writeFileSync(path.join(dir, "Logger.mdb"), "x".repeat(1000)); // previous database larger
    expect(calls({ STUB_LIST_FAIL: "1" })).toBe(2); // shrink: attempt now despite a fresh attempt
    expect(fs.existsSync(path.join(dir, ".listing.reset_pending"))).toBe(true);
    expect(calls({ STUB_LIST_FAIL: "1" })).toBe(1); // same size, attempt < 1 h ago: wait
    const hourAgo = new Date(Date.now() - 61 * 60e3);
    fs.utimesSync(path.join(dir, ".listing.attempt"), hourAgo, hourAgo);
    expect(calls({})).toBe(2); // pending and > 1 h: retry, succeeds
    expect(fs.existsSync(path.join(dir, ".listing.reset_pending"))).toBe(false);
    expect(read(dir, "Data_Logger.ls")).toMatch(/Logger_old\.mdb/);
    fs.utimesSync(path.join(dir, ".listing.attempt"), hourAgo, hourAgo);
    expect(calls({})).toBe(1); // nothing pending, daily throttle
  });

  test("listing cannot be installed (directory at its path): grab succeeds, stderr empty", () => {
    const dir = sysDir();
    fs.mkdirSync(path.join(dir, "Data_Logger.ls"), { recursive: true });
    const r = run(dir);
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(read(dir, "Events.csv")).toBe(EVENTS_CSV);
  });

  test("publish failure at a later file: the message lists exactly what was published", () => {
    const dir = sysDir();
    seed(dir);
    fs.rmSync(path.join(dir, "EALInfo.csv"));
    fs.mkdirSync(path.join(dir, "EALInfo.csv"));
    const r = run(dir);
    expect(r.status).toBe(1);
    expect(r.stderr).toContain("phil_ct: publish EALInfo.csv failed; outputs partly updated (already published: Logger.mdb EALInfo.output Events.output)");
    expect(read(dir, "Events.output")).toBe(EVENTS_OUTPUT_LEGACY);
    expect(read(dir, "Events.csv")).toBe("previous Events.csv\n");
  });

  test("each grab stages in its own private directory", () => {
    const dir = sysDir();
    expect(run(dir).status).toBe(0);
    expect(run(dir).status).toBe(0);
    const stagings = fs.readFileSync(path.join(stubDir, "export.calls"), "utf8").trim().split("\n")
      .map((l) => l.match(/\.incoming\.[A-Za-z0-9]{6}/)[0]);
    expect(stagings).toHaveLength(8);
    expect(new Set(stagings).size).toBe(2);
  });

  test.each([
    ["dangling symlink", (p) => fs.symlinkSync("/nonexistent-philct/attempt", p), 1],
    ["read-only, old", (p) => { fs.writeFileSync(p, ""); fs.chmodSync(p, 0o444); const t = new Date(Date.now() - 2 * 86400e3); fs.utimesSync(p, t, t); }, 2],
  ])("listing attempt state %s: grab still succeeds, stderr empty", (label, make, sessions) => {
    const dir = sysDir();
    seed(dir);
    make(path.join(dir, ".listing.attempt"));
    const r = run(dir);
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(read(dir, "Events.csv")).toBe(EVENTS_CSV);
    expect(lftpCalls()).toHaveLength(sessions); // attempt time not recordable -> no listing session
  });

  test("reset flag cannot be created: grab still succeeds, the listing is still attempted", () => {
    const dir = sysDir();
    expect(run(dir).status).toBe(0);
    fs.writeFileSync(path.join(dir, "Logger.mdb"), "x".repeat(1000)); // shrink
    fs.symlinkSync("/nonexistent-philct/pending", path.join(dir, ".listing.reset_pending"));
    fs.rmSync(path.join(stubDir, "lftp.calls"));
    const r = run(dir);
    expect(r.status).toBe(0);
    expect(r.stderr).toBe("");
    expect(lftpCalls()).toHaveLength(2);
  });

  test.each([
    ["download", { STUB_LFTP_RESISTANT_CHILD: "1", PHIL_CT_DL_TIMEOUT: "1" }, "Connection timed out"],
    ["listing", { STUB_LIST_RESISTANT_CHILD: "1", PHIL_CT_LIST_TIMEOUT: "1" }, ""],
  ])("%s: a TERM-resistant child left behind by the session is killed; the lock is free", (which, env, stderr) => {
    const dir = sysDir();
    const t0 = Date.now();
    const r = run(dir, { ...env, PHIL_CT_KILL_GRACE: "1" });
    expect(r.status).toBe(0);
    if (stderr) expect(r.stderr).toContain(stderr); else expect(r.stderr).toBe("");
    expect(Date.now() - t0).toBeLessThan(10000);
    expect(leftovers()).toBe("");
    expect(lockHeld(dir)).toBe(false);
  });

  test("collector killed while a TERM-resistant child holds the lock: cleaned up after limit + grace, next grab runs", async () => {
    const dir = sysDir();
    seed(dir);
    const c = spawn(wrapper, [...FAKE, dir], {
      env: childEnv({ STUB_LFTP_RESISTANT_CHILD: "1", STUB_MARK: "K", PHIL_CT_DL_TIMEOUT: "1", PHIL_CT_KILL_GRACE: "1" }),
      stdio: ["ignore", "pipe", "pipe"],
    });
    const pipesClosed = new Promise((res) => c.on("close", res)); // fires once every holder of stdout/stderr is gone
    c.stdout.resume(); c.stderr.resume();
    await waitFor(() => fs.existsSync(path.join(stubDir, "started.K"))); // resistant child is running
    process.kill(c.pid, "SIGKILL"); // only the collector shell
    const t0 = Date.now();
    await waitFor(() => !lockHeld(dir), 10000);
    expect(Date.now() - t0).toBeLessThan(8000);
    await pipesClosed;
    expect(leftovers()).toBe("");
    // the killed grab published nothing; its private staging stays until the next grab removes it under the lock
    for (const f of PUBLISHED) expect(read(dir, f)).toBe(`previous ${f}\n`);
    expect(staging(dir)).toHaveLength(1);
    expect(run(dir).status).toBe(0);
    expect(read(dir, "Logger.mdb")).toBe("synthetic mdb\n");
    expect(staging(dir)).toEqual([]);
  }, 20000);

  test("a child left behind by a successful download is killed too", () => {
    const dir = sysDir();
    const r = run(dir, { STUB_LFTP_LEAVE_CHILD: "1" });
    expect(r.status).toBe(0);
    expect(leftovers()).toBe("");
    expect(lockHeld(dir)).toBe(false);
  });

  test.each([
    [{ PHIL_CT_DL_TIMEOUT: "0", PHIL_CT_LIST_TIMEOUT: "000", PHIL_CT_KILL_GRACE: "9999999" }, ["-k|15|600|lftp|", "-k|15|120|lftp|"]],
    [{ PHIL_CT_DL_TIMEOUT: "86401", PHIL_CT_LIST_TIMEOUT: "", PHIL_CT_KILL_GRACE: "0" }, ["-k|15|600|lftp|", "-k|15|120|lftp|"]],
    [{ PHIL_CT_DL_TIMEOUT: "0030", PHIL_CT_LIST_TIMEOUT: "45", PHIL_CT_KILL_GRACE: "5" }, ["-k|5|30|lftp|", "-k|5|45|lftp|"]],
  ])("deadline settings %j reach timeout as %j", (env, expected) => {
    const dir = sysDir();
    expect(run(dir, env).status).toBe(0);
    const calls = fs.readFileSync(path.join(stubDir, "timeout.calls"), "utf8").trim().split("\n");
    expect(calls).toEqual(expected);
  });
});

// --- the real runner, with Redis/logger mocked: what each outcome records ----------------------
describe("read/exec-hhm_data_grab.js with this script", () => {
  const exec_hhm_data_grab = require("../exec-hhm_data_grab");
  // The runner calls execFile without an env, and child_process then uses the real process.env,
  // not jest's sandboxed copy, so per-test settings go through runner.env and the shared wrapper.
  const saved = {};
  let root;
  const setRunnerEnv = (text) => fs.writeFileSync(path.join(stubDir, "runner.env"), text);
  beforeAll(() => {
    root = fs.mkdtempSync(path.join(tmp, "runner-"));
    for (const k of ["RUN_ENV", "DEV_HHM_FILES"]) saved[k] = process.env[k];
    process.env.RUN_ENV = "dev"; // read by the runner itself (sandboxed env is fine there)
    process.env.DEV_HHM_FILES = root;
    jest.spyOn(console, "log").mockImplementation(() => {});
  });
  afterAll(() => {
    setRunnerEnv("");
    for (const [k, v] of Object.entries(saved)) { if (v === undefined) delete process.env[k]; else process.env[k] = v; }
    console.log.mockRestore();
  });
  beforeEach(() => {
    mockQueue.redis.mockClear(); mockQueue.online.mockClear(); mockQueue.reset.mockClear(); mockLog.mockClear();
    setRunnerEnv("");
  });
  const grab = (sme) => exec_hhm_data_grab("job-1", { log_events: [] }, sme, wrapper, { id: sme }, [...FAKE], "2026-11-20T00:00:00Z");
  const errorsLogged = () => mockLog.mock.calls.filter((c) => c[0] === "E").length;

  test("success: online queue, successful_acquisition true", async () => {
    await grab("SME09001");
    expect(mockQueue.online).toHaveBeenCalledTimes(1);
    expect(mockQueue.online.mock.calls[0][2]).toMatchObject({ id: "SME09001", successful_acquisition: true });
    expect(mockQueue.redis).not.toHaveBeenCalled();
  });

  test("connection timeout: redis (retry) queue, as before", async () => {
    setRunnerEnv("export STUB_MODE=timeout\n");
    await grab("SME09002");
    expect(mockQueue.redis).toHaveBeenCalledTimes(1);
    expect(mockQueue.online).not.toHaveBeenCalled();
  });

  test("download deadline: handled like a failed connection (redis retry queue)", async () => {
    setRunnerEnv("export STUB_LFTP_SLEEP=30 PHIL_CT_DL_TIMEOUT=1 PHIL_CT_KILL_GRACE=1\n");
    await grab("SME09005");
    expect(mockQueue.redis).toHaveBeenCalledTimes(1);
    expect(mockQueue.online).not.toHaveBeenCalled();
  });

  test("download deadline with a TERM-resistant child: the runner still gets its answer (redis queue)", async () => {
    setRunnerEnv("export STUB_LFTP_RESISTANT_CHILD=1 PHIL_CT_DL_TIMEOUT=1 PHIL_CT_KILL_GRACE=1\n");
    await grab("SME09006");
    expect(mockQueue.redis).toHaveBeenCalledTimes(1);
    expect(mockQueue.online).not.toHaveBeenCalled();
    expect(leftovers()).toBe("");
  }, 15000);

  test("skipped (lock held): no acquisition recorded, an error is logged", async () => {
    const release = await holdLock(path.join(root, "SME09003"));
    try {
      await grab("SME09003");
    } finally {
      await release();
    }
    expect(mockQueue.online).not.toHaveBeenCalled();
    expect(mockQueue.redis).not.toHaveBeenCalled();
    expect(errorsLogged()).toBe(1);
  });

  test("export failure: no acquisition recorded, an error is logged", async () => {
    setRunnerEnv("export STUB_EXPORT_FAIL=csv:Events\n");
    await grab("SME09004");
    expect(mockQueue.online).not.toHaveBeenCalled();
    expect(mockQueue.redis).not.toHaveBeenCalled();
    expect(errorsLogged()).toBe(1);
  });
});
