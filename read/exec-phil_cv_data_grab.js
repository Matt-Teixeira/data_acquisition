const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const {
  add_to_redis_queue,
  add_to_online_queue,
  add_system_reset_totalizer,
  update_last_dir_date
} = require("../redis");
const { extractConnectionError, connection_regexes } = require("../util");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");
const path = require("path");

const PHASE = "transfer";

const exec_phil_cv_data_grab = async (
  job_id,
  run_log,
  sme,
  execPath,
  system,
  args,
  type,
  capture_datetime,
  ip_reset = false
) => {
  system.data_source = "hhm";
  let note = {
    job_id,
    system_id: system.id,
    execute_path: execPath,
    args
  };
  await addLogEvent(I, run_log, "exec_phil_cv_data_grab", cal, note, null);

  const fallback = path.join(process.cwd(), "files");

  let data_store_path = "";
  switch (process.env.RUN_ENV) {
    case "dev":
      data_store_path = process.env.DEV_HHM_FILES;
      break;
    case "staging":
      data_store_path = process.env.STAGING_HHM_FILES;
      break;
    case "prod":
      data_store_path = process.env.PROD_HHM_FILES;
      break;
    default:
      break;
  }
  data_store_path = fallback;

  console.log("\ndata_store_path:");
  console.log(data_store_path);

  // EXAMPLE: /home/prod/hhm_data_acquisition/files/prod_hhm/GE/CT/SME00001
  // DEV: args.push(`${data_store_path}/${manufacturer}/${modality}/${sme}`);
  args.push(`${data_store_path}/${sme}`);

  try {
    const { stdout, stderr } = await execFile(execPath, args);

/*  console.log("\n*********** stdout *****************");
    console.log(system.id);
    console.log(stdout);
    console.log("\n*********** stderr *****************");
    console.log(system.id);
    console.log(stderr);
 */
    let note = {
      job_id,
      system_id: system.id,
      stdout,
      stderr
    };

    await addLogEvent(I, run_log, "exec_phil_cv_data_grab", det, note, null);

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
          phase: PHASE
        });

        return false;
      }

      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source
      });
      // ADD HERE: Place system daily_total and lifetime_total redis:queue

      return false;
    }

    // TEST stderr FOR CONNECTIVITY
    if (extracted_stderr?.connection_error) {
      let note = {
        job_id: job_id,
        system_id: system.id,
        stdout,
        stderr
      };

      await addLogEvent(W, run_log, "exec_phil_cv_data_grab", det, note, null);

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
          phase: PHASE
        });

        return false;
      }

      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source
      });
      // ADD HERE: Place system daily_total and lifetime_total redis:queue

      return false;
    }

    await update_last_dir_date(sme, args[3], type);

    // REDIS: PREVENT SECOND online:queue INSERTION
    if (type === "last_phil_cv_lod") return stdout;

    await add_to_online_queue(job_id, run_log, {
      id: system.id,
      capture_datetime,
      successful_acquisition: true,
      data_source: system.data_source,
      host_intervention: false,
      connection_error: null,
      conn_err: false,
      error_category: null,
      phase: PHASE
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
        system_id: system.id
      };

      await addLogEvent(E, run_log, "exec_phil_cv_data_grab", cat, note, error);

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
          phase: PHASE
        });

        return false;
      }

      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source
      });

      return false;
    }

    // CHECK ERROR CODE - execFile timeout
    if (error.code === 124) {
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
          phase: PHASE
        });
        return false;
      }

      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {
        id: system.id,
        data_source: system.data_source
      });

      return false;
    }

    // UNKNOWN EXCEPTION - surface it to the DB as error_category="unknown"
    // so it is visible for manual review rather than silently returning null.
    await addLogEvent(E, run_log, "exec_phil_cv_data_grab", cat, note, error);
    await add_to_online_queue(job_id, run_log, {
      id: system.id,
      capture_datetime,
      successful_acquisition: false,
      data_source: system.data_source,
      host_intervention: false,
      connection_error: (error?.message || "unknown error").slice(0, 500),
      conn_err: true,
      error_category: "unknown",
      phase: PHASE
    });
    return null;
  }
};

module.exports = exec_phil_cv_data_grab;

// Example of ssh tunnel reset example
// ssh: connect to host 167.171.115.90 port 22: Connection timed out
