const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const {
  add_to_redis_queue,
  add_to_online_queue,
  add_system_reset_totalizer,
} = require("../redis");
const { extractConnectionError, connection_regexes } = require("../util");
const [
  addLogEvent,
  ,
  ,
  ,
  ,
  startTimer,
  endTimer,
] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../utils/logger/enums");
const path = require("path");
const { redactArgsForLog } = require("../util/log_shapes");

const PHASE = "grab";
// Shell-level timeout fires first (coreutils `timeout`, clean exit 124, preserves
// stdout/stderr); the Node backstop fires for scripts that trap TERM. Callers
// can override the shell timeout per-call via the last argument; the Node
// backstop auto-scales to stay >= shellTimeoutS*1000 + 30s.
const SHELL_TIMEOUT_S = Number(process.env.SHELL_TIMEOUT_S) || 840;
const EXEC_TIMEOUT_MS = Number(process.env.EXEC_TIMEOUT_MS) || 120_000;
const EXEC_MAX_BUFFER = 10 * 1024 * 1024;
const MAX_STREAM_CHARS = 4096;

// Preserve the tail of a long stream (errors usually live at the end) and
// prepend a marker indicating how many chars were dropped.
const truncateStream = (s) => {
  if (typeof s !== "string" || s.length <= MAX_STREAM_CHARS) return s;
  return `...[truncated ${s.length - MAX_STREAM_CHARS} chars]\n${s.slice(-MAX_STREAM_CHARS)}`;
};

const exec_hhm_data_grab = async (
  job_id,
  run_log,
  sme,
  execPath,
  system,
  args,
  capture_datetime,
  ip_reset = false,
  shellTimeoutS
) => {
  const resolvedShellS = shellTimeoutS ?? SHELL_TIMEOUT_S;
  const resolvedExecMs = Math.max(
    EXEC_TIMEOUT_MS,
    resolvedShellS * 1000 + 30_000
  );
  system.data_source = "hhm";

  // RESOLVES TO WITHIN CONTAINER: /workspace/files
  const inner_container_path = path.join(process.cwd(), "files");

  let data_store_path = `${inner_container_path}/${sme}`;

  let note = {
    job_id: job_id,
    system_id: system.id,
    execute_path: execPath,
    file_path: data_store_path,
    args: redactArgsForLog(args),
  };

  await addLogEvent(I, run_log, "exec_hhm_data_grab", cal, note, null);

  args.push(data_store_path);

  const timer_label = `exec.${system.id}`;
  startTimer(run_log, timer_label);
  try {
  try {
    const { stdout, stderr } = await execFile(
      "timeout",
      [`${resolvedShellS}s`, execPath, ...args],
      {
        timeout: resolvedExecMs,
        killSignal: "SIGKILL",
        maxBuffer: EXEC_MAX_BUFFER,
      }
    );

    console.log("\n*********** stdout *****************");
    console.log(system.id);
    console.log(stdout);
    console.log("\n*********** stderr *****************");
    console.log(system.id);
    console.log(stderr);

    let note = {
      job_id: job_id,
      system_id: system.id,
      stdout: truncateStream(stdout),
      stderr: truncateStream(stderr),
    };

    await addLogEvent(I, run_log, "exec_hhm_data_grab", det, note, null);

    const extracted_stderr = extractConnectionError(stderr, connection_regexes);
    const extracted_stdout = extractConnectionError(stdout, connection_regexes);

    if (extracted_stdout?.extraction_error) {
      if (ip_reset || !extracted_stdout.connection_error) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: extracted_stdout.successful_acquisition,
          data_source: system.data_source,
          host_intervention: extracted_stdout.manual_intervention,
          connection_error: extracted_stdout.message,
          conn_err: extracted_stdout.connection_error,
          error_category: extracted_stdout.error_category,
          phase: PHASE,
        });

        return false;
      }

      // await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source,
      });
      // ADD HERE: Place system daily_total and lifetime_total redis:queue

      return false;
    }

    // TEST stderr FOR CONNECTIVITY
    if (extracted_stderr?.connection_error) {
      let note = {
        job_id: job_id,
        system_id: system.id,
        stdout: truncateStream(stdout),
        stderr: truncateStream(stderr),
      };

      await addLogEvent(W, run_log, "exec_hhm_data_grab", det, note, null);

      // Only runs for ip reset instance
      // Reason: In initial data pull, if connection issue occurs, just send to ip:queue and make second attempt.
      // If connection issue occurs on second attempt (ip reset job), place in online:queue to then place in connection status table
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: extracted_stderr.successful_acquisition,
          data_source: system.data_source,
          host_intervention: extracted_stderr.manual_intervention,
          connection_error: extracted_stderr.message,
          conn_err: extracted_stderr.connection_error,
          error_category: extracted_stderr.error_category,
          phase: PHASE,
        });

        return false;
      }

      // await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source,
      });
      // ADD HERE: Place system daily_total and lifetime_total redis:queue

      return false;
    }

    await add_to_online_queue(job_id, run_log, {
      id: system.id,
      capture_datetime,
      successful_acquisition: true,
      data_source: system.data_source,
      host_intervention: false,
      connection_error: null,
      conn_err: false,
      error_category: null,
      phase: PHASE,
    });

    return stdout;
  } catch (error) {
    console.log("\n*********** Catch Error *****************");
    console.log(error);

    // Classify against everything we have: node's error wrapper (error.message),
    // plus the child's captured stdout/stderr at the moment of failure.
    // Critical for lftp-style partial-pull failures where mget errors live
    // in stderr and are missing from the short error.message snippet.
    const error_text = [error.message, error.stderr, error.stdout]
      .filter(Boolean)
      .join("\n");
    const extracted_err_message = extractConnectionError(
      error_text,
      connection_regexes
    );

    if (
      extracted_err_message?.connection_error ||
      extracted_err_message?.extraction_error
    ) {
      let note = {
        job_id,
        system_id: system.id,
      };

      await addLogEvent(E, run_log, "exec_hhm_data_grab", cat, note, error);

      // IF IP RESET, JUST SEND TO QUEUE TO NOT RUN RESET AGAIN
      // TEST FOR THE PRESENCE OF extracted_err_message (present means connectivity, but file pull issue. Not connectivity)
      if (ip_reset || extracted_err_message?.extraction_error) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: extracted_err_message.successful_acquisition,
          data_source: system.data_source,
          host_intervention: extracted_err_message.manual_intervention,
          connection_error: extracted_err_message.message,
          conn_err: extracted_err_message.connection_error,
          error_category: extracted_err_message.error_category,
          phase: PHASE,
        });

        return false;
      }

      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source,
      });

      return false;
    }

    // CHECK ERROR CODE - execFile timeout
    // error.code === 124: coreutils `timeout` wrapper killed the child.
    // error.killed === true: Node's execFile { timeout } option fired SIGKILL.
    if (error.code === 124 || error.killed === true) {
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: false,
          data_source: system.data_source,
          host_intervention: false,
          connection_error: "execFile timed out",
          conn_err: true,
          error_category: "hanging_exec",
          phase: PHASE,
        });
        return false;
      }

      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source,
      });

      return false;
    }

    // UNKNOWN EXCEPTION - surface it to the DB as error_category="unknown"
    // so it is visible for manual review rather than silently returning null.
    await addLogEvent(E, run_log, "exec_hhm_data_grab", cat, note, error);
    await add_to_online_queue(job_id, run_log, {
      id: system.id,
      capture_datetime,
      successful_acquisition: false,
      data_source: system.data_source,
      host_intervention: false,
      connection_error: (error?.message || "unknown error").slice(0, 500),
      conn_err: true,
      error_category: "unknown",
      phase: PHASE,
    });
    return null;
  }
  } finally {
    await endTimer(run_log, timer_label, {
      sme: system.id,
      host_ip: system.host_ip,
    });
  }
};

module.exports = exec_hhm_data_grab;
