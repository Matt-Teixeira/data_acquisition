// FLUSH A RUN LOG (util.app_run_logs + local run-log file) WITH DEVICE CREDENTIALS MASKED.
//
// utils/logger/log.js belongs to the shared AvanteHS-RTT/utils repo (used by every app), so
// the redaction is applied here, in this app, to the events themselves right before the
// shared logger serializes them. See util/redact.js.
const { redactInPlace } = require("./redact");
const [, writeLogEvents, dbInsertLogEvents] = require("../utils/logger/log");

const flushRunLog = async (pgp, run_log) => {
  redactInPlace(run_log.log_events);
  await dbInsertLogEvents(pgp, run_log);
  // dbInsertLogEvents appends its own success/error event: scrub again before the file write
  redactInPlace(run_log.log_events);
  await writeLogEvents(run_log);
};

module.exports = flushRunLog;
