const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const {
  add_to_redis_queue,
  add_to_online_queue,
  update_last_dir_date
} = require("../redis");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

const exec_phil_cv_unzip = async (
  job_id,
  run_log,
  sme,
  execPath,
  system,
  daily_dir
) => {
  let note = {
    job_id,
    system_id: system.id,
    execute_path: execPath,
    daily_dir
  };
  await addLogEvent(I, run_log, "exec_phil_cv_unzip", cal, note, null);

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
  let args = [(`${data_store_path}/${sme}/${daily_dir}`)];

  console.log("\nargs");
  console.log(args);

  try {
    const { stdout, stderr } = await execFile(execPath, args);

    let note = {
      job_id,
      system_id: system.id,
      stdout,
      stderr
    };

    await addLogEvent(I, run_log, "exec_phil_cv_unzip", det, note, null);

    return stdout;
  } catch (error) {
    console.log("\n*********** Catch Error *****************");
    console.log(error);

    await addLogEvent(E, run_log, "exec_phil_cv_unzip", cat, note, error);
    return null;
  }
};

module.exports = exec_phil_cv_unzip;

// Example of ssh tunnel reset example
// ssh: connect to host 167.171.115.90 port 22: Connection timed out
