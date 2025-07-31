const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const {
  add_to_redis_queue,
  add_to_online_queue,
  add_system_reset_totalizer
} = require("../redis");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

const exec_hhm_data_grab = async (
  job_id,
  run_log,
  sme,
  execPath,
  system,
  args,
  capture_datetime,
  ip_reset = false
) => {
  system.data_source = "hhm"; 

  let note = {
    job_id: job_id,
    system_id: system.id,
    execute_path: execPath,
    args
  };

  console.log("\nExec Note");
  console.log(note);
  await addLogEvent(I, run_log, "exec_hhm_data_grab", cal, note, null);

  const regexes = [
    {
      connection_error: true,
      error_type: "connection",
      message: "Connection timed out",
      manual_intervention: false,
      successful_acquisition: false,
      re: /Connection timed out/
    },
    {
      connection_error: true,
      error_type: "connection",
      message: "max-retries exceeded",
      manual_intervention: false,
      successful_acquisition: false,
      re: /error: max-retries exceeded/
    },
    {
      connection_error: true,
      error_type: "connection",
      message: "confirm the new fingerprint and update known hosts",
      manual_intervention: true,
      successful_acquisition: false,
      re: /Warning:\sPermanently\sadded\s'\d+\.\d+\.\d+\.\d+'.+to\sthe\slist\sof\sknown\shosts|Error:\sCommand\sfailed/g
    }
  ];

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

  // EXAMPLE: /home/prod/hhm_data_acquisition/files/prod_hhm/GE/CT/SME00001
  // DEV: args.push(`${data_store_path}/${manufacturer}/${modality}/${sme}`);
  args.push(`${data_store_path}/${sme}`);

  try {
    const { stdout, stderr } = await execFile(execPath, args);

    console.log("\n*********** stdout *****************");
    console.log(system.id);
    console.log(stdout);
    console.log("\n*********** stderr *****************");
    console.log(system.id);
    console.log(stderr);

    let note = {
      job_id: job_id,
      system_id: system.id,
      stdout,
      stderr
    };

    await addLogEvent(I, run_log, "exec_hhm_data_grab", det, note, null);

    const extracted_error = extractConnectionError(stderr, regexes);

    // TEST stderr FOR CONNECTIVITY
    if (extracted_error?.connection_error) {
      let note = {
        job_id: job_id,
        system_id: system.id,
        stdout,
        stderr
      };

      await addLogEvent(W, run_log, "exec_hhm_data_grab", det, note, null);

      // Only runs for ip reset instance
      // Reason: In initial data pull, if connection issue occurs, just send to ip:queue and make second attempt.
      // If connection issue occurs on second attempt (ip reset job), place in online:queue to then place in connection status table
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: extracted_error.successful_acquisition,
          data_source: system.data_source,
          host_intervention: extracted_error.manual_intervention,
          connection_error: extracted_error.message
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

    await add_to_online_queue(job_id, run_log, {
      id: system.id,
      capture_datetime,
      successful_acquisition: true,
      data_source: system.data_source,
      host_intervention: false,
      connection_error: null
    });

    return stdout;
  } catch (error) {
    console.log("\n*********** Catch Error *****************");
    console.log(error);

    // TEST stderr FOR CONNECTION ERROR
    const extracted_error = extractConnectionError(error.message, regexes);

    if (extracted_error?.connection_error) {
      let note = {
        job_id,
        system_id: system.id
      };

      await addLogEvent(E, run_log, "exec_hhm_data_grab", cat, note, error);

      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: extracted_error.successful_acquisition,
          data_source: system.data_source,
          host_intervention: extracted_error.host_intervention,
          connection_error: extracted_error.message
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
          connection_error: "hanging connection"
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
    await addLogEvent(E, run_log, "exec_hhm_data_grab", cat, note, error);
    return null;
  }
};

// TEST stderr FOR CONNECTION ERROR
function extractConnectionError(text, regexes) {
  for (let regex of regexes) {
    const is_match = regex.re.test(text);

    if (is_match) return regex;
  }
  return null;
}

module.exports = exec_hhm_data_grab;
