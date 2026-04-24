const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const {
  add_to_redis_queue,
  add_to_online_queue,
  add_system_reset_totalizer
} = require("../redis");
const {
  extractConnectionError,
  connection_regexes
} = require("../util/tools/connection_regex");
const [addLogEvent] = require("../utils/logger/log");
const { redactArgsForLog } = require("../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

const PHASE = "remote_rsync";

const exec_remote_rsync = async (
  job_id,
  run_log,
  sme,
  rsyncShPath,
  rsyncShArgs,
  capture_datetime = null,
  ip_reset = false
) => {
  let note = {
    job_id,
    system_id: sme,
    rsync_path: rsyncShPath,
    // rsyncShArgs = [user_id, mmb_ip, dest_path]; redact user_id at index 0.
    args: redactArgsForLog(rsyncShArgs, [0])
  };

  try {
    await addLogEvent(I, run_log, "exec_remote_rsync", cal, note, null);
    const { stdout, stderr } = await execFile(rsyncShPath, rsyncShArgs);

    // Check for classifiable signals even on success (rsync can exit 0
    // while logging skipped files).
    const extracted = extractConnectionError(
      [stdout, stderr].filter(Boolean).join("\n"),
      connection_regexes
    );

    if (capture_datetime !== null && capture_datetime !== "ip_reset") {
      await add_to_online_queue(job_id, run_log, {
        id: sme,
        capture_datetime,
        successful_acquisition: extracted ? extracted.successful_acquisition : true,
        data_source: "mmb",
        host_intervention: extracted ? extracted.manual_intervention : false,
        connection_error: extracted ? extracted.message : null,
        conn_err: extracted ? extracted.connection_error : false,
        error_category: extracted ? extracted.error_category : null,
        phase: PHASE
      });
    }

    return;
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "exec_remote_rsync", cat, note, error);

    // Without capture_datetime the caller hasn't opted into queue writing
    // (preserves backwards compat for any non-MMB caller that used this
    // helper historically). Bail after logging.
    if (capture_datetime === null) {
      return null;
    }

    const error_text = [error.message, error.stderr, error.stdout]
      .filter(Boolean)
      .join("\n");
    const extracted = extractConnectionError(error_text, connection_regexes);

    const system = {
      id: sme,
      data_source: "mmb",
      rsyncShArgs,
      rsyncShPath,
      capture_datetime
    };

    if (extracted?.connection_error) {
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: sme,
          capture_datetime,
          successful_acquisition: extracted.successful_acquisition,
          data_source: "mmb",
          host_intervention: extracted.manual_intervention,
          connection_error: extracted.message,
          conn_err: extracted.connection_error,
          error_category: extracted.error_category,
          phase: PHASE
        });
        return null;
      }
      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: sme,
        data_source: "mmb"
      });
      return null;
    }

    if (extracted?.extraction_error) {
      await add_to_online_queue(job_id, run_log, {
        id: sme,
        capture_datetime,
        successful_acquisition: extracted.successful_acquisition,
        data_source: "mmb",
        host_intervention: extracted.manual_intervention,
        connection_error: extracted.message,
        conn_err: extracted.connection_error,
        error_category: extracted.error_category,
        phase: PHASE
      });
      return null;
    }

    if (error.code === 124) {
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: sme,
          capture_datetime,
          successful_acquisition: false,
          data_source: "mmb",
          host_intervention: false,
          connection_error: "execFile timed out",
          conn_err: true,
          error_category: "hanging_exec",
          phase: PHASE
        });
        return null;
      }
      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: sme,
        data_source: "mmb"
      });
      return null;
    }

    // UNKNOWN EXCEPTION - surface to DB rather than silently swallowing.
    await add_to_online_queue(job_id, run_log, {
      id: sme,
      capture_datetime,
      successful_acquisition: false,
      data_source: "mmb",
      host_intervention: false,
      connection_error: (error?.message || "unknown error").slice(0, 500),
      conn_err: true,
      error_category: "unknown",
      phase: PHASE
    });
    return null;
  }
};

module.exports = exec_remote_rsync;
