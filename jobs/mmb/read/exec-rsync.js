const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const {
  add_to_redis_queue,
  add_to_online_queue,
  add_system_reset_totalizer
} = require("../../../redis");
const {
  extractConnectionError,
  connection_regexes
} = require("../../../util/tools/connection_regex");

const [addLogEvent] = require("../../../utils/logger/log");
const { redactArgsForLog } = require("../../../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../../utils/logger/enums");

const PHASE = "remote_rsync";

/*
run_log,
job_id,
system.id,
`./jobs/mmb/read/sh/rsync_mmb.sh`,
system.rsyncShArgs,
capture_datetime,
true
*/

const execRsync = async (
  run_log,
  job_id,
  sme,
  rsyncShPath,
  rsyncShArgs,
  capture_datetime,
  vpn,
  ip_reset = false
) => {
  // THIS FUNCTION SYNCS A REMOTE FILE TO A LOCAL MIRROR AND RETURNS THE NEWLY SYNCED FILE SIZE
  let note = {
    job_id,
    sme: sme,
    rsyncShPath: rsyncShPath,
    // rsyncShArgs = [sme, remote_path, local_path, ip_address, user_id]; redact user_id at index 4.
    rsyncShArgs: redactArgsForLog(rsyncShArgs, [4])
  };
  await addLogEvent(I, run_log, "execRsync", cal, note, null);

  try {
    const { stdout, stderr } = await execFile(rsyncShPath, rsyncShArgs);

    const fileSizeAfterRsync = parseInt(stdout);

    await addLogEvent(I, run_log, "execRsync", det, {
      job_id,
      sme,
      fileSizeAfterRsync
    }, null);

    // Check stdout/stderr for classifiable partial-transfer / file-missing
    // signals even on a "success" exit - rsync can exit 0 while logging
    // skipped files. Rare, but keeps the signal path consistent.
    const extracted = extractConnectionError(
      [stdout, stderr].filter(Boolean).join("\n"),
      connection_regexes
    );

    if (capture_datetime !== "ip_reset") {
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

    return fileSizeAfterRsync;
  } catch (error) {
    await addLogEvent(E, run_log, "execRsync", cat, { job_id, sme }, error);

    // Classify against everything we have: error.message + stderr + stdout.
    const error_text = [error.message, error.stderr, error.stdout]
      .filter(Boolean)
      .join("\n");
    const extracted = extractConnectionError(error_text, connection_regexes);

    // system object used for ip:queue retry (matches tunnel_reset expectations)
    const system = {
      id: rsyncShArgs[0],
      vpn: vpn,
      mmb_ip: rsyncShArgs[3],
      data_source: "mmb",
      rsyncShArgs,
      rsyncShPath,
      capture_datetime
    };

    // Connection-layer error: first attempt goes to ip:queue for tunnel-reset
    // retry; second attempt (ip_reset=true) lands on online:queue as failed.
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

    // Extraction-layer error (file missing, partial, etc.): land on
    // online:queue with the classification - not a connectivity issue.
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

    // execFile timeout (GNU timeout wrapper) - ambiguous outcome.
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

    // UNKNOWN EXCEPTION - surface to DB rather than silently returning null.
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

module.exports = execRsync;
