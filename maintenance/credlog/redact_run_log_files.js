#!/usr/bin/env node
// ONE-OFF CLEAN-UP: mask device credentials in existing run-log files
// (utils/logger/*-log.*.js and the gzipped daily dirs), written before util/redact.js.
//
// The values themselves are unknown here (they are only ever decrypted by the collector),
// so this uses the STRUCTURE the old code wrote them in, same rules as
// redact_app_run_logs.sql. <cred script> = ./read/sh/GE/*, ./read/sh/Philips/*,
// ./read/sh/Siemens/siemens_c* (called with [ip, user, pass, ...]):
//   R1  "execute_path":"<cred script>","args":["<ip>","<user>","<pass>",... -> user, pass = "***"
//   R2  exec_list_dirs note {job_id, system_id, args:[ip,user,pass,...]}     -> user, pass = "***"
//   R3  Command failed: <cred script> <args...>                              -> <script> ***
//   R4  "cmd":"<cred script> <args...>"                                     -> "<script> ***"
//
// Usage (as the owner of the files):
//   node redact_run_log_files.js <dir> [<dir> ...]            dry run: counts only
//   node redact_run_log_files.js --apply <dir> [<dir> ...]    rewrite affected files
// Prints counts only; never prints file content. Files are rewritten atomically
// (temp file + rename in the same dir), keeping mode and mtime. *.gz is handled.
// Exit code 2 if any file still matches a residual pattern after --apply.

const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const S = '(?:[^"\\\\]|\\\\.)*'; // body of a JSON string
// credential-bearing collector scripts: called with [ip, user, pass, ...]
const CRED = "(?:GE|Philips|Siemens/siemens_c)";
const RULES = [
  [new RegExp(`("execute_path":"\\./read/sh/${CRED}[^"]*","args":\\["${S}",)"${S}","${S}"`, "g"), '$1"***","***"'],
  [new RegExp(`("func":"exec_list_dirs","tag":"${S}","note":\\{"job_id":"${S}","system_id":"${S}","args":\\["${S}",)"${S}","${S}"`, "g"), '$1"***","***"'],
  [new RegExp(`(Command failed: \\./read/sh/${CRED}[^ "\\\\]*) (?:[^"\\\\]|\\\\[^n])+`, "g"), "$1 ***"],
  [new RegExp(`("cmd":"\\./read/sh/${CRED}[^ "\\\\]*) (?:[^"\\\\]|\\\\.)+"`, "g"), '$1 ***"'],
];
// what must not remain afterwards: an args array of >= 3 strings whose [1],[2] are not both
// "***", or a Command failed line with unmasked arguments ([ip, data_path] is not flagged)
const RESIDUAL = [
  new RegExp(`"execute_path":"\\./read/sh/${CRED}[^"]*","args":\\["${S}",(?!"\\*\\*\\*","\\*\\*\\*")"${S}","${S}"`),
  new RegExp(`"func":"exec_list_dirs","tag":"${S}","note":\\{"job_id":"${S}","system_id":"${S}","args":\\["${S}",(?!"\\*\\*\\*","\\*\\*\\*")"${S}","${S}"`),
  new RegExp(`Command failed: \\./read/sh/${CRED}[^ "\\\\]* (?!\\*\\*\\*)`),
];

const redact = (text) => RULES.reduce((t, [re, rep]) => t.replace(re, rep), text);
const isLog = (name) => /-log\..+\.js(\.gz)?$/.test(name);

const apply = process.argv.includes("--apply");
const dirs = process.argv.slice(2).filter((a) => a !== "--apply");
if (!dirs.length) {
  console.error("usage: redact_run_log_files.js [--apply] <dir> [<dir> ...]");
  process.exit(1);
}

const stats = { scanned: 0, affected: 0, rewritten: 0, residual: 0, invalid_json_after: 0, errors: 0 };

const walk = (dir) => {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p);
    else if (ent.isFile() && isLog(ent.name)) handle(p);
  }
};

const handle = (p) => {
  stats.scanned++;
  try {
    const gz = p.endsWith(".gz");
    const raw = fs.readFileSync(p);
    const text = (gz ? zlib.gunzipSync(raw) : raw).toString("utf8");
    const out = redact(text);
    // checked on every file, also unchanged ones: catches shapes the rules do not cover
    if (RESIDUAL.some((re) => re.test(out))) stats.residual++;
    if (out === text) return;
    stats.affected++;
    let wasJson = true;
    try { JSON.parse(text); } catch (e) { wasJson = false; }
    if (wasJson) {
      try { JSON.parse(out); } catch (e) { stats.invalid_json_after++; return; } // never write a broken file
    }
    if (!apply) return;
    const st = fs.statSync(p);
    const tmp = path.join(path.dirname(p), `.${path.basename(p)}.redact-tmp`);
    const fd = fs.openSync(tmp, "wx", st.mode & 0o7777);
    try {
      fs.writeSync(fd, gz ? zlib.gzipSync(Buffer.from(out, "utf8")) : out);
      fs.fsyncSync(fd);
    } finally {
      fs.closeSync(fd);
    }
    fs.utimesSync(tmp, st.atime, st.mtime);
    fs.renameSync(tmp, p);
    stats.rewritten++;
  } catch (e) {
    stats.errors++;
  }
  if (stats.scanned % 20000 === 0) process.stderr.write(`${stats.scanned} scanned\n`);
};

for (const d of dirs) walk(d);
console.log(JSON.stringify({ mode: apply ? "apply" : "dry-run", ...stats }));
process.exit(stats.residual || stats.invalid_json_after || stats.errors ? 2 : 0);
