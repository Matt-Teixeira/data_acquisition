const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const { add_to_redis_queue, add_to_online_queue } = require("../redis");
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
  let note = {
    job_id,
    system_id: sme,
    args
  };
  await addLogEvent(I, run_log, "exec_list_dirs", cal, note, null);

  const connection_test_1 = /Connection timed out/;
  const connection_test_2 = /error: max-retries exceeded/;
  const fingerprint_test =
    /Warning:\sPermanently\sadded\s'\d+\.\d+\.\d+.\d+'.+to\sthe\slist\sof\sknown\shosts|Error:\sCommand\sfailed/g;

  try {
    const { stdout, stderr } = await execFile(path, args);

    console.log("\n*********** stdout *****************");
    console.log(stdout);
    console.log("\n*********** stderr *****************");
    console.log(stderr);

    // If connection is closed, return false
    if (connection_test_1.test(stderr) || connection_test_2.test(stderr)) {
      let note = {
        job_id,
        system_id: sme,
        stdout,
        stderr
      };
      await addLogEvent(W, run_log, "exec_list_dirs", det, note, null);
      system.data_source = "hhm";

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

      await add_to_redis_queue(job_id, run_log, system);
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
        system_id: sme
      };
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
      await addLogEvent(E, run_log, "exec_list_dirs", cat, note, error);
      system.data_source = "hhm";
      await add_to_redis_queue(job_id, run_log, system);
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
    return null;
  }
};

module.exports = exec_list_dirs;
