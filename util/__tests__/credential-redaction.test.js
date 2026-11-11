// Credential redaction: a collector script that fails (or echoes its arguments) must not
// put device credentials into util.app_run_logs, the local run-log file or the console.
//
// Uses FAKE credentials only, generated per run. They pass through the real
// encryptString/decryptString so the decrypt -> register path is exercised end to end.
// Run: npx jest util/__tests__/credential-redaction.test.js

const fs = require("fs");
const os = require("os");
const path = require("path");
const util = require("util");
const crypto = require("crypto");
const execFile = util.promisify(require("child_process").execFile);

// --- mocks: no Redis, no Postgres ------------------------------------------------
jest.mock("../../redis", () => ({
  add_to_redis_queue: jest.fn(async () => {}),
  add_to_online_queue: jest.fn(async () => {}),
  add_system_reset_totalizer: jest.fn(async () => {}),
}));
// the wrapper only needs the connection regexes from ../util; avoid loading the
// rest of util/index.js (Redis/DB clients)
jest.mock("../../util", () => require("../tools/connection_regex"));
const mockDbNone = jest.fn(async () => {});
jest.mock("../../utils/db/pg-pool", () => ({ none: (...a) => mockDbNone(...a) }));

const pgp = require("pg-promise")();
const {
  MASK,
  redactString,
  safeStringify,
  installConsoleRedaction,
  _resetSecretsForTests,
} = require("../redact");
const { encryptString, decryptString } = require("../encrypt");

// --- fake credentials --------------------------------------------------------------
const rnd = crypto.randomBytes(6).toString("hex");
const FAKE_USER = `fakeuser_${rnd}`;
// quote, backslash, space, single quote, URL-reserved chars: exercises every escape form
const FAKE_PASS = `Fk"p\\@ss w0rd'${rnd}&/`;

// every textual form a value can take in a log line / JSON / SQL / URL
const leakForms = (v) => [
  v,
  JSON.stringify(v).slice(1, -1),
  util.inspect(v).slice(1, -1),
  encodeURIComponent(v),
  v.replace(/'/g, "''"), // SQL literal escaping (pg-promise)
  JSON.stringify(v).slice(1, -1).replace(/'/g, "''"), // JSON inside a SQL literal
];
const expectNoLeak = (label, text) => {
  expect(typeof text).toBe("string");
  for (const secret of [FAKE_USER, FAKE_PASS]) {
    for (const form of leakForms(secret)) {
      if (text.includes(form)) {
        // never print the value; say which sink and which form leaked
        throw new Error(`${label}: credential leaked (form #${leakForms(secret).indexOf(form)})`);
      }
    }
  }
};
const containsSecret = (text) =>
  [FAKE_USER, FAKE_PASS].some((s) => leakForms(s).some((f) => text.includes(f)));

// --- temp workspace: collector scripts + run-log dir ---------------------------------
const origCwd = process.cwd();
let tmp, failScript, echoScript;
const consoleOut = [];

beforeAll(() => {
  tmp = fs.mkdtempSync(path.join(os.tmpdir(), "credlog-"));
  fs.mkdirSync(path.join(tmp, "utils", "logger"), { recursive: true });
  // fails and echoes all its args to stderr (worst case: a tool that prints argv)
  failScript = path.join(tmp, "fail.sh");
  fs.writeFileSync(failScript, '#!/bin/sh\necho "login as $2 failed; args: $*" >&2\nexit 3\n');
  // succeeds but echoes its args to stdout and stderr
  echoScript = path.join(tmp, "echo.sh");
  fs.writeFileSync(echoScript, '#!/bin/sh\necho "out: $*"\necho "err: $3" >&2\nexit 0\n');
  fs.chmodSync(failScript, 0o755);
  fs.chmodSync(echoScript, 0o755);

  process.chdir(tmp); // log.js writes ./utils/logger/<APP_NAME>-log.<LOGGER>.<run_id>.js
  process.env.APP_NAME = "credlog_test";
  process.env.LOGGER = "dev"; // also exercises log.js's dev console output

  // capture console as text, then guard it the way index.js does at boot. The captured trace
  // writes directly (does not call console.error), so the guard must wrap trace itself.
  for (const m of ["log", "info", "warn", "error", "debug", "trace"]) {
    console[m] = (...a) => consoleOut.push(util.format(...a));
  }
  installConsoleRedaction(console);
});

afterAll(() => {
  process.chdir(origCwd);
  fs.rmSync(tmp, { recursive: true, force: true });
});

const readRunLogFile = async () => {
  const dir = path.join(tmp, "utils", "logger");
  for (let i = 0; i < 50; i++) {
    const files = fs.readdirSync(dir).filter((f) => f.startsWith("credlog_test-log."));
    if (files.length === 1) {
      const text = fs.readFileSync(path.join(dir, files[0]), "utf8");
      if (text.length > 0) {
        try {
          JSON.parse(text);
          return text;
        } catch (e) {
          // still being flushed
        }
      }
    }
    await new Promise((r) => setTimeout(r, 50));
  }
  throw new Error("run-log file not written");
};

describe("redactString / safeStringify (unit)", () => {
  afterEach(() => _resetSecretsForTests());

  test("no registered secrets: strings unchanged", () => {
    expect(redactString("Command failed: ./x.sh 1.2.3.4 a b")).toBe("Command failed: ./x.sh 1.2.3.4 a b");
  });

  test("exact match in every escaped form; longer value masked whole", () => {
    const { registerSecret } = require("../redact");
    registerSecret("abc");
    registerSecret("abc-longer");
    expect(redactString("x abc-longer y abc z")).toBe(`x ${MASK} y ${MASK} z`);
    registerSecret(FAKE_PASS);
    const json = JSON.stringify({ m: `Command failed: ./x.sh ip u ${FAKE_PASS} /p` });
    expect(containsSecret(json)).toBe(true); // raw JSON does contain it
    const safe = safeStringify({ m: `Command failed: ./x.sh ip u ${FAKE_PASS} /p` });
    expect(containsSecret(safe)).toBe(false);
    expect(JSON.parse(safe).m).toBe(`Command failed: ./x.sh ip u ${MASK} /p`);
  });

  test("redactInPlace: nested objects, arrays, Error own props, cycles", () => {
    const { registerSecret, redactInPlace } = require("../redact");
    registerSecret(FAKE_PASS);
    const err = new Error(`Command failed: ./x.sh ip u ${FAKE_PASS}`);
    err.cmd = `./x.sh ip u ${FAKE_PASS}`;
    const ev = [{ note: { args: ["ip", "u", FAKE_PASS], error: err }, n: 1 }];
    ev[0].self = ev; // cycle
    redactInPlace(ev);
    expect(ev[0].note.args).toEqual(["ip", "u", MASK]);
    expect(err.cmd).toBe(`./x.sh ip u ${MASK}`);
    expect(err.message).toBe(`Command failed: ./x.sh ip u ${MASK}`);
    expect(containsSecret(err.stack)).toBe(false);
    expect(ev[0].n).toBe(1);
  });

  test("non-strings pass through", () => {
    const { registerSecret } = require("../redact");
    registerSecret("s3cr3t");
    expect(redactString(undefined)).toBeUndefined();
    expect(safeStringify({ n: 1, b: true, z: null })).toBe('{"n":1,"b":true,"z":null}');
  });
});

describe("failing execFile with fake credentials (integration)", () => {
  let run_log, error;
  // the shared, UNMODIFIED logger (AvanteHS-RTT/utils); redaction comes from flushRunLog
  const [addLogEvent, , , makeAppRunLog] = require("../../utils/logger/log");
  const flushRunLog = require("../flush_run_log");
  const exec_hhm_data_grab = require("../../read/exec-hhm_data_grab");

  beforeAll(async () => {
    _resetSecretsForTests();
    // the collector's path: credentials arrive encrypted and are decrypted per run
    const user = decryptString(encryptString(FAKE_USER));
    const pass = decryptString(encryptString(FAKE_PASS));
    expect(user).toBe(FAKE_USER);
    expect(pass).toBe(FAKE_PASS);

    // negative control: the raw execFile error really does carry the credentials
    error = await execFile(failScript, ["10.0.0.1", user, pass, "/data"]).catch((e) => e);
    expect(containsSecret(error.message)).toBe(true);
    expect(containsSecret(error.stack)).toBe(true);
    expect(containsSecret(error.cmd)).toBe(true);
    expect(containsSecret(error.stderr)).toBe(true);

    run_log = await makeAppRunLog();
    const system = { id: "SMETEST1" };
    // failure path: wrapper logs args (I), then the execFile error (E) via its catch
    const failed = await exec_hhm_data_grab("job-1", run_log, "SMETEST1", failScript, system,
      ["10.0.0.1", user, pass], "2026-11-11T00:00:00Z");
    expect(failed).toBeNull();
    // success path: stdout/stderr that echo the args are logged as a det event
    await exec_hhm_data_grab("job-2", run_log, "SMETEST1", echoScript, system,
      ["10.0.0.1", user, pass], "2026-11-11T00:00:00Z");
    // a raw Error object inside a note: JSON.stringify serializes cmd/stdout/stderr
    await addLogEvent("ERROR", run_log, "test_note_error", "cat", { error }, error);
    // a plain-string err (not an Error)
    await addLogEvent("ERROR", run_log, "test_string_err", "cat", null, error.message);

    console.log(error); // what every catch block in read/exec-*.js does
    console.log("\nExec Note", { args: ["10.0.0.1", user, pass] });
    console.trace("trace", error.message);

    await flushRunLog(pgp, run_log); // exactly what index.js does at the end of a run
  });

  test("the scenario logged errors at all (guards against a vacuous pass)", () => {
    const types = run_log.log_events.map((e) => e.type);
    expect(types).toContain("ERROR");
    expect(run_log.log_events.some((e) => typeof e.err_msg === "string" && e.err_msg.includes("Command failed:"))).toBe(true);
  });

  test("util.app_run_logs INSERT has no credential", () => {
    const insert = mockDbNone.mock.calls.map((c) => c[0]).find((q) => /app_run_logs/.test(q));
    expect(insert).toBeDefined();
    expectNoLeak("app_run_logs INSERT", insert);
    expect(insert).toContain("Command failed:");
    expect(insert).toContain(MASK);
    // the IP and script path survive, so the row is still useful
    expect(insert).toContain("10.0.0.1");
    expect(insert).toContain("fail.sh");
  });

  test("local run-log file has no credential and is valid JSON", async () => {
    const text = await readRunLogFile();
    expectNoLeak("run-log file", text);
    const events = JSON.parse(text);
    const errEvent = events.find((e) => e.func === "exec_hhm_data_grab" && e.type === "ERROR");
    expect(errEvent.err_msg).toContain(`Command failed: ${failScript} 10.0.0.1 ${MASK} ${MASK}`);
    const argsEvent = events.find((e) => e.note && Array.isArray(e.note.args));
    expect(argsEvent.note.args.slice(0, 3)).toEqual(["10.0.0.1", MASK, MASK]);
  });

  test("console output has no credential", () => {
    expect(consoleOut.length).toBeGreaterThan(0);
    const all = consoleOut.join("\n");
    expectNoLeak("console", all);
    expect(all).toContain("Command failed:");
  });
});
