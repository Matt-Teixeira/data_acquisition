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
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

const exec_list_dirs = async (
  job_id,
  run_log,
  sme,
  path,
  system,
  args,
  capture_datetime,
  ip_reset = false
) => {
  system.data_source = "hhm";
  let note = {
    job_id,
    system_id: sme,
    args
  };
  await addLogEvent(I, run_log, "exec_list_dirs", cal, note, null);

  try {
    const { stdout, stderr } = await execFile(path, args);

/*     console.log("\n*********** stdout *****************");
    console.log(system.id);
    console.log(stdout);
    console.log("\n*********** stderr *****************");
    console.log(system.id);
    console.log(stderr); */

    const extracted_stderr = extractConnectionError(stderr, connection_regexes);
    const extracted_stdout = extractConnectionError(stdout, connection_regexes);

    // TEST stdout FOR CONNECTIVITY
    if (extracted_stdout?.extraction_error) {
      if (ip_reset || !extracted_stdout.connection_error) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: extracted_stdout.successful_acquisition,
          data_source: system.data_source,
          host_intervention: extracted_stdout.manual_intervention,
          connection_error: extracted_stdout.message,
          conn_err: extracted_stdout.connection_error
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

      await addLogEvent(W, run_log, "exec_list_dirs", det, note, null);

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
          conn_err: extracted_stderr.connection_error
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

    // ON HOLD: DO NOT NEED TO ASSERT ONLINE BECAUSE NEXT EXEC-CHILD-PROCESS WILL RUN AND DO SO
    /*
    await add_to_online_queue(job_id, run_log, {
      id: system.id,
      capture_datetime,
      successful_acquisition: true,
      data_source: system.data_source,
      host_intervention: false
    });
    */

    return stdout;
  } catch (error) {
    console.log("\n*********** Catch Error *****************");
    console.log(error);

    if (
      extracted_err_message?.connection_error ||
      extracted_err_message?.extraction_error
    ) {
      let note = {
        job_id,
        system_id: system.id
      };

      await addLogEvent(E, run_log, "exec_list_dirs", cat, note, error);

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
          conn_err: extracted_err_message.connection_error
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

    // CHECK ERROR CODE
    if (error.code === 124) {
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: false,
          data_source: system.data_source,
          host_intervention: false,
          connection_error: "hanging connection",
          conn_err: true
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
    return null;
  }
};

module.exports = exec_list_dirs;
