const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const { getHhmFilesPath } = require("../config");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, E },
  tag: { cal, det, cat }
} = require("../utils/logger/enums");

const exec_phil_cv_unzip = async (
  job_id,
  run_log,
  sme,
  execPath,
  system,
  daily_dir
) => {
  const note = {
    job_id,
    system_id: system.id,
    execute_path: execPath,
    daily_dir
  };
  await addLogEvent(I, run_log, "exec_phil_cv_unzip", cal, note, null);

  const data_store_path = getHhmFilesPath();
  const args = [`${data_store_path}/${sme}/${daily_dir}`];

  try {
    const { stdout, stderr } = await execFile(execPath, args);

    const resultNote = {
      job_id,
      system_id: system.id,
      stdout,
      stderr
    };

    await addLogEvent(I, run_log, "exec_phil_cv_unzip", det, resultNote, null);

    return stdout;
  } catch (error) {
    await addLogEvent(E, run_log, "exec_phil_cv_unzip", cat, note, error);
    return null;
  }
};

module.exports = exec_phil_cv_unzip;
