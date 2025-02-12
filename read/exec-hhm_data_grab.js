const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const { add_to_redis_queue, add_to_online_queue, add_system_reset_totalizer } = require("../redis");
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
  let note = {
    job_id: job_id,
    system_id: system.id,
    execute_path: execPath,
    args
  };

  console.log(note);
  await addLogEvent(I, run_log, "exec_hhm_data_grab", cal, note, null);

  const connection_test_1 = /Connection timed out/;
  const connection_test_2 = /error: max-retries exceeded/;
  const no_file_test = /No such file or directory/;
  const fingerprint_test =
    /Warning:\sPermanently\sadded\s'\d+\.\d+\.\d+.\d+'.+to\sthe\slist\sof\sknown\shosts|Error:\sCommand\sfailed/g;

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
    console.log(stdout);
    console.log("\n*********** stderr *****************");
    console.log(stderr);

    let note = {
      job_id: job_id,
      system_id: system.id,
      stdout,
      stderr
    };

    await addLogEvent(I, run_log, "exec_hhm_data_grab", det, note, null);

    // TEST stderr FOR CONNECTIVITY: If connection is closed, return false. Any other error, return null.
    if (connection_test_1.test(stderr) || connection_test_2.test(stderr)) {
      let note = {
        job_id: job_id,
        system_id: system.id,
        stdout,
        stderr
      };

      await addLogEvent(W, run_log, "exec_hhm_data_grab", det, note, null);

      // Only runs for ip reset instance
      // Reason: In initial data pull, if connection issue occurs, just send to ip:queue and make second attempt.
      // If connection issue occurs on second attempt (ip reset job), place in online:queue to then place in heartbeat table as offline
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: false,
          data_source: "hhm",
          host_intervention: false
        });

        return false;
      }

      system.data_source = "hhm";
      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {id: system.id, data_source: "HHM"});
      // ADD HERE: Place system daily_total and lifetime_total redis:queue

      return false;
    }

    await add_to_online_queue(job_id, run_log, {
      id: system.id,
      capture_datetime,
      successful_acquisition: true,
      data_source: "hhm",
      host_intervention: false
    });

    return stdout;
  } catch (error) {
    console.log("\n*********** Catch Error *****************");
    console.log(error);

    if (
      connection_test_1.test(error.message) ||
      connection_test_2.test(error.message)
    ) {
      let note = {
        job_id,
        system_id: system.id
      };

      await addLogEvent(E, run_log, "exec_hhm_data_grab", cat, note, error);

      if (ip_reset) {
        console.log("In ip_reset");
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: false,
          data_source: "hhm",
          host_intervention: false
        });

        return false;
      }

      system.data_source = "hhm";
      await add_to_redis_queue(job_id, run_log, system);
      await add_system_reset_totalizer(job_id, run_log, {id: system.id, data_source: "HHM"});

      return false;
    }

    // data_acqu was able to reach out and connect, but no file found. Sent to online queue
    if(no_file_test.test(error)) {
      await add_to_online_queue(job_id, run_log, {
        id: system.id,
        capture_datetime,
        successful_acquisition: true,
        data_source: "hhm",
        host_intervention: false
      });
      return false;
    }

    // Second condition mostly as a catch all for now due to "Error: Command failed:" pattern match
    if (fingerprint_test.test(error)) {
      console.log("Reestablish keys/fingerprint/password");
      await add_to_online_queue(job_id, run_log, {
        id: system.id,
        capture_datetime,
        successful_acquisition: false,
        data_source: "hhm",
        host_intervention: true
      });
      return false;
    }
    await addLogEvent(E, run_log, "exec_hhm_data_grab", cat, note, error);
    return null;
  }
};

module.exports = exec_hhm_data_grab;
