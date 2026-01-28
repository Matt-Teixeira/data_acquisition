const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const { getHhmFilesPath } = require("../../config");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, E },
  tag: { cal, det, cat }
} = require("../../utils/logger/enums");

const exec_hhm_data_grab = async (run_log, sme, execPath, system, args) => {
  const note = {
    system_id: system.id,
    execute_path: execPath,
    args
  };
  await addLogEvent(I, run_log, "exec_hhm_data_grab", cal, note, null);

  const data_store_path = getHhmFilesPath();
  args.push(`${data_store_path}/${sme}`);

  try {
    const { stdout, stderr } = await execFile(execPath, args);

    const resultNote = {
      system_id: system.id,
      stdout,
      stderr
    };

    await addLogEvent(I, run_log, "exec_hhm_data_grab", det, resultNote, null);

    return stdout;
  } catch (error) {
    await addLogEvent(E, run_log, "exec_hhm_data_grab", cat, note, error);
    return null;
  }
};

module.exports = exec_hhm_data_grab;
