// CREDENTIAL REDACTION FOR LOGS
//
// Device credentials are decrypted at run time (util/encrypt decryptString) and passed
// to collector scripts as command-line arguments. Anything that echoes those arguments
// (the execFile error message / stack / cmd, a logged `args` array, console output)
// would otherwise carry the plain-text values into util.app_run_logs, the local run-log
// files and cron output.
//
// Approach: every value that decryptString returns is registered here for the life of
// the process (one cron run = one process). At each sink (DB insert, run-log file,
// console, stats.job_runs) strings are scrubbed by EXACT match against the registered
// values, including the escaped forms that JSON.stringify and util.inspect produce.
// No positional regexes: a value is masked wherever it appears, in any field.

const util = require("util");

const MASK = "***";

// literal forms to mask, longest first so that a value that contains another
// registered value is masked as a whole
let needles = [];
const secrets = new Set();

const variants = (value) => {
  const out = new Set([value]);
  out.add(JSON.stringify(value).slice(1, -1)); // as embedded in JSON text
  out.add(util.inspect(value).slice(1, -1)); // as printed by console.log(obj)
  try {
    out.add(encodeURIComponent(value)); // as embedded in a URL
  } catch (e) {
    // lone surrogate: not URL-encodable, nothing to add
  }
  return out;
};

const registerSecret = (value) => {
  if (typeof value !== "string" || value.length === 0 || secrets.has(value)) {
    return value;
  }
  secrets.add(value);
  const all = new Set(needles);
  for (const v of variants(value)) if (v.length > 0) all.add(v);
  needles = [...all].sort((a, b) => b.length - a.length);
  return value;
};

const redactString = (str) => {
  if (typeof str !== "string" || needles.length === 0) return str;
  let out = str;
  for (const needle of needles) {
    if (out.includes(needle)) out = out.split(needle).join(MASK);
  }
  return out;
};

// SCRUB EVERY STRING REACHABLE FROM value, IN PLACE: array items and own enumerable
// properties (what JSON.stringify serializes, including the cmd / stdout / stderr of an
// execFile Error), plus an Error's message and stack. Used on run_log.log_events right
// before the shared logger (utils/logger/log.js, a separate repo used by every app)
// serializes them, so its output is valid JSON with the values masked.
// Cycle-safe; read-only / frozen properties are skipped.
const redactInPlace = (value, seen = new WeakSet()) => {
  if (needles.length === 0 || value === null || typeof value !== "object") return value;
  if (seen.has(value)) return value;
  seen.add(value);
  const keys = Object.keys(value);
  if (value instanceof Error) keys.push("message", "stack");
  for (const k of keys) {
    const v = value[k];
    if (typeof v === "string") {
      const r = redactString(v);
      if (r !== v) {
        try {
          value[k] = r;
        } catch (e) {
          // non-writable: leave it
        }
      }
    } else if (v !== null && typeof v === "object") {
      redactInPlace(v, seen);
    }
  }
  return value;
};

// JSON.stringify OF A REDACTED COPY OF value (DOES NOT MUTATE value)
const safeStringify = (value) =>
  JSON.stringify(value, (key, v) => (typeof v === "string" ? redactString(v) : v));

// ANY VALUE -> REDACTED STRING, FORMATTED THE WAY console.log WOULD FORMAT IT
const redactFormat = (...args) => redactString(util.format(...args));

// WRAP console.* SO EVERY CALLER IS COVERED (INCLUDING console.log(error) IN CATCH
// BLOCKS). IDEMPOTENT.
const CONSOLE_GUARD = Symbol.for("hhm.redact.consoleGuard");
// trace is wrapped explicitly: Node's trace happens to print via this.error, but that is an
// implementation detail, not a contract
const CONSOLE_METHODS = ["log", "info", "warn", "error", "debug", "trace"];
const installConsoleRedaction = (con = console) => {
  if (con[CONSOLE_GUARD]) return con;
  for (const method of CONSOLE_METHODS) {
    const original = con[method];
    if (typeof original !== "function") continue;
    con[method] = function (...args) {
      if (needles.length === 0) return original.apply(this, args);
      return original.call(this, redactFormat(...args));
    };
  }
  con[CONSOLE_GUARD] = true;
  return con;
};

// TEST HOOK ONLY
const _resetSecretsForTests = () => {
  secrets.clear();
  needles = [];
};

module.exports = {
  MASK,
  registerSecret,
  redactString,
  redactInPlace,
  safeStringify,
  redactFormat,
  installConsoleRedaction,
  _resetSecretsForTests,
};
